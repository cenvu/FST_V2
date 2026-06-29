import Foundation

public actor RsyncEngine {
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    
    private var isCancelled = false
    private let copyTimingDiagnostics = RsyncCopyTimingDiagnostics()
    private var copyTimingHeartbeatTask: Task<Void, Never>?
    private let bundledRsyncService: BundledRsyncService
    
    public init(bundledRsyncService: BundledRsyncService = BundledRsyncService()) {
        self.bundledRsyncService = bundledRsyncService
    }
    
    public func startTransfer(request: TransferRequest, onEvent: @escaping @Sendable (TransferEvent) -> Void) async {
        isCancelled = false
        onEvent(.started)
        emitCopyRuntimeMetricsCleared(onEvent: onEvent)
        let bundledInfo = await bundledRsyncService.bundledInfo()
        guard bundledInfo.isAvailable else {
            for diagnostic in bundledInfo.diagnostics {
                onEvent(.log(diagnostic))
            }
            onEvent(.failed(.rsyncNotFound))
            cleanup()
            return
        }

        let command: RsyncCommand
        do {
            command = try RsyncCommand(bundledInfo: bundledInfo, request: request)
        } catch {
            onEvent(.log("Invalid bandwidth limit: \(error.localizedDescription)"))
            onEvent(.failed(.invalidBandwidthLimit))
            cleanup()
            return
        }

        for diagnostic in command.diagnostics {
            onEvent(.log(diagnostic))
        }
        onEvent(.log("Using \(command.description)"))
        onEvent(.log(command.bandwidthDiagnosticSummary))
        onEvent(.log("Rsync Args: \(command.arguments.joined(separator: " "))"))
        onEvent(.log("Rsync Command: \(command.executableURL.path) \(command.arguments.joined(separator: " "))"))
        
        let rsyncProcess = Process()
        self.process = rsyncProcess
        
        rsyncProcess.executableURL = command.executableURL
        rsyncProcess.arguments = command.arguments
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        self.stdoutPipe = outPipe
        self.stderrPipe = errPipe
        
        rsyncProcess.standardOutput = outPipe
        rsyncProcess.standardError = errPipe
        
        let copyTimingDiagnostics = copyTimingDiagnostics
        let outTask = Task.detached(priority: .userInitiated) {
            RsyncPipeDrainer.streamStdout(
                from: outPipe.fileHandleForReading,
                diagnostics: copyTimingDiagnostics,
                onEvent: onEvent
            )
        }
        
        let errTask = Task.detached(priority: .userInitiated) {
            RsyncPipeDrainer.streamStderr(
                from: errPipe.fileHandleForReading,
                diagnostics: copyTimingDiagnostics,
                onEvent: onEvent
            )
        }
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                rsyncProcess.terminationHandler = { _ in
                    continuation.resume(returning: ())
                }
                
                do {
                    try rsyncProcess.run()
                    Task {
                        self.markRsyncProcessStarted(onEvent: onEvent)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            _ = await outTask.result
            _ = await errTask.result
            stopRsyncTimingHeartbeat()
            
            let status = rsyncProcess.terminationStatus
            if isCancelled || status == 20 || status == 9 {
                emitCopyRuntimeMetricsCleared(onEvent: onEvent)
                onEvent(.cancelled)
            } else if status == 0 {
                onEvent(.progress(ProgressParser.completedCopyProgress))
                emitCopyRuntimeMetricsCleared(onEvent: onEvent)
                onEvent(.completed)
            } else {
                emitCopyRuntimeMetricsCleared(onEvent: onEvent)
                onEvent(.failed(mapExitCode(status)))
            }
        } catch {
            stopRsyncTimingHeartbeat()
            if isCancelled {
                emitCopyRuntimeMetricsCleared(onEvent: onEvent)
                onEvent(.cancelled)
            } else {
                emitCopyRuntimeMetricsCleared(onEvent: onEvent)
                onEvent(.failed(.processLaunchFailed))
            }
        }
        
        cleanup()
    }
    
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        process?.terminate()
    }
    
    private func markRsyncProcessStarted(onEvent: @escaping @Sendable (TransferEvent) -> Void) {
        copyTimingDiagnostics.reset(startedAt: Date())
        onEvent(.log("DIAG [RSYNC TIMING] Process started at +0s"))
        startRsyncTimingHeartbeat(onEvent: onEvent)
    }

    private func startRsyncTimingHeartbeat(onEvent: @escaping @Sendable (TransferEvent) -> Void) {
        stopRsyncTimingHeartbeat()
        copyTimingHeartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.emitRsyncTimingHeartbeat(onEvent: onEvent)
            }
        }
    }

    private func emitRsyncTimingHeartbeat(onEvent: @Sendable (TransferEvent) -> Void) {
        guard !copyTimingDiagnostics.hasProgressOutput else {
            stopRsyncTimingHeartbeat()
            return
        }

        onEvent(.log("DIAG [RSYNC TIMING] Copy active; waiting for rsync progress output... elapsed \(copyTimingDiagnostics.elapsedSeconds())s"))
    }

    private func stopRsyncTimingHeartbeat() {
        copyTimingHeartbeatTask?.cancel()
        copyTimingHeartbeatTask = nil
    }

    private func emitCopyRuntimeMetricsCleared(onEvent: @Sendable (TransferEvent) -> Void) {
        onEvent(.currentFile(""))
        onEvent(.speed(0.0))
        onEvent(.eta(0.0))
    }
    
    private func mapExitCode(_ code: Int32) -> TransferError {
        switch code {
        case 20: return .interrupted
        case 24: return .sourceUnavailable
        case 30: return .timeout
        default: return .rsyncExit(code)
        }
    }

    private func cleanup() {
        try? stdoutPipe?.fileHandleForReading.close()
        try? stderrPipe?.fileHandleForReading.close()
        stdoutPipe = nil
        stderrPipe = nil
        process = nil
    }
}

nonisolated enum RsyncPipeDrainer {
    private static let chunkSize = 32 * 1024

    static func streamStdout(
        from fileHandle: FileHandle,
        diagnostics: RsyncCopyTimingDiagnostics,
        onEvent: @escaping @Sendable (TransferEvent) -> Void
    ) {
        var framer = RsyncOutputFramer()
        var processor = RsyncStdoutRecordProcessor(diagnostics: diagnostics, onEvent: onEvent)

        while !Task.isCancelled {
            let data = fileHandle.readData(ofLength: chunkSize)
            if data.isEmpty { break }

            if let diagnostic = diagnostics.markFirstRawStdoutChunk(byteCount: data.count) {
                onEvent(.log(diagnostic))
            }

            for record in framer.append(data) {
                if Task.isCancelled { break }
                processor.process(record)
            }
        }

        if !Task.isCancelled, let record = framer.flush() {
            processor.process(record)
        }
    }

    static func streamStderr(
        from fileHandle: FileHandle,
        diagnostics: RsyncCopyTimingDiagnostics,
        onEvent: @escaping @Sendable (TransferEvent) -> Void
    ) {
        var framer = RsyncOutputFramer()

        while !Task.isCancelled {
            let data = fileHandle.readData(ofLength: chunkSize)
            if data.isEmpty { break }

            if let diagnostic = diagnostics.markFirstRawStderrChunk(byteCount: data.count) {
                onEvent(.log(diagnostic))
            }

            for record in framer.append(data) {
                if Task.isCancelled { break }
                processStderrRecord(record, diagnostics: diagnostics, onEvent: onEvent)
            }
        }

        if !Task.isCancelled, let record = framer.flush() {
            processStderrRecord(record, diagnostics: diagnostics, onEvent: onEvent)
        }
    }

    private static func processStderrRecord(
        _ record: String,
        diagnostics: RsyncCopyTimingDiagnostics,
        onEvent: @Sendable (TransferEvent) -> Void
    ) {
        let trimmed = record.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let diagnostic = diagnostics.markFirstFramedStderrRecord() {
            onEvent(.log(diagnostic))
        }

        onEvent(.log("[STDERR] \(trimmed)"))
    }
}

nonisolated struct RsyncStdoutRecordProcessor: Sendable {
    private let parser = ProgressParser()
    private let diagnostics: RsyncCopyTimingDiagnostics
    private var deliveryGate: RsyncProgressDeliveryGate
    private let onEvent: @Sendable (TransferEvent) -> Void

    init(
        diagnostics: RsyncCopyTimingDiagnostics,
        minimumProgressDeliveryInterval: TimeInterval = 0.12,
        onEvent: @escaping @Sendable (TransferEvent) -> Void
    ) {
        self.diagnostics = diagnostics
        self.deliveryGate = RsyncProgressDeliveryGate(minimumInterval: minimumProgressDeliveryInterval)
        self.onEvent = onEvent
    }

    mutating func process(_ record: String, now: Date = Date()) {
        let trimmed = record.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let diagnostic = diagnostics.markFirstFramedStdoutRecord() {
            onEvent(.log(diagnostic))
        }

        guard let data = parser.parse(line: record) else {
            onEvent(.log("[STDOUT] \(trimmed)"))
            return
        }

        if let diagnostic = diagnostics.markFirstParsedProgress2() {
            onEvent(.log(diagnostic))
        }

        let activeProgress = ProgressParser.activeCopyProgress(data.progress)
        let firstProgressDiagnostic = activeProgress > 0 ? diagnostics.markFirstStructuredProgressOverZero(activeProgress) : nil
        if let firstProgressDiagnostic {
            onEvent(.log(firstProgressDiagnostic))
        }

        guard deliveryGate.shouldDeliver(now: now, force: firstProgressDiagnostic != nil) else {
            return
        }

        onEvent(.log("[STDOUT] \(trimmed)"))
        onEvent(.progress(activeProgress))
        onEvent(.speed(data.speedMBps))
        onEvent(.eta(data.eta))
        onEvent(.log(String(format: "Actual Runtime Speed: %.2f MB/s", data.speedMBps)))
    }
}

nonisolated struct RsyncProgressDeliveryGate: Sendable {
    private let minimumInterval: TimeInterval
    private var lastDelivery: Date?

    init(minimumInterval: TimeInterval = 0.12) {
        self.minimumInterval = minimumInterval
    }

    mutating func shouldDeliver(now: Date = Date(), force: Bool = false) -> Bool {
        if force || lastDelivery == nil {
            lastDelivery = now
            return true
        }

        guard let lastDelivery else {
            self.lastDelivery = now
            return true
        }

        guard now.timeIntervalSince(lastDelivery) >= minimumInterval else {
            return false
        }

        self.lastDelivery = now
        return true
    }
}

nonisolated private struct RsyncCopyTimingState {
    var startedAt: Date?
    var didLogFirstRawStdout = false
    var didLogFirstRawStderr = false
    var didLogFirstFramedStdout = false
    var didLogFirstFramedStderr = false
    var didLogFirstProgress2 = false
    var didLogFirstProgressOverZero = false
}

nonisolated final class RsyncCopyTimingDiagnostics: @unchecked Sendable {
    private let lock = NSLock()
    private var state = RsyncCopyTimingState()

    var hasProgressOutput: Bool {
        lock.withLock {
            state.didLogFirstProgress2 || state.didLogFirstProgressOverZero
        }
    }

    func reset(startedAt: Date) {
        lock.withLock {
            state = RsyncCopyTimingState(startedAt: startedAt)
        }
    }

    func markFirstRawStdoutChunk(byteCount: Int) -> String? {
        lock.withLock {
            guard !state.didLogFirstRawStdout else { return nil }
            state.didLogFirstRawStdout = true
            return "DIAG [RSYNC RAW] First stdout chunk: \(byteCount) bytes at +\(elapsedSecondsLocked())s"
        }
    }

    func markFirstRawStderrChunk(byteCount: Int) -> String? {
        lock.withLock {
            guard !state.didLogFirstRawStderr else { return nil }
            state.didLogFirstRawStderr = true
            return "DIAG [RSYNC RAW] First stderr chunk: \(byteCount) bytes at +\(elapsedSecondsLocked())s"
        }
    }

    func markFirstFramedStdoutRecord() -> String? {
        lock.withLock {
            guard !state.didLogFirstFramedStdout else { return nil }
            state.didLogFirstFramedStdout = true
            return "DIAG [RSYNC TIMING] First framed stdout record at +\(elapsedSecondsLocked())s"
        }
    }

    func markFirstFramedStderrRecord() -> String? {
        lock.withLock {
            guard !state.didLogFirstFramedStderr else { return nil }
            state.didLogFirstFramedStderr = true
            return "DIAG [RSYNC TIMING] First framed stderr record at +\(elapsedSecondsLocked())s"
        }
    }

    func markFirstParsedProgress2() -> String? {
        lock.withLock {
            guard !state.didLogFirstProgress2 else { return nil }
            state.didLogFirstProgress2 = true
            return "DIAG [RSYNC TIMING] First parsed progress2 record at +\(elapsedSecondsLocked())s"
        }
    }

    func markFirstStructuredProgressOverZero(_ progress: Double) -> String? {
        lock.withLock {
            guard !state.didLogFirstProgressOverZero else { return nil }
            state.didLogFirstProgressOverZero = true
            return String(format: "DIAG [RSYNC TIMING] First structured progress >0: %.1f%% at +%ds", progress, elapsedSecondsLocked())
        }
    }

    func elapsedSeconds(now: Date = Date()) -> Int {
        lock.withLock {
            elapsedSecondsLocked(now: now)
        }
    }

    private func elapsedSecondsLocked(now: Date = Date()) -> Int {
        guard let startedAt = state.startedAt else { return 0 }
        return max(0, Int(now.timeIntervalSince(startedAt).rounded(.down)))
    }
}

nonisolated struct RsyncCommand: Sendable {
    let executableURL: URL
    let versionDescription: String
    let arguments: [String]
    let bandwidthDiagnosticSummary: String
    let diagnostics: [String]

    var description: String {
        "\(versionDescription) at \(executableURL.path)"
    }

    init(bundledInfo: BundledRsyncInfo, request: TransferRequest) throws {
        guard let executableURL = bundledInfo.executableURL else {
            preconditionFailure("RsyncCommand requires an available rsync executable.")
        }

        self.executableURL = executableURL
        self.versionDescription = "bundled rsync \(bundledInfo.version)"
        self.diagnostics = bundledInfo.diagnostics

        var arguments = ["-a", "-h", "--info=progress2", "--outbuf=L"]

        if let bwlimitArgument = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: request.bandwidthLimit),
           let bwlimitKiBPerSecond = request.bandwidthLimit {
            let selectedLimitDescription = RsyncBandwidthLimit.displayDescription(kibPerSecond: bwlimitKiBPerSecond)

            arguments.append(bwlimitArgument)
            self.bandwidthDiagnosticSummary = [
                "Selected Limit: \(selectedLimitDescription)",
                "Converted Limit: \(bwlimitKiBPerSecond) KiB/s",
                "Rsync Bwlimit Argument: \(bwlimitArgument)",
                "Rsync Version: \(versionDescription)"
            ].joined(separator: " | ")
        } else {
            self.bandwidthDiagnosticSummary = [
                "Selected Limit: Unlimited",
                "Converted Limit: none",
                "Rsync Bwlimit Argument: none",
                "Rsync Version: \(versionDescription)"
            ].joined(separator: " | ")
        }

        arguments.append(contentsOf: TransferFileExclusionPolicy.rsyncExclusionArguments)
        arguments.append(request.sourceURL.path)
        arguments.append(request.destinationURL.path + "/")
        self.arguments = arguments
    }
}
