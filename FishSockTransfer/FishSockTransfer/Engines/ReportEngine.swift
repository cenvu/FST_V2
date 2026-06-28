import Foundation

public actor ReportEngine {
    
    public init() {}
    
    public func generateReportText(report: TransferReport, bandwidthLimit: Int?) -> String {
        let limitString = RsyncBandwidthLimit.displayDescription(kibPerSecond: bandwidthLimit)
        let verifyResultStr = verificationResultDescription(for: report)
        let sizeMB = Double(report.totalSize) / 1_048_576.0
        let durationString = formatDuration(report.transferDuration)
        let finalStatusText = finalStatusDescription(for: report)
        let notes = notesDescription(for: report, finalStatusText: finalStatusText)
        
        var text = "====================================================\n"
        text += "             FST TRANSFER REPORT\n"
        text += "====================================================\n"
        text += "App Name:            \(report.appName)\n"
        text += "Report Created:      \(report.date) \(report.time)\n"
        text += "Start Time:          \(formatDate(report.startedAt))\n"
        text += "End Time:            \(formatDate(report.endedAt))\n"
        text += "Source Path:         \(report.sourcePath)\n"
        text += "Destination Path:    \(report.destinationPath)\n"
        text += "Source Name:         \(report.sourceName)\n"
        text += "Destination Name:    \(report.destinationName ?? "N/A")\n"
        text += "----------------------------------------------------\n"
        text += "Total Files:         \(report.fileCount)\n"
        text += String(format: "Total Size:          %.2f MB\n", sizeMB)
        text += "Bandwidth Limit:     \(limitString)\n"
        text += "Transfer Duration:   \(durationString)\n"
        text += String(format: "Average Speed:       %.2f MB/s\n", report.averageSpeed)
        text += "Copy Result:         \(copyResultDescription(for: report))\n"
        text += "----------------------------------------------------\n"
        text += "Verification Mode:   \(report.verificationMode.reportLabel)\n"
        text += "Verification Coverage: \(report.verificationMode.coverageDescription)\n"
        text += "Hash Algorithm:      \(report.verificationMode.hashAlgorithm?.displayName ?? "None")\n"
        if let hashNote = report.verificationMode.hashAlgorithm?.verificationNote {
            text += "Verification Note:   \(hashNote)\n"
        }
        text += "Verification Result: \(verifyResultStr)\n"
        text += "Verified Files:      \(report.verifiedFiles)\n"
        text += "Passed Files:        \(report.passedFiles)\n"
        text += "Failed Files:        \(report.failedFiles)\n"
        text += "----------------------------------------------------\n"
        text += "Rsync Binary Path:   \(report.rsyncBinaryPath)\n"
        text += "Rsync Version:       \(report.rsyncVersion)\n"
        text += "Exclusion Policy:    \(report.exclusionPolicySummary.joined(separator: ", "))\n"
        text += "Error Count:         \(report.errorCount)\n"
        if let failureReason = report.failureReason, !failureReason.isEmpty {
            text += "Failure Reason:      \(failureReason)\n"
        }
        text += "Final Status:        \(finalStatusText)\n"
        text += "----------------------------------------------------\n"
        text += "Notes:\n"
        text += notes
        text += "====================================================\n"
        
        return text
    }
    
    public func saveReport(report: TransferReport, bandwidthLimit: Int?, to destinationFolder: URL) async throws -> URL {
        let text = generateReportText(report: report, bandwidthLimit: bandwidthLimit)
        let fileURL = uniqueReportURL(sourceName: report.sourceName, createdAt: report.createdAt, in: destinationFolder)
        
        // Writing synchronously falls under the actor's execution context,
        // which moves it off the MainActor natively. Data safety is maintained.
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }

    public func uniqueReportURL(sourceName: String, createdAt: Date, in destinationFolder: URL) -> URL {
        let timestamp = formatFilenameDate(createdAt)
        let safeSourceName = sanitizedFilenameComponent(sourceName)
        let baseName = "FST_Report_\(safeSourceName)_\(timestamp)"
        var candidate = destinationFolder.appendingPathComponent("\(baseName).txt")
        var suffix = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = destinationFolder.appendingPathComponent("\(baseName)_\(suffix).txt")
            suffix += 1
        }

        return candidate
    }

    private func finalStatusDescription(for report: TransferReport) -> String {
        switch report.finalStatus {
        case .copyComplete:
            return "TRANSFER COMPLETE"
        case .safeToFormat:
            if report.verificationMode != .none, report.verificationResult == .passed {
                return "SAFE TO EJECT"
            }

            return "MANUAL CHECK REQUIRED"
        case .error:
            if report.verificationResult == .failed {
                return "MANUAL CHECK REQUIRED"
            }

            return "TRANSFER ERROR"
        case .cancelled:
            return "CANCELLED"
        case .ready, .validating, .copying, .verifying:
            return report.finalStatus.rawValue.uppercased()
        }
    }

    private func copyResultDescription(for report: TransferReport) -> String {
        switch report.finalStatus {
        case .copyComplete, .safeToFormat:
            return "PASSED"
        case .cancelled:
            return "CANCELLED"
        case .error:
            return report.verificationResult == .failed ? "PASSED" : "FAILED"
        case .ready, .validating, .copying, .verifying:
            return "INCOMPLETE"
        }
    }

    private func verificationResultDescription(for report: TransferReport) -> String {
        if report.verificationMode == .none {
            return "OFF - NOT VERIFIED BY FST"
        }

        switch report.verificationResult {
        case .passed:
            return "PASSED"
        case .failed:
            return "FAILED"
        case .cancelled:
            return "CANCELLED"
        case nil:
            return "N/A"
        }
    }

    private func notesDescription(for report: TransferReport, finalStatusText: String) -> String {
        switch finalStatusText {
        case "TRANSFER COMPLETE":
            return "- Verification was OFF.\n- Copy completed, but this transfer was not verified by FST.\n"
        case "SAFE TO EJECT":
            return "- Verification passed for the selected mode.\n- This report does not perform any format or eject operation.\n"
        case "MANUAL CHECK REQUIRED":
            return "- Verification did not pass. Do not treat this transfer as verified.\n"
        case "TRANSFER ERROR":
            return "- Transfer/preflight/rsync failed before a verified terminal success.\n"
        case "CANCELLED":
            return "- Transfer was cancelled and must not be treated as complete or verified.\n"
        default:
            return "- Terminal status recorded by FST.\n"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private func formatFilenameDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    private func sanitizedFilenameComponent(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }
        let sanitized = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return sanitized.isEmpty ? "Source" : sanitized
    }

}
