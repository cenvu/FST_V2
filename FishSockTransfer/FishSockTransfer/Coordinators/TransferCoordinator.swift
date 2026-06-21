import Foundation

public actor TransferCoordinator {
    public private(set) var state: TransferState = .ready
    
    // Dependencies
    private let driveService: DriveService
    private let loggerService: LoggerService
    private let rsyncEngine: RsyncEngine
    private let verifyEngine: VerifyEngine
    
    // Callbacks for ViewModel
    private var onStateChanged: (@MainActor @Sendable (TransferState) -> Void)?
    private var onProgress: (@MainActor @Sendable (Double) -> Void)?
    private var onSpeed: (@MainActor @Sendable (Double) -> Void)?
    private var onETA: (@MainActor @Sendable (TimeInterval) -> Void)?
    private var onCurrentFile: (@MainActor @Sendable (String) -> Void)?
    private var onError: (@MainActor @Sendable (String) -> Void)?
    private var onLog: (@MainActor @Sendable (LogEntry) -> Void)?
    
    private var isCancelled = false
    private var workflowTask: Task<Void, Never>?
    
    public init(
        driveService: DriveService = DriveService(),
        loggerService: LoggerService = LoggerService(),
        rsyncEngine: RsyncEngine? = nil,
        verifyEngine: VerifyEngine = VerifyEngine(),
        bundledRsyncService: BundledRsyncService = BundledRsyncService()
    ) {
        self.driveService = driveService
        self.loggerService = loggerService
        self.rsyncEngine = rsyncEngine ?? RsyncEngine(bundledRsyncService: bundledRsyncService)
        self.verifyEngine = verifyEngine
    }

    public func configureCallbacks(
        onStateChanged: (@MainActor @Sendable @escaping (TransferState) -> Void),
        onProgress: (@MainActor @Sendable @escaping (Double) -> Void),
        onSpeed: (@MainActor @Sendable @escaping (Double) -> Void),
        onETA: (@MainActor @Sendable @escaping (TimeInterval) -> Void),
        onCurrentFile: (@MainActor @Sendable @escaping (String) -> Void),
        onError: (@MainActor @Sendable @escaping (String) -> Void),
        onLog: (@MainActor @Sendable @escaping (LogEntry) -> Void)
    ) {
        self.onStateChanged = onStateChanged
        self.onProgress = onProgress
        self.onSpeed = onSpeed
        self.onETA = onETA
        self.onCurrentFile = onCurrentFile
        self.onError = onError
        self.onLog = onLog
    }
    
    private func updateState(_ newState: TransferState) async {
        self.state = newState
        await onStateChanged?(newState)
    }

    private func log(category: LogCategory, message: String) async {
        await loggerService.log(category: category, message: message)
        await onLog?(LogEntry(category: category, message: message))
    }
    
    public func startTransfer(source: URL, destination: URL, bandwidthLimit: Int?, mode: VerificationMode) {
        // Enforce valid start states
        guard state == .ready || state == .copyComplete || state == .safeToFormat || state == .error || state == .cancelled else {
            return
        }
        
        isCancelled = false
        
        workflowTask = Task.detached(priority: .userInitiated) { [self] in
            await self.runWorkflow(source: source, destination: destination, bandwidthLimit: bandwidthLimit, mode: mode)
        }
    }
    
    public func cancelTransfer() {
        guard state == .copying || state == .verifying else { return }
        isCancelled = true
        let currentState = state
        let rsyncEngine = rsyncEngine
        let verifyEngine = verifyEngine
        
        Task.detached {
            if currentState == .copying {
                await rsyncEngine.cancel()
            } else if currentState == .verifying {
                await verifyEngine.cancel()
            }
        }
    }
    
    private func runWorkflow(source: URL, destination: URL, bandwidthLimit: Int?, mode: VerificationMode) async {
        // STATE: VALIDATING
        await updateState(.validating)
        await log(category: .info, message: "Validating transfer requirements...")
        
        do {
            try await driveService.validateSource(at: source)
            try await driveService.validateDestination(at: destination)
            let freeSpace = try await driveService.calculateFreeSpace(at: destination)
            if freeSpace <= 0 {
                throw NSError(domain: "TransferCoordinator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Insufficient free space on destination."])
            }
        } catch {
            await log(category: .error, message: "Validation failed: \(error.localizedDescription)")
            await onError?(error.localizedDescription)
            await updateState(.error)
            return
        }
        
        if isCancelled {
            await updateState(.cancelled)
            return
        }
        
        // STATE: COPYING
        await updateState(.copying)
        let request = TransferRequest(sourceURL: source, destinationURL: destination, bandwidthLimit: bandwidthLimit)
        let (rsyncSuccess, rsyncError) = await executeRsync(request: request)
        
        if isCancelled {
            await updateState(.cancelled)
            return
        }
        
        if !rsyncSuccess {
            if let err = rsyncError {
                await onError?(err.localizedDescription)
            }
            await updateState(.error)
            return
        }
        
        // Mode None -> Fast Exit
        if mode == .none {
            await updateState(.copyComplete)
            await log(category: .system, message: "Copy complete. Verification disabled.")
            return
        }
        
        // STATE: VERIFYING
        await updateState(.verifying)
        let verifiedDestination = destination.appendingPathComponent(source.lastPathComponent, isDirectory: true)
        let verifyRequest = VerificationRequest(sourceURL: source, destinationURL: verifiedDestination, mode: mode)
        let (verifySuccess, verifyError) = await executeVerify(request: verifyRequest)
        
        if isCancelled {
            await updateState(.cancelled)
            return
        }
        
        if !verifySuccess {
            if let err = verifyError {
                await onError?(err.localizedDescription)
            }
            await updateState(.error)
            return
        }
        
        // STATE: SAFE_TO_FORMAT (Only reachable if both Copy and Verify succeed)
        await updateState(.safeToFormat)
        await log(category: .system, message: "Verification Passed. SAFE TO FORMAT.")
    }
    
    private func executeRsync(request: TransferRequest) async -> (Bool, Error?) {
        return await withCheckedContinuation { continuation in
            Task {
                let eventStream = AsyncStream(TransferEvent.self) { eventContinuation in
                    Task {
                        await rsyncEngine.startTransfer(request: request) { event in
                            eventContinuation.yield(event)
                        }
                        eventContinuation.finish()
                    }
                }

                var didResume = false
                for await event in eventStream {
                    switch event {
                    case .progress(let p):
                        await self.onProgress?(p)
                        await self.log(category: .progress, message: "Progress \(Int(p.rounded()))%")
                    case .speed(let s):
                        await self.onSpeed?(s)
                        await self.log(category: .progress, message: String(format: "Speed %.2f MB/s", s))
                    case .eta(let e):
                        await self.onETA?(e)
                        await self.log(category: .progress, message: "ETA \(self.formatETA(e))")
                    case .currentFile(let f):
                        await self.onCurrentFile?(f)
                        await self.log(category: .file, message: f)
                    case .log(let logStr):
                        await self.logRsyncLine(logStr)
                    case .started:
                        await self.log(category: .info, message: "Transfer Started")
                    case .completed:
                        await self.log(category: .success, message: "Transfer Completed")
                        continuation.resume(returning: (true, nil))
                        didResume = true
                    case .cancelled:
                        await self.log(category: .warning, message: "Transfer Cancelled")
                        continuation.resume(returning: (false, nil))
                        didResume = true
                    case .failed(let err):
                        await self.log(category: .error, message: "Transfer Failed: \(err.localizedDescription)")
                        continuation.resume(returning: (false, err))
                        didResume = true
                    }

                    if didResume {
                        break
                    }
                }
            }
        }
    }
    
    private func executeVerify(request: VerificationRequest) async -> (Bool, Error?) {
        return await withCheckedContinuation { continuation in
            Task {
                let eventStream = AsyncStream(VerificationEvent.self) { eventContinuation in
                    Task {
                        await verifyEngine.startVerification(request: request) { event in
                            eventContinuation.yield(event)
                        }
                        eventContinuation.finish()
                    }
                }

                var didResume = false
                for await event in eventStream {
                    switch event {
                    case .progress(let p):
                        await self.onProgress?(p)
                        await self.log(category: .progress, message: "Verification \(Int((p * 100).rounded()))%")
                    case .currentFile(let f):
                        await self.onCurrentFile?(f)
                        await self.log(category: .file, message: f)
                    case .log(let message):
                        await self.log(category: .verify, message: message)
                    case .hashGenerated(let logMsg):
                        await self.log(category: .verify, message: logMsg)
                    case .started:
                        await self.log(category: .verify, message: "Verification Started")
                    case .completed(let result):
                        if result.status == .passed {
                            await self.log(category: .success, message: "Verification Completed")
                            continuation.resume(returning: (true, nil))
                        } else {
                            let err = NSError(domain: "VerifyEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Verification failed."])
                            await self.log(category: .error, message: err.localizedDescription)
                            continuation.resume(returning: (false, err))
                        }
                        didResume = true
                    case .cancelled:
                        await self.log(category: .warning, message: "Verification Cancelled")
                        continuation.resume(returning: (false, nil))
                        didResume = true
                    case .failed(let err):
                        await self.log(category: .error, message: "VerificationError reached TransferCoordinator: \(String(describing: err))")
                        await self.log(category: .error, message: err.localizedDescription)
                        continuation.resume(returning: (false, err))
                        didResume = true
                    }

                    if didResume {
                        break
                    }
                }
            }
        }
    }

    private func logRsyncLine(_ line: String) async {
        if line.hasPrefix("[STDOUT] ") {
            await log(category: .stdout, message: String(line.dropFirst(9)))
        } else if line.hasPrefix("[STDERR] ") {
            await log(category: .stderr, message: String(line.dropFirst(9)))
        } else {
            await log(category: .transfer, message: line)
        }
    }

    private func formatETA(_ eta: TimeInterval) -> String {
        guard eta > 0 else { return "--:--" }
        let totalSeconds = Int(eta.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
