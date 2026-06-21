import Foundation

private func assertContains(_ value: String, _ expectedSubstring: String, _ message: String) {
    guard value.contains(expectedSubstring) else {
        fatalError("\(message): missing '\(expectedSubstring)'")
    }
}

private func assertNotContains(_ value: String, _ unexpectedSubstring: String, _ message: String) {
    guard !value.contains(unexpectedSubstring) else {
        fatalError("\(message): found unexpected '\(unexpectedSubstring)'")
    }
}

@main
struct ReportEngineWordingTests {
    static func main() async {
        let engine = ReportEngine()
        let formerFormatLabel = ["SAFE", "TO", "FORMAT"].joined(separator: " ")

        let copyOnly = await engine.generateReportText(
            report: report(finalStatus: .copyComplete, verificationResult: nil, verificationMode: .none),
            bandwidthLimit: nil
        )
        assertContains(copyOnly, "Final Status:        TRANSFER COMPLETE", "copy-only report status")
        assertNotContains(copyOnly, "SAFE TO EJECT", "copy-only report must not imply verified eject status")
        assertNotContains(copyOnly, formerFormatLabel, "copy-only report must not use old format wording")

        let verified = await engine.generateReportText(
            report: report(finalStatus: .safeToFormat, verificationResult: .passed, verificationMode: .full),
            bandwidthLimit: nil
        )
        assertContains(verified, "Final Status:        SAFE TO EJECT", "verified report status")
        assertNotContains(verified, formerFormatLabel, "verified report must not use old format wording")

        let verificationFailed = await engine.generateReportText(
            report: report(finalStatus: .error, verificationResult: .failed, verificationMode: .random33),
            bandwidthLimit: nil
        )
        assertContains(verificationFailed, "Final Status:        MANUAL CHECK REQUIRED", "verification failure report status")
        assertNotContains(verificationFailed, formerFormatLabel, "verification failure report must not use old format wording")

        let transferFailed = await engine.generateReportText(
            report: report(finalStatus: .error, verificationResult: nil, verificationMode: .none),
            bandwidthLimit: nil
        )
        assertContains(transferFailed, "Final Status:        TRANSFER ERROR", "transfer failure report status")
        assertNotContains(transferFailed, formerFormatLabel, "transfer failure report must not use old format wording")

        print("ReportEngineWordingTests passed")
    }

    private static func report(
        finalStatus: TransferState,
        verificationResult: VerificationStatus?,
        verificationMode: VerificationMode
    ) -> TransferReport {
        TransferReport(
            date: "2026-06-22",
            time: "04:00:00",
            sourcePath: "/Volumes/CARD",
            destinationPath: "/Volumes/RAID/CARD",
            totalSize: 1_048_576,
            fileCount: 1,
            transferDuration: 60,
            averageSpeed: 10,
            verificationMode: verificationMode,
            verificationResult: verificationResult,
            errorCount: finalStatus == .error ? 1 : 0,
            finalStatus: finalStatus
        )
    }
}
