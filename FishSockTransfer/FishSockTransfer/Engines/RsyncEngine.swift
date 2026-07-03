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
                    copyTimingDiagnostics.reset(startedAt: Date())
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
        onEvent(.log("DIAG [RSYNC TIMING] Rsync process started at +0s"))
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
            if let filename = parser.parseFilename(line: record) {
                if let diagnostic = diagnostics.markFirstParsedFilename(filename) {
                    onEvent(.log(diagnostic))
                }
                if let diagnostic = diagnostics.markFirstEngineCurrentFileEvent(filename) {
                    onEvent(.log(diagnostic))
                }
                onEvent(.log("[STDOUT] \(filename)"))
                onEvent(.currentFile(filename))
                return
            }

            onEvent(.log("[STDOUT] \(trimmed)"))
            return
        }

        if let diagnostic = diagnostics.markFirstParsedProgress2(data) {
            onEvent(.log(diagnostic))
        }

        let activeProgress = ProgressParser.activeCopyProgress(data.progress)
        if let diagnostic = diagnostics.markFirstEngineProgressEvent(data, activeProgress: activeProgress) {
            onEvent(.log(diagnostic))
        }
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

public actor DestinationActivityObserver {
    private var observationTask: Task<Void, Never>?
    private var isObserving = false

    public init() {}

    public func start(
        destinationRootURL: URL,
        totalBytes: Int64?,
        totalFiles: Int?,
        copyStartedAt: Date,
        cadenceSeconds: TimeInterval = 5,
        onSnapshot: @escaping @Sendable (CopyRuntimeSnapshot) -> Void,
        onLog: @escaping @Sendable (String) -> Void
    ) {
        observationTask?.cancel()
        isObserving = true
        let cadenceNanoseconds = UInt64(max(5, cadenceSeconds) * 1_000_000_000)
        onLog("DIAG [OBSERVER] OBSERVER started: \(destinationRootURL.path)")

        observationTask = Task.detached(priority: .utility) {
            var samples: [DestinationActivitySample] = []

            while !Task.isCancelled {
                do {
                    let now = Date()
                    let result = try DestinationActivitySnapshotter.snapshot(
                        destinationRootURL: destinationRootURL,
                        totalBytes: totalBytes,
                        totalFiles: totalFiles,
                        copyStartedAt: copyStartedAt,
                        previousSamples: samples,
                        now: now
                    )
                    samples = result.samples
                    onSnapshot(result.snapshot)
                    onLog(DestinationActivitySnapshotter.diagnosticMessage(for: result.snapshot))
                } catch is CancellationError {
                    return
                } catch {
                    onLog("DIAG [OBSERVER] OBSERVER unavailable: \(error.localizedDescription)")
                }

                try? await Task.sleep(nanoseconds: cadenceNanoseconds)
            }
        }
    }

    public func stop(reason: String, onLog: @escaping @Sendable (String) -> Void) {
        observationTask?.cancel()
        observationTask = nil
        if isObserving {
            onLog("DIAG [OBSERVER] OBSERVER stopped: \(reason)")
        }
        isObserving = false
    }

    public func isRunning() -> Bool {
        isObserving && observationTask?.isCancelled == false
    }
}

nonisolated struct DestinationActivitySample: Equatable, Sendable {
    let observedAt: Date
    let copiedBytes: Int64
    let copiedFiles: Int
    let currentItem: String?
}

nonisolated struct DestinationActivitySnapshotResult: Equatable, Sendable {
    let snapshot: CopyRuntimeSnapshot
    let samples: [DestinationActivitySample]
}

nonisolated enum DestinationActivitySnapshotter {
    private static let rollingWindowSeconds: TimeInterval = 15

    static func snapshot(
        destinationRootURL: URL,
        totalBytes: Int64?,
        totalFiles: Int?,
        copyStartedAt: Date,
        previousSamples: [DestinationActivitySample],
        now: Date = Date(),
        fileManager: FileManager = .default
    ) throws -> DestinationActivitySnapshotResult {
        let scan = try scanDestination(destinationRootURL: destinationRootURL, fileManager: fileManager)
        let copiedBytes = clampCopiedBytes(scan.copiedBytes, totalBytes: totalBytes)
        let copiedFiles = clampCopiedFiles(scan.copiedFiles, totalFiles: totalFiles)
        let elapsedSeconds = max(0, Int(now.timeIntervalSince(copyStartedAt).rounded(.down)))
        let sample = DestinationActivitySample(
            observedAt: now,
            copiedBytes: copiedBytes,
            copiedFiles: copiedFiles,
            currentItem: scan.currentItem
        )
        let samples = (previousSamples + [sample]).filter {
            now.timeIntervalSince($0.observedAt) <= rollingWindowSeconds
        }

        let currentSpeed = rollingSpeedBytesPerSecond(samples: samples)
        let averageSpeed = averageSpeedBytesPerSecond(copiedBytes: copiedBytes, elapsedSeconds: elapsedSeconds)
        let progress = progressFraction(copiedBytes: copiedBytes, totalBytes: totalBytes)
        let eta = etaSeconds(
            copiedBytes: copiedBytes,
            totalBytes: totalBytes,
            currentSpeedBytesPerSecond: currentSpeed
        )

        return DestinationActivitySnapshotResult(
            snapshot: CopyRuntimeSnapshot(
                elapsedSeconds: elapsedSeconds,
                currentItem: scan.currentItem,
                copiedBytes: copiedBytes,
                totalBytes: totalBytes,
                copiedFiles: copiedFiles,
                totalFiles: totalFiles,
                progressFraction: progress,
                currentSpeedBytesPerSecond: currentSpeed,
                averageSpeedBytesPerSecond: averageSpeed,
                etaSeconds: eta,
                signalSource: .destinationObserver,
                lastObservedAt: now,
                activityState: .observingDestination
            ),
            samples: samples
        )
    }

    static func diagnosticMessage(for snapshot: CopyRuntimeSnapshot) -> String {
        let currentItem = snapshot.currentItem ?? "-"
        let speed = snapshot.currentSpeedBytesPerSecond.map { String(format: "%.2f MB/s", $0 / 1_048_576.0) } ?? "-"
        let eta = snapshot.etaSeconds.map { formatDuration($0) } ?? "-"
        return "DIAG [OBSERVER] OBSERVER sample: copiedBytes=\(snapshot.copiedBytes) files=\(snapshot.copiedFiles) currentItem=\(currentItem) speed=\(speed) eta=\(eta)"
    }

    private static func scanDestination(
        destinationRootURL: URL,
        fileManager: FileManager
    ) throws -> (copiedBytes: Int64, copiedFiles: Int, currentItem: String?) {
        guard fileManager.fileExists(atPath: destinationRootURL.path) else {
            return (0, 0, nil)
        }

        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        guard let enumerator = fileManager.enumerator(
            at: destinationRootURL,
            includingPropertiesForKeys: keys,
            options: [.skipsPackageDescendants],
            errorHandler: nil
        ) else {
            return (0, 0, nil)
        }

        var copiedBytes: Int64 = 0
        var copiedFiles = 0
        var mostRecentFile: (path: String, modifiedAt: Date)?

        for case let itemURL as URL in enumerator {
            try Task.checkCancellation()
            let values = try itemURL.resourceValues(forKeys: Set(keys))

            if shouldExclude(itemURL, rootURL: destinationRootURL) {
                if values.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            guard values.isRegularFile == true else { continue }

            copiedFiles += 1
            copiedBytes += Int64(max(0, values.fileSize ?? 0))

            let relativePath = TransferFileExclusionPolicy.relativePath(for: itemURL, rootURL: destinationRootURL)
            let modifiedAt = values.contentModificationDate ?? .distantPast
            if mostRecentFile == nil || modifiedAt > mostRecentFile!.modifiedAt {
                mostRecentFile = (relativePath, modifiedAt)
            }
        }

        return (copiedBytes, copiedFiles, mostRecentFile?.path)
    }

    private static func shouldExclude(_ url: URL, rootURL: URL) -> Bool {
        if TransferFileExclusionPolicy.shouldExclude(url, rootURL: rootURL) {
            return true
        }

        return url.lastPathComponent.hasPrefix("FST_Report")
    }

    private static func clampCopiedBytes(_ copiedBytes: Int64, totalBytes: Int64?) -> Int64 {
        guard let totalBytes, totalBytes >= 0 else { return max(0, copiedBytes) }
        return min(max(0, copiedBytes), totalBytes)
    }

    private static func clampCopiedFiles(_ copiedFiles: Int, totalFiles: Int?) -> Int {
        guard let totalFiles, totalFiles >= 0 else { return max(0, copiedFiles) }
        return min(max(0, copiedFiles), totalFiles)
    }

    private static func progressFraction(copiedBytes: Int64, totalBytes: Int64?) -> Double? {
        guard let totalBytes, totalBytes > 0 else { return nil }
        return min(max(Double(copiedBytes) / Double(totalBytes), 0), 1)
    }

    private static func rollingSpeedBytesPerSecond(samples: [DestinationActivitySample]) -> Double? {
        guard let first = samples.first, let last = samples.last, samples.count >= 2 else { return nil }
        let elapsed = last.observedAt.timeIntervalSince(first.observedAt)
        guard elapsed > 0 else { return nil }
        let deltaBytes = last.copiedBytes - first.copiedBytes
        guard deltaBytes > 0 else { return nil }
        return Double(deltaBytes) / elapsed
    }

    private static func averageSpeedBytesPerSecond(copiedBytes: Int64, elapsedSeconds: Int) -> Double? {
        guard copiedBytes > 0, elapsedSeconds > 0 else { return nil }
        return Double(copiedBytes) / Double(elapsedSeconds)
    }

    private static func etaSeconds(
        copiedBytes: Int64,
        totalBytes: Int64?,
        currentSpeedBytesPerSecond: Double?
    ) -> TimeInterval? {
        guard let totalBytes, totalBytes > copiedBytes,
              let currentSpeedBytesPerSecond, currentSpeedBytesPerSecond > 0 else {
            return nil
        }

        return Double(totalBytes - copiedBytes) / currentSpeedBytesPerSecond
    }

    private static func formatDuration(_ duration: TimeInterval) -> String {
        guard duration > 0 else { return "-" }
        let totalSeconds = Int(duration.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

nonisolated private struct RsyncCopyTimingState {
    var startedAt: Date?
    var didLogFirstRawStdout = false
    var didLogFirstRawStderr = false
    var didLogFirstFramedStdout = false
    var didLogFirstFramedStderr = false
    var didLogFirstFilename = false
    var didLogFirstProgress2 = false
    var didLogFirstEngineCurrentFileEvent = false
    var didLogFirstEngineProgressEvent = false
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
            return "DIAG [RSYNC RAW] First rsync stdout byte after \(elapsedSecondsLocked())s; chunk \(byteCount) bytes"
        }
    }

    func markFirstRawStderrChunk(byteCount: Int) -> String? {
        lock.withLock {
            guard !state.didLogFirstRawStderr else { return nil }
            state.didLogFirstRawStderr = true
            return "DIAG [RSYNC RAW] First rsync stderr byte after \(elapsedSecondsLocked())s; chunk \(byteCount) bytes"
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

    func markFirstParsedFilename(_ filename: String) -> String? {
        lock.withLock {
            guard !state.didLogFirstFilename else { return nil }
            state.didLogFirstFilename = true
            return "DIAG [RSYNC TIMING] First rsync filename after \(elapsedSecondsLocked())s: \(filename)"
        }
    }

    func markFirstParsedProgress2(_ data: ProgressData) -> String? {
        lock.withLock {
            guard !state.didLogFirstProgress2 else { return nil }
            state.didLogFirstProgress2 = true
            return String(
                format: "DIAG [RSYNC TIMING] First rsync progress after %ds: %.1f%% / %.2f MB/s / %@",
                elapsedSecondsLocked(),
                data.progress,
                data.speedMBps,
                Self.timeValue(seconds: data.eta)
            )
        }
    }

    func markFirstEngineCurrentFileEvent(_ filename: String) -> String? {
        lock.withLock {
            guard !state.didLogFirstEngineCurrentFileEvent else { return nil }
            state.didLogFirstEngineCurrentFileEvent = true
            return "DIAG [RSYNC EVENT] ENGINE EVENT currentFile after \(elapsedSecondsLocked())s: \(filename)"
        }
    }

    func markFirstEngineProgressEvent(_ data: ProgressData, activeProgress: Double) -> String? {
        lock.withLock {
            guard !state.didLogFirstEngineProgressEvent else { return nil }
            state.didLogFirstEngineProgressEvent = true
            return String(
                format: "DIAG [RSYNC EVENT] ENGINE EVENT progress after %ds: raw %.1f%% / active %.1f%% / %.2f MB/s / %@",
                elapsedSecondsLocked(),
                data.progress,
                activeProgress,
                data.speedMBps,
                Self.timeValue(seconds: data.eta)
            )
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

    private static func timeValue(seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "-" }
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
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

        var arguments = ["-a", "-h", "--info=name1,progress2", "--outbuf=N"]

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
