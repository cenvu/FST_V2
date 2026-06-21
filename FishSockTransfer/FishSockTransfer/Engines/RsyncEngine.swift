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
        let bundledInfo = await bundledRsyncService.bundledInfo()
        guard bundledInfo.isAvailable else {
            for diagnostic in bundledInfo.diagnostics {
                onEvent(.log(diagnostic))
            }
            onEvent(.failed(.rsyncNotFound))
            cleanup()
            return
        }

        let command = RsyncCommand(bundledInfo: bundledInfo, request: request)
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
            for try await line in outPipe.fileHandleForReading.bytes.lines {
                if self.isCancelled { break }
                self.processOutputLine(line, onEvent: onEvent)
            }
        }
        
        let errTask = Task {
            for try await line in errPipe.fileHandleForReading.bytes.lines {
                if self.isCancelled { break }
                onEvent(.log("[STDERR] \(line)"))
            }
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
                onEvent(.cancelled)
            } else if status == 0 {
                onEvent(.completed)
            } else {
                onEvent(.failed(mapExitCode(status)))
            }
        } catch {
            if isCancelled {
                onEvent(.cancelled)
            } else {
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
            onEvent(.progress(data.progress))
            onEvent(.speed(data.speedMBps))
            onEvent(.eta(data.eta))
            onEvent(.log(String(format: "Actual Runtime Speed: %.2f MB/s", data.speedMBps)))
        } else {
            if !trimmed.contains("bytes/sec") && !trimmed.contains("total size is") {
                onEvent(.currentFile(trimmed))
            }
        }
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

nonisolated private struct RsyncCommand: Sendable {
    let executableURL: URL
    let versionDescription: String
    let arguments: [String]
    let bandwidthDiagnosticSummary: String
    let diagnostics: [String]

    var description: String {
        "\(versionDescription) at \(executableURL.path)"
    }

    init(bundledInfo: BundledRsyncInfo, request: TransferRequest) {
        guard let executableURL = bundledInfo.executableURL else {
            preconditionFailure("RsyncCommand requires an available rsync executable.")
        }

        self.executableURL = executableURL
        self.versionDescription = "bundled rsync \(bundledInfo.version)"
        self.diagnostics = bundledInfo.diagnostics

        var arguments = ["-a", "-h", "--info=progress2"]

        if let bwlimitKiBPerSecond = request.bandwidthLimit {
            let bandwidthArgumentValue = bwlimitKiBPerSecond
            let selectedLimitDescription = Self.selectedLimitDescription(kibPerSecond: bwlimitKiBPerSecond)

            arguments.append("--bwlimit=\(bandwidthArgumentValue)")
            self.bandwidthDiagnosticSummary = [
                "Selected Limit: \(selectedLimitDescription)",
                "Converted Limit: \(bwlimitKiBPerSecond) KiB/s",
                "Rsync Bwlimit Argument: --bwlimit=\(bandwidthArgumentValue)",
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

    private static func selectedLimitDescription(kibPerSecond: Int) -> String {
        let mibPerSecond = Double(kibPerSecond) / 1024.0
        if mibPerSecond.rounded() == mibPerSecond {
            return "\(Int(mibPerSecond)) MB/s"
        }
        return String(format: "%.2f MB/s", mibPerSecond)
    }
}
