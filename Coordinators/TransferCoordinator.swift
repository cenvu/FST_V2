import Foundation

@MainActor
public final class TransferCoordinator {
    public private(set) var state: TransferState = .ready
    
    // Dependencies
    private let driveService: DriveService
    private let loggerService: LoggerService
    private let rsyncEngine: RsyncEngine
    private let verifyEngine: VerifyEngine
    
    // Callbacks for ViewModel
    public var onStateChanged: ((TransferState) -> Void)?
    public var onProgress: ((Double) -> Void)?
    public var onSpeed: ((Double) -> Void)?
    public var onETA: ((TimeInterval) -> Void)?
    public var onCurrentFile: ((String) -> Void)?
    public var onError: ((Error) -> Void)?
    
    private var isCancelled = false
    
    public init(
        driveService: DriveService = DriveService(),
        loggerService: LoggerService = LoggerService(),
        rsyncEngine: RsyncEngine = RsyncEngine(),
        verifyEngine: VerifyEngine = VerifyEngine()
    ) {
        self.driveService = driveService
        self.loggerService = loggerService
        self.rsyncEngine = rsyncEngine
        self.verifyEngine = verifyEngine
    }
    
    private func updateState(_ newState: TransferState) {
        self.state = newState
        onStateChanged?(newState)
    }
    
    public func startTransfer(source: URL, destination: URL, bandwidthLimit: Int?, mode: VerificationMode) {
        // Enforce valid start states
        guard state == .ready || state == .copyComplete || state == .safeToFormat || state == .error || state == .cancelled else {
            return
        }
        
        isCancelled = false
        
        Task {
            await runWorkflow(source: source, destination: destination, bandwidthLimit: bandwidthLimit, mode: mode)
        }
    }
    
    public func cancelTransfer() {
        guard state == .copying || state == .verifying else { return }
        isCancelled = true
        
        Task {
            if state == .copying {
                await rsyncEngine.cancel()
            } else if state == .verifying {
                await verifyEngine.cancel()
            }
        }
    }
    
    private func runWorkflow(source: URL, destination: URL, bandwidthLimit: Int?, mode: VerificationMode) async {
        // STATE: VALIDATING
        updateState(.validating)
        await loggerService.log(category: .info, message: "Validating transfer requirements...")
        
        do {
            try await driveService.validateSource(at: source)
            try await driveService.validateDestination(at: destination)
            let freeSpace = try await driveService.calculateFreeSpace(at: destination)
            if freeSpace <= 0 {
                throw NSError(domain: "TransferCoordinator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Insufficient free space on destination."])
            }
        } catch {
            await loggerService.log(category: .error, message: "Validation failed: \(error.localizedDescription)")
            onError?(error)
            updateState(.error)
            return
        }
        
        if isCancelled {
            updateState(.cancelled)
            return
        }
        
        // STATE: COPYING
        updateState(.copying)
        let request = TransferRequest(sourceURL: source, destinationURL: destination, bandwidthLimit: bandwidthLimit)
        let (rsyncSuccess, rsyncError) = await executeRsync(request: request)
        
        if isCancelled {
            updateState(.cancelled)
            return
        }
        
        if !rsyncSuccess {
            if let err = rsyncError {
                onError?(err)
            }
            updateState(.error)
            return
        }
        
        // Mode None -> Fast Exit
        if mode == .none {
            updateState(.copyComplete)
            await loggerService.log(category: .system, message: "Copy complete. Verification disabled.")
            return
        }
        
        // STATE: VERIFYING
        updateState(.verifying)
        let verifyRequest = VerificationRequest(sourceURL: source, destinationURL: destination, mode: mode)
        let (verifySuccess, verifyError) = await executeVerify(request: verifyRequest)
        
        if isCancelled {
            updateState(.cancelled)
            return
        }
        
        if !verifySuccess {
            if let err = verifyError {
                onError?(err)
            }
            updateState(.error)
            return
        }
        
        // STATE: SAFE_TO_FORMAT (Only reachable if both Copy and Verify succeed)
        updateState(.safeToFormat)
        await loggerService.log(category: .system, message: "Verification Passed. SAFE TO FORMAT.")
    }
    
    private func executeRsync(request: TransferRequest) async -> (Bool, Error?) {
        return await withCheckedContinuation { continuation in
            Task {
                await rsyncEngine.startTransfer(request: request) { event in
                    Task { @MainActor in
                        switch event {
                        case .progress(let p): self.onProgress?(p)
                        case .speed(let s): self.onSpeed?(s)
                        case .eta(let e): self.onETA?(e)
                        case .currentFile(let f): self.onCurrentFile?(f)
                        case .log(let logStr): await self.loggerService.log(category: .transfer, message: logStr)
                        case .started: break
                        case .completed: continuation.resume(returning: (true, nil))
                        case .cancelled: continuation.resume(returning: (false, nil))
                        case .failed(let err): continuation.resume(returning: (false, err))
                        }
                    }
                }
            }
        }
    }
    
    private func executeVerify(request: VerificationRequest) async -> (Bool, Error?) {
        return await withCheckedContinuation { continuation in
            Task {
                await verifyEngine.startVerification(request: request) { event in
                    Task { @MainActor in
                        switch event {
                        case .progress(let p): self.onProgress?(p)
                        case .currentFile(let f): self.onCurrentFile?(f)
                        case .hashGenerated(let logMsg): await self.loggerService.log(category: .verify, message: logMsg)
                        case .started: break
                        case .completed(let result):
                            if result.status == .passed {
                                continuation.resume(returning: (true, nil))
                            } else {
                                let err = NSError(domain: "VerifyEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Verification failed."])
                                continuation.resume(returning: (false, err))
                            }
                        case .cancelled: continuation.resume(returning: (false, nil))
                        case .failed(let err): continuation.resume(returning: (false, err))
                        }
                    }
                }
            }
        }
    }
}
