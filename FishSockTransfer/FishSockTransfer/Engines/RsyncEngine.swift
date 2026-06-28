import Foundation

public actor RsyncEngine {
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private let parser = ProgressParser()
    
    private var isCancelled = false
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
        
        let outTask = Task {
            await self.streamStdoutRecords(from: outPipe.fileHandleForReading, onEvent: onEvent)
        }
        
        let errTask = Task {
            await self.streamStderrRecords(from: errPipe.fileHandleForReading, onEvent: onEvent)
        }
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                rsyncProcess.terminationHandler = { _ in
                    continuation.resume(returning: ())
                }
                
                do {
                    try rsyncProcess.run()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            _ = await outTask.result
            _ = await errTask.result
            
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
    
    private func processOutputLine(_ line: String, onEvent: @Sendable (TransferEvent) -> Void) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onEvent(.log("[STDOUT] \(trimmed)"))
        
        if let data = parser.parse(line: line) {
            onEvent(.progress(ProgressParser.activeCopyProgress(data.progress)))
            onEvent(.speed(data.speedMBps))
            onEvent(.eta(data.eta))
            onEvent(.log(String(format: "Actual Runtime Speed: %.2f MB/s", data.speedMBps)))
        }
    }

    private func streamStdoutRecords(
        from fileHandle: FileHandle,
        onEvent: @Sendable (TransferEvent) -> Void
    ) async {
        var framer = RsyncOutputFramer()

        do {
            for try await byte in fileHandle.bytes {
                if isCancelled { break }
                for record in framer.append(Data([byte])) {
                    if isCancelled { break }
                    processOutputLine(record, onEvent: onEvent)
                }
            }
        } catch {
            // Pipe closure during process termination is expected; rsync exit status remains authoritative.
        }

        if !isCancelled, let record = framer.flush() {
            processOutputLine(record, onEvent: onEvent)
        }
    }

    private func streamStderrRecords(
        from fileHandle: FileHandle,
        onEvent: @Sendable (TransferEvent) -> Void
    ) async {
        var framer = RsyncOutputFramer()

        do {
            for try await byte in fileHandle.bytes {
                if isCancelled { break }
                for record in framer.append(Data([byte])) {
                    if isCancelled { break }
                    processErrorLine(record, onEvent: onEvent)
                }
            }
        } catch {
            // Pipe closure during process termination is expected; rsync exit status remains authoritative.
        }

        if !isCancelled, let record = framer.flush() {
            processErrorLine(record, onEvent: onEvent)
        }
    }

    private func processErrorLine(_ line: String, onEvent: @Sendable (TransferEvent) -> Void) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onEvent(.log("[STDERR] \(trimmed)"))
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
