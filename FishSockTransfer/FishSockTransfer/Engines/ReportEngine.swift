import Foundation

public actor ReportEngine {
    
    public init() {}
    
    public func generateReportText(report: TransferReport, bandwidthLimit: Int?) -> String {
        let limitString = RsyncBandwidthLimit.displayDescription(kibPerSecond: bandwidthLimit).uppercased()
        let verifyResultStr = report.verificationResult?.rawValue.uppercased() ?? "N/A"
        let sizeMB = Double(report.totalSize) / 1_048_576.0
        
        let hours = Int(report.transferDuration) / 3600
        let minutes = (Int(report.transferDuration) % 3600) / 60
        let seconds = Int(report.transferDuration) % 60
        let durationString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        let finalStatusText: String
        if report.finalStatus == .safeToFormat {
            finalStatusText = "SAFE TO FORMAT"
        } else if report.finalStatus == .copyComplete {
            finalStatusText = "COPY COMPLETE"
        } else {
            finalStatusText = report.finalStatus.rawValue.uppercased()
        }
        
        var text = "====================================================\n"
        text += "             FST TRANSFER REPORT\n"
        text += "====================================================\n"
        text += "Transfer Date:       \(report.date) \(report.time)\n"
        text += "Source Path:         \(report.sourcePath)\n"
        text += "Destination Path:    \(report.destinationPath)\n"
        text += "----------------------------------------------------\n"
        text += "Total Files:         \(report.fileCount)\n"
        text += String(format: "Total Size:          %.2f MB\n", sizeMB)
        text += "Bandwidth Limit:     \(limitString)\n"
        text += "Transfer Duration:   \(durationString)\n"
        text += String(format: "Average Speed:       %.2f MB/s\n", report.averageSpeed)
        text += "----------------------------------------------------\n"
        text += "Verification Mode:   \(report.verificationMode.rawValue.uppercased())\n"
        text += "Verification Result: \(verifyResultStr)\n"
        text += "Error Count:         \(report.errorCount)\n"
        text += "Final Status:        \(finalStatusText)\n"
        text += "====================================================\n"
        
        return text
    }
    
    public func saveReport(report: TransferReport, bandwidthLimit: Int?, to destinationFolder: URL) async throws -> URL {
        let text = generateReportText(report: report, bandwidthLimit: bandwidthLimit)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let fileName = "FST_Report_\(timestamp).txt"
        let fileURL = destinationFolder.appendingPathComponent(fileName)
        
        // Writing synchronously falls under the actor's execution context,
        // which moves it off the MainActor natively. Data safety is maintained.
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}
