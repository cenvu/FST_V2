import Foundation

public actor TransferCoordinator {
    public private(set) var state: TransferState = .ready
    
    // Dependencies
    private let driveService: DriveService
    private let loggerService: LoggerService
    private let rsyncEngine: RsyncEngine
    private let verifyEngine: VerifyEngine
    private let reportEngine: ReportEngine
    private let bundledRsyncService: BundledRsyncService
    
    // Callbacks for ViewModel
    private var onStateChanged: (@MainActor @Sendable (TransferState) -> Void)?
    private var onProgress: (@MainActor @Sendable (Double) -> Void)?
    private var onSpeed: (@MainActor @Sendable (Double) -> Void)?
    private var onTransferTime: (@MainActor @Sendable (TimeInterval) -> Void)?
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
        reportEngine: ReportEngine = ReportEngine(),
        bundledRsyncService: BundledRsyncService = BundledRsyncService()
    ) {
        self.driveService = driveService
        self.loggerService = loggerService
        self.rsyncEngine = rsyncEngine ?? RsyncEngine(bundledRsyncService: bundledRsyncService)
        self.verifyEngine = verifyEngine
        self.reportEngine = reportEngine
        self.bundledRsyncService = bundledRsyncService
    }

    public func configureCallbacks(
        onStateChanged: (@MainActor @Sendable @escaping (TransferState) -> Void),
        onProgress: (@MainActor @Sendable @escaping (Double) -> Void),
        onSpeed: (@MainActor @Sendable @escaping (Double) -> Void),
        onTransferTime: (@MainActor @Sendable @escaping (TimeInterval) -> Void),
        onCurrentFile: (@MainActor @Sendable @escaping (String) -> Void),
        onError: (@MainActor @Sendable @escaping (String) -> Void),
        onLog: (@MainActor @Sendable @escaping (LogEntry) -> Void)
    ) {
        self.onStateChanged = onStateChanged
        self.onProgress = onProgress
        self.onSpeed = onSpeed
        self.onTransferTime = onTransferTime
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
        let workflowStartDate = Date()
        var sourceMetadata: SourceStorageMetadata?

        // STATE: VALIDATING
        await updateState(.validating)
        await log(category: .info, message: "Validating transfer requirements...")
        
        do {
            try await driveService.validateSource(at: source)
            let scannedSourceMetadata = try await driveService.sourceMetadata(for: source)
            sourceMetadata = scannedSourceMetadata
            try await driveService.validateDestination(at: destination)
            let freeSpace = try await driveService.calculateReliableFreeSpace(at: destination)
            _ = try TransferPreflightValidator.validate(
                source: source,
                destination: destination,
                sourceMetadata: scannedSourceMetadata,
                destinationFreeSpaceBytes: freeSpace
            )
        } catch {
            let message = "TRANSFER ERROR: \(error.localizedDescription)"
            await log(category: .error, message: message)
            await onError?(message)
            await updateState(.error)
            await saveTerminalReport(
                source: source,
                destination: destination,
                bandwidthLimit: bandwidthLimit,
                mode: mode,
                finalStatus: .error,
                verificationResult: nil,
                sourceMetadata: sourceMetadata,
                failureReason: message,
                startedAt: workflowStartDate,
                endedAt: Date()
            )
            return
        }
        
        if isCancelled {
            await updateState(.cancelled)
            await saveTerminalReport(
                source: source,
                destination: destination,
                bandwidthLimit: bandwidthLimit,
                mode: mode,
                finalStatus: .cancelled,
                verificationResult: nil,
                sourceMetadata: sourceMetadata,
                failureReason: "Transfer was cancelled.",
                startedAt: workflowStartDate,
                endedAt: Date()
            )
            return
        }
        
        // STATE: COPYING
        await updateState(.copying)
        let request = TransferRequest(sourceURL: source, destinationURL: destination, bandwidthLimit: bandwidthLimit)
        let (rsyncSuccess, rsyncError) = await executeRsync(request: request)
        
        if isCancelled {
            await updateState(.cancelled)
            await saveTerminalReport(
                source: source,
                destination: destination,
                bandwidthLimit: bandwidthLimit,
                mode: mode,
                finalStatus: .cancelled,
                verificationResult: nil,
                sourceMetadata: sourceMetadata,
                failureReason: "Transfer was cancelled.",
                startedAt: workflowStartDate,
                endedAt: Date()
            )
            return
        }
        
        if !rsyncSuccess {
            let failureReason: String?
            if let err = rsyncError {
                failureReason = "TRANSFER ERROR: \(err.localizedDescription)"
                await onError?(failureReason ?? "TRANSFER ERROR")
            } else {
                failureReason = "TRANSFER ERROR: Transfer failed."
            }
            await updateState(.error)
            await saveTerminalReport(
                source: source,
                destination: destination,
                bandwidthLimit: bandwidthLimit,
                mode: mode,
                finalStatus: .error,
                verificationResult: nil,
                sourceMetadata: sourceMetadata,
                failureReason: failureReason,
                startedAt: workflowStartDate,
                endedAt: Date()
            )
            return
        }
        
        // Mode None -> Fast Exit
        if mode == .none {
            await updateState(.copyComplete)
            await log(category: .system, message: "TRANSFER COMPLETE. Verification disabled.")
            await saveTerminalReport(
                source: source,
                destination: destination,
                bandwidthLimit: bandwidthLimit,
                mode: mode,
                finalStatus: .copyComplete,
                verificationResult: nil,
                sourceMetadata: sourceMetadata,
                failureReason: nil,
                startedAt: workflowStartDate,
                endedAt: Date()
            )
            return
        }
        
        // STATE: VERIFYING
        await updateState(.verifying)
        let verifiedDestination = destination.appendingPathComponent(source.lastPathComponent, isDirectory: true)
        let verifyRequest = VerificationRequest(sourceURL: source, destinationURL: verifiedDestination, mode: mode)
        let (verifySuccess, verificationResult, verifyError) = await executeVerify(request: verifyRequest)
        
        if isCancelled {
            await updateState(.cancelled)
            await saveTerminalReport(
                source: source,
                destination: destination,
                bandwidthLimit: bandwidthLimit,
                mode: mode,
                finalStatus: .cancelled,
                verificationResult: verificationResult,
                sourceMetadata: sourceMetadata,
                failureReason: "Transfer was cancelled.",
                startedAt: workflowStartDate,
                endedAt: Date()
            )
            return
        }
        
        if !verifySuccess {
            let failureReason: String?
            if let err = verifyError {
                failureReason = "MANUAL CHECK REQUIRED: \(err.localizedDescription)"
                await onError?(failureReason ?? "MANUAL CHECK REQUIRED")
            } else {
                failureReason = "MANUAL CHECK REQUIRED: Verification failed."
            }
            await updateState(.error)
            await saveTerminalReport(
                source: source,
                destination: destination,
                bandwidthLimit: bandwidthLimit,
                mode: mode,
                finalStatus: .error,
                verificationResult: verificationResult ?? failedVerificationResult(sourceMetadata: sourceMetadata),
                sourceMetadata: sourceMetadata,
                failureReason: failureReason,
                startedAt: workflowStartDate,
                endedAt: Date()
            )
            return
        }
        
        // Internal state name is legacy; operator-facing language is SAFE TO EJECT.
        await updateState(.safeToFormat)
        await log(category: .system, message: "Verification Passed. SAFE TO EJECT.")
        await saveTerminalReport(
            source: source,
            destination: destination,
            bandwidthLimit: bandwidthLimit,
            mode: mode,
            finalStatus: .safeToFormat,
            verificationResult: verificationResult,
            sourceMetadata: sourceMetadata,
            failureReason: nil,
            startedAt: workflowStartDate,
            endedAt: Date()
        )
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
                let rsyncEventStartedAt = Date()
                var didLogFirstProgressForward = false
                var didLogFirstSpeedForward = false
                var didLogFirstTransferTimeForward = false
                for await event in eventStream {
                    switch event {
                    case .progress(let p):
                        await self.onProgress?(p)
                        if p > 0, !didLogFirstProgressForward {
                            didLogFirstProgressForward = true
                            await self.log(
                                category: .progress,
                                message: String(format: "DIAG [COORDINATOR] First progress forwarded: %.1f%% at +%ds", p, self.elapsedSeconds(since: rsyncEventStartedAt))
                            )
                        }
                        await self.log(category: .progress, message: "Progress \(Int(p.rounded()))%")
                    case .speed(let s):
                        await self.onSpeed?(s)
                        if s > 0, !didLogFirstSpeedForward {
                            didLogFirstSpeedForward = true
                            await self.log(
                                category: .progress,
                                message: String(format: "DIAG [COORDINATOR] First speed forwarded: %.2f MB/s at +%ds", s, self.elapsedSeconds(since: rsyncEventStartedAt))
                            )
                        }
                        await self.log(category: .progress, message: String(format: "Speed %.2f MB/s", s))
                    case .eta(let e):
                        await self.onTransferTime?(e)
                        if e > 0, !didLogFirstTransferTimeForward {
                            didLogFirstTransferTimeForward = true
                            await self.log(
                                category: .progress,
                                message: "DIAG [COORDINATOR] First rsync time forwarded: \(self.formatTransferTime(e)) at +\(self.elapsedSeconds(since: rsyncEventStartedAt))s"
                            )
                        }
                        await self.log(category: .progress, message: "Rsync Time \(self.formatTransferTime(e))")
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
                        await self.log(category: .error, message: "TRANSFER ERROR: \(err.localizedDescription)")
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
    
    private func executeVerify(request: VerificationRequest) async -> (Bool, VerificationResult?, Error?) {
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
                            continuation.resume(returning: (true, result, nil))
                        } else {
                            let err = NSError(domain: "VerifyEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Verification failed."])
                            await self.log(category: .error, message: "MANUAL CHECK REQUIRED: \(err.localizedDescription)")
                            continuation.resume(returning: (false, result, err))
                        }
                        didResume = true
                    case .cancelled:
                        await self.log(category: .warning, message: "Verification Cancelled")
                        continuation.resume(returning: (false, nil, nil))
                        didResume = true
                    case .failed(let err):
                        await self.log(category: .error, message: "MANUAL CHECK REQUIRED: \(err.localizedDescription)")
                        continuation.resume(returning: (false, nil, err))
                        didResume = true
                    }

                    if didResume {
                        break
                    }
                }
            }
        }
    }

    private func saveTerminalReport(
        source: URL,
        destination: URL,
        bandwidthLimit: Int?,
        mode: VerificationMode,
        finalStatus: TransferState,
        verificationResult: VerificationResult?,
        sourceMetadata: SourceStorageMetadata?,
        failureReason: String?,
        startedAt: Date,
        endedAt: Date
    ) async {
        let bundledInfo = await bundledRsyncService.bundledInfo()
        let createdAt = Date()
        let report = makeReport(
            source: source,
            destination: destination,
            mode: mode,
            finalStatus: finalStatus,
            verificationResult: verificationResult,
            sourceMetadata: sourceMetadata,
            failureReason: failureReason,
            startedAt: startedAt,
            endedAt: endedAt,
            createdAt: createdAt,
            bundledInfo: bundledInfo
        )
        guard let reportFolder = TransferPreflightValidator.safeReportFolder(source: source, destination: destination) else {
            await log(category: .warning, message: "Report skipped: no report was written because the destination was unsafe for report output.")
            return
        }

        do {
            let reportURL = try await reportEngine.saveReport(
                report: report,
                bandwidthLimit: bandwidthLimit,
                to: reportFolder
            )
            await log(category: .system, message: "Report saved: \(reportURL.path)")
        } catch {
            await log(category: .warning, message: "Report write failed: \(error.localizedDescription)")
        }
    }

    private func makeReport(
        source: URL,
        destination: URL,
        mode: VerificationMode,
        finalStatus: TransferState,
        verificationResult: VerificationResult?,
        sourceMetadata: SourceStorageMetadata?,
        failureReason: String?,
        startedAt: Date,
        endedAt: Date,
        createdAt: Date,
        bundledInfo: BundledRsyncInfo
    ) -> TransferReport {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")

        let verifiedFiles = verificationResult?.verifiedFiles ?? 0
        let passedFiles = verificationResult?.passedFiles ?? 0
        let failedFiles = verificationResult?.failedFiles ?? 0
        let errorCount = finalStatus == .error ? max(1, failedFiles) : 0
        let rsyncPath = bundledInfo.executableURL?.path ?? "Unavailable"

        return TransferReport(
            date: dateFormatter.string(from: createdAt),
            time: timeFormatter.string(from: createdAt),
            createdAt: createdAt,
            startedAt: startedAt,
            endedAt: endedAt,
            sourcePath: source.path,
            destinationPath: destination.path,
            sourceName: sourceMetadata?.folderName ?? source.lastPathComponent,
            destinationName: destination.lastPathComponent,
            totalSize: sourceMetadata?.totalSizeBytes ?? 0,
            fileCount: sourceMetadata?.fileCount ?? verificationResult?.totalFiles ?? 0,
            transferDuration: endedAt.timeIntervalSince(startedAt),
            averageSpeed: averageSpeedMBps(totalSizeBytes: sourceMetadata?.totalSizeBytes ?? 0, duration: endedAt.timeIntervalSince(startedAt)),
            verificationMode: mode,
            verificationResult: verificationResult?.status,
            verifiedFiles: verifiedFiles,
            passedFiles: passedFiles,
            failedFiles: failedFiles,
            failureReason: failureReason,
            rsyncBinaryPath: rsyncPath,
            rsyncVersion: bundledInfo.version,
            errorCount: errorCount,
            finalStatus: finalStatus
        )
    }

    private func failedVerificationResult(sourceMetadata: SourceStorageMetadata?) -> VerificationResult {
        VerificationResult(
            totalFiles: sourceMetadata?.fileCount ?? 0,
            verifiedFiles: 0,
            passedFiles: 0,
            failedFiles: 1,
            duration: 0,
            status: .failed
        )
    }

    private func averageSpeedMBps(totalSizeBytes: Int64, duration: TimeInterval) -> Double {
        guard duration > 0, totalSizeBytes > 0 else { return 0 }
        return (Double(totalSizeBytes) / 1_048_576.0) / duration
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

    private func formatTransferTime(_ time: TimeInterval) -> String {
        guard time > 0 else { return "--:--" }
        let totalSeconds = Int(time.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func elapsedSeconds(since startDate: Date) -> Int {
        max(0, Int(Date().timeIntervalSince(startDate).rounded(.down)))
    }
}
