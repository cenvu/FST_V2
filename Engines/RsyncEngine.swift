import Foundation

public actor RsyncEngine {
    private var process: Process?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private let parser = ProgressParser()
    
    private var isCancelled = false
    
    public init() {}
    
    public func startTransfer(request: TransferRequest, onEvent: @escaping (TransferEvent) -> Void) async {
        isCancelled = false
        onEvent(.started)
        onEvent(.log("Transfer Started"))
        
        let rsyncProcess = Process()
        self.process = rsyncProcess
        
        rsyncProcess.executableURL = URL(fileURLWithPath: "/usr/bin/rsync")
        
        var arguments = ["-a", "-h", "--info=progress2"]
        if let bwlimit = request.bandwidthLimit {
            arguments.append("--bwlimit=\(bwlimit)")
        }
        arguments.append(request.sourceURL.path + "/")
        arguments.append(request.destinationURL.path + "/")
        rsyncProcess.arguments = arguments
        
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
                onEvent(.log("ERROR: \(line)"))
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
                onEvent(.log("Transfer Cancelled"))
            } else if status == 0 {
                onEvent(.completed)
                onEvent(.log("Transfer Completed"))
            } else {
                onEvent(.failed(mapExitCode(status)))
                onEvent(.log("Transfer Failed with exit code \(status)"))
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
    
    private func processOutputLine(_ line: String, onEvent: (TransferEvent) -> Void) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let data = parser.parse(line: line) {
            onEvent(.progress(data.progress))
            onEvent(.speed(data.speedMBps))
            onEvent(.eta(data.eta))
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
        process?.standardOutput = nil
        process?.standardError = nil
        process = nil
    }
}
