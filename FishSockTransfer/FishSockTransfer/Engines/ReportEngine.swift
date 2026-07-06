// FST / CenVu | (+84) 842 841 222

import Foundation

public actor ReportEngine {

    public init() {}

    /// Generates the TXT report summary only (no log section).
    /// Used by tests that do not exercise log appending.
    public func generateReportText(report: TransferReport, bandwidthLimit: Int?) -> String {
        generateReportText(report: report, bandwidthLimit: bandwidthLimit, logs: [])
    }

    /// Generates the TXT report summary followed by a full technical log section.
    ///
    /// - Parameters:
    ///   - logs: The full unfiltered log array. Must include DIAG entries for evidence.
    ///           Passing an empty array records an empty Technical Log section.
    public func generateReportText(report: TransferReport, bandwidthLimit: Int?, logs: [LogEntry]) -> String {
        let limitString = RsyncBandwidthLimit.displayDescription(kibPerSecond: bandwidthLimit)
        let verifyResultStr = verificationResultDescription(for: report)
        let sizeMB = Double(report.totalSize) / 1_048_576.0
        let finalStatusText = finalStatusDescription(for: report)
        let safeToEjectDestination = safeToEjectDestinationDescription(for: report)
        let decisionReason = safetyDecisionReason(for: report, finalStatusText: finalStatusText)
        let warningMessages = warningMessages(from: logs)
        let errorMessages = errorMessages(from: logs, failureReason: report.failureReason)

        var text = "====================================================\n"
        text += "        FST DETAILED TXT REPORT V1\n"
        text += "====================================================\n"
        text += "Disclaimer / Miễn trừ trách nhiệm:\n"
        text += "FST only reports copy and verification results. Any decision to erase, format, or reuse the source media is the sole responsibility of the user.\n"
        text += "FST chỉ báo cáo kết quả copy và verify. Mọi quyết định xoá, format, hoặc tái sử dụng media nguồn thuộc hoàn toàn trách nhiệm của người dùng.\n"
        text += "----------------------------------------------------\n"
        text += "Operator Summary\n"
        text += "Job ID:              \(report.jobID)\n"
        text += "Final Status:        \(finalStatusText)\n"
        text += "SAFE TO EJECT DESTINATION: \(safeToEjectDestination)\n"
        text += "Decision Reason:     \(decisionReason)\n"
        text += "Transfer Engine:     \(transferEngineDescription(for: report))\n"
        text += "----------------------------------------------------\n"
        text += "Source\n"
        text += "Source Path:         \(report.sourcePath)\n"
        text += "Source Name:         \(report.sourceName)\n"
        text += "Source Change Detection: NOT AVAILABLE IN V1 - FST does not authorize erase, format, or reuse decisions.\n"
        text += "----------------------------------------------------\n"
        text += "Destination\n"
        text += "Destination Path:    \(report.destinationPath)\n"
        text += "Destination Name:    \(report.destinationName ?? "N/A")\n"
        text += "----------------------------------------------------\n"
        text += "Copy Result\n"
        text += "Copy Result:         \(copyResultDescription(for: report))\n"
        text += "Total Files:         \(report.fileCount)\n"
        text += String(format: "Total Size:          %.2f MB\n", sizeMB)
        text += "Bandwidth Limit:     \(limitString)\n"
        text += "Copy Duration:       \(formatOptionalDuration(report.copyDuration))\n"
        text += "Copy Average Speed:  \(formatOptionalSpeed(report.copyAverageSpeed))\n"
        text += "----------------------------------------------------\n"
        text += "Verify Result\n"
        text += "Verification Mode:   \(report.verificationMode.reportLabel)\n"
        text += "Verification Scope:  \(verificationScopeDescription(for: report.verificationMode))\n"
        text += "Hash Algorithm:      \(report.verificationMode.hashAlgorithm?.displayName ?? "None")\n"
        if let hashNote = report.verificationMode.hashAlgorithm {
            text += "Verification Note:   \(hashNote.verificationNote)\n"
        }
        text += "Verification Result: \(verifyResultStr)\n"
        text += "Verify Duration:     \(formatOptionalDuration(report.verificationDuration))\n"
        text += "Verified Files:      \(report.verifiedFiles)\n"
        text += "Passed Files:        \(report.passedFiles)\n"
        text += "Failed Files:        \(report.failedFiles)\n"
        text += "----------------------------------------------------\n"
        text += "Safety Decision\n"
        text += "Final Status:        \(finalStatusText)\n"
        text += "SAFE TO EJECT DESTINATION: \(safeToEjectDestination)\n"
        text += "Decision Reason:     \(decisionReason)\n"
        text += "----------------------------------------------------\n"
        text += "Warnings\n"
        text += bulletList(warningMessages)
        text += "----------------------------------------------------\n"
        text += "Errors\n"
        text += "Error Count:         \(max(report.errorCount, errorMessages.count))\n"
        text += bulletList(errorMessages)
        text += "----------------------------------------------------\n"
        text += "Skipped Items\n"
        text += "Skipped Count:       NOT RECORDED IN V1\n"
        text += "Skipped Details:     Metadata/system files excluded by policy\n"
        text += "Exclusion Policy:    \(report.exclusionPolicySummary.joined(separator: ", "))\n"
        text += "----------------------------------------------------\n"
        text += "Timing\n"
        text += "Start Time:          \(formatDate(report.startedAt))\n"
        text += "End Time:            \(formatDate(report.endedAt))\n"
        text += "Total Duration:      \(formatDuration(report.totalDuration))\n"
        text += appendFullTechnicalLog(logs)
        text += "Report Generated Info\n"
        text += "App Name:            \(report.appName)\n"
        text += "Report Created:      \(report.date) \(report.time)\n"
        text += "====================================================\n"
        text += "Generated by FST / CenVu D.I.T Tools\n"

        return text
    }

    /// Saves the report summary only (no logs). Used by tests.
    public func saveReport(report: TransferReport, bandwidthLimit: Int?, to destinationFolder: URL) async throws -> URL {
        try await saveReport(report: report, bandwidthLimit: bandwidthLimit, logs: [], to: destinationFolder)
    }

    /// Saves the report with the full technical log appended.
    ///
    /// - Parameter logs: Full unfiltered log array. DIAG entries are included for evidence.
    public func saveReport(report: TransferReport, bandwidthLimit: Int?, logs: [LogEntry], to destinationFolder: URL) async throws -> URL {
        let text = generateReportText(report: report, bandwidthLimit: bandwidthLimit, logs: logs)
        let fileURL = uniqueReportURL(jobID: report.jobID, in: destinationFolder)

        // Writing synchronously falls under the actor's execution context,
        // which moves it off the MainActor natively. Data safety is maintained.
        try text.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    public func uniqueReportURL(jobID: String, in destinationFolder: URL) -> URL {
        let safeJobID = sanitizedFilenameComponent(jobID)
        let baseName = "FST_Report_\(safeJobID)"
        var candidate = destinationFolder.appendingPathComponent("\(baseName).txt")
        var suffix = 2

        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = destinationFolder.appendingPathComponent("\(baseName)_\(suffix).txt")
            suffix += 1
        }

        return candidate
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

    private func safeToEjectDestinationDescription(for report: TransferReport) -> String {
        finalStatusDescription(for: report) == "SAFE TO EJECT DESTINATION" ? "YES" : "NO"
    }

    private func transferEngineDescription(for report: TransferReport) -> String {
        let version = report.rsyncVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !version.isEmpty, version != "unknown" else {
            return "rsync unknown"
        }

        if version.localizedCaseInsensitiveContains("rsync") {
            return version
        }

        return "rsync \(version)"
    }

    private func finalStatusDescription(for report: TransferReport) -> String {
        switch report.finalStatus {
        case .copyComplete:
            return "TRANSFER COMPLETE"
        case .safeToFormat:
            if report.verificationMode != .none, report.verificationResult == .passed {
                return "SAFE TO EJECT DESTINATION"
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

    private func safetyDecisionReason(for report: TransferReport, finalStatusText: String) -> String {
        switch finalStatusText {
        case "TRANSFER COMPLETE":
            return "Copy completed; verification was OFF and this transfer was not verified by FST."
        case "SAFE TO EJECT DESTINATION":
            return "Copy completed and verification passed for the selected mode."
        case "MANUAL CHECK REQUIRED":
            return "Verification failed, mismatch was detected, or job facts are uncertain."
        case "TRANSFER ERROR":
            return "Preflight, copy, rsync, destination, or workflow failure blocked completion."
        case "CANCELLED":
            return "Operator cancelled the job or the workflow did not complete."
        default:
            return "Terminal status recorded by FST."
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

    private func verificationScopeDescription(for mode: VerificationMode) -> String {
        switch mode {
        case .none:
            return "NONE"
        case .random33:
            return "RANDOM SAMPLE"
        case .full:
            return "FULL 100%"
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

    private func warningMessages(from logs: [LogEntry]) -> [String] {
        logs
            .filter { $0.category == .warning }
            .map(\.message)
    }

    private func errorMessages(from logs: [LogEntry], failureReason: String?) -> [String] {
        var messages = logs
            .filter { $0.category == .error || $0.category == .stderr }
            .map(\.message)

        if let failureReason, !failureReason.isEmpty, !messages.contains(failureReason) {
            messages.insert(failureReason, at: 0)
        }

        return messages
    }

    private func bulletList(_ messages: [String]) -> String {
        guard !messages.isEmpty else {
            return "- None\n"
        }

        return messages.map { "- \($0)\n" }.joined()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func formatOptionalDuration(_ duration: TimeInterval?) -> String {
        guard let duration, duration.isFinite, duration >= 0 else {
            return "N/A"
        }

        return formatDuration(duration)
    }

    private func formatOptionalSpeed(_ speed: Double?) -> String {
        guard let speed, speed.isFinite, speed > 0 else {
            return "N/A"
        }

        return String(format: "%.2f MB/s", speed)
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

    // MARK: - Technical Log section

    private func appendFullTechnicalLog(_ logs: [LogEntry]) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")

        var section = "\n====================================================\n"
        section += logs.isEmpty ? "             TECHNICAL LOG\n" : "             FULL TECHNICAL LOG\n"
        section += "====================================================\n"
        section += "Technical Log Note:\n"
        section += "This section may include internal diagnostics and full local file paths. Review before sharing externally.\n"

        guard !logs.isEmpty else {
            section += "No log entries recorded.\n"
            section += "====================================================\n"
            return section
        }

        for entry in logs {
            let time = timeFormatter.string(from: entry.timestamp)
            section += "[\(time)] \(entry.level) \(entry.message)\n"
        }

        section += "====================================================\n"
        return section
    }

}
