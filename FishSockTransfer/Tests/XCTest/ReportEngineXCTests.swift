// FST / CenVu | (+84) 842 841 222

import XCTest

final class ReportEngineXCTests: XCTestCase {
    private let formerFormatLabel = ["SAFE", "TO", "FORMAT"].joined(separator: " ")
    private let formerTitleCaseFormatLabel = ["Safe", "To", "Format"].joined(separator: " ")
    private let formerLowercaseFormatLabel = ["safe", "to", "format"].joined(separator: " ")
    private let formerSourceFormatAuthorizationLabel = ["Source", "Format", "Authorization"].joined(separator: " ")
    private let formerSourceEraseAuthorizationLabel = ["Source", "Erase", "Authorization"].joined(separator: " ")
    private let infoFlag = ["--", "info"].joined()
    private let outbufFlag = ["--", "outbuf"].joined()
    private let bwlimitFlag = ["--", "bwlimit="].joined()

    func testReportIncludesBilingualDisclaimerNearTop() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("FST DETAILED TXT REPORT V1"))
        XCTAssertTrue(text.contains("Disclaimer / Miễn trừ trách nhiệm:"))
        XCTAssertTrue(text.contains("FST only reports copy and verification results. Any decision to erase, format, or reuse the source media is the sole responsibility of the user."))
        XCTAssertTrue(text.contains("FST chỉ báo cáo kết quả copy và verify. Mọi quyết định xoá, format, hoặc tái sử dụng media nguồn thuộc hoàn toàn trách nhiệm của người dùng."))
        let disclaimerRange = text.range(of: "Disclaimer / Miễn trừ trách nhiệm:")!
        let summaryRange = text.range(of: "Operator Summary")!
        XCTAssertTrue(disclaimerRange.lowerBound < summaryRange.lowerBound)
    }

    func testReportDoesNotContainForbiddenFormatAuthorizationWording() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .safeToFormat, mode: .full, verificationStatus: .passed),
            bandwidthLimit: nil
        )

        XCTAssertFalse(text.contains(formerFormatLabel))
        XCTAssertFalse(text.contains(formerTitleCaseFormatLabel))
        XCTAssertFalse(text.contains(formerLowercaseFormatLabel))
        XCTAssertFalse(text.contains(formerSourceFormatAuthorizationLabel))
        XCTAssertFalse(text.contains(formerSourceEraseAuthorizationLabel))
    }

    func testOperatorFacingRsyncDetailIsMinimalAndBandwidthIsHumanReadable() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .safeToFormat, mode: .full, verificationStatus: .passed),
            bandwidthLimit: RsyncBandwidthLimit.kibPerSecond(for: 120)
        )

        XCTAssertTrue(text.contains("Transfer Engine:     rsync 3.4.4"))
        XCTAssertTrue(text.contains("Bandwidth Limit:     120 MB/s"))
        XCTAssertFalse(text.contains("Rsync Binary Path:"))
        XCTAssertFalse(text.contains("Rsync Version:"))
        XCTAssertFalse(text.contains("/App/Contents/Resources/rsync"))
        XCTAssertFalse(text.contains(infoFlag))
        XCTAssertFalse(text.contains(outbufFlag))
        XCTAssertFalse(text.contains(bwlimitFlag))
        XCTAssertFalse(text.contains("122880"))
    }

    func testCopyOnlyReportIsTransferCompleteAndNotSafeToEject() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("App Name:            FishSockTransfer"))
        XCTAssertTrue(text.contains("Job ID:              FST-20260622-053000-1234ABCD"))
        XCTAssertTrue(text.contains("Final Status:        TRANSFER COMPLETE"))
        XCTAssertTrue(text.contains("SAFE TO EJECT DESTINATION: NO"))
        XCTAssertTrue(text.contains("Verification Result: OFF - NOT VERIFIED BY FST"))
        XCTAssertTrue(text.contains("Copy Duration:       00:00:20"))
        XCTAssertTrue(text.contains("Verify Duration:     N/A"))
        XCTAssertTrue(text.contains("Total Duration:      00:01:40"))
        XCTAssertTrue(text.contains("Copy Average Speed:  50.00 MB/s"))
        XCTAssertTrue(text.contains("Source Change Detection: NOT AVAILABLE IN V1"))
        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
    }

    func testRandom33PassUsesSHA256SampleAndRandomSampleScope() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .safeToFormat,
                mode: .random33,
                verificationStatus: .passed,
                verifiedFiles: 3,
                passedFiles: 3,
                failedFiles: 0
            ),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("Final Status:        SAFE TO EJECT"))
        XCTAssertTrue(text.contains("SAFE TO EJECT DESTINATION: YES"))
        XCTAssertTrue(text.contains("Verification Mode:   SHA256 Sample 33%"))
        XCTAssertTrue(text.contains("Verification Scope:  RANDOM SAMPLE"))
        XCTAssertTrue(text.contains("Hash Algorithm:      SHA256"))
        XCTAssertTrue(text.contains("Strong cryptographic hash verification"))
        XCTAssertFalse(text.contains("xxHash64 Full 100%"))
        XCTAssertFalse(text.contains("Verification Scope:  FULL 100%"))
    }

    func testFullPassUsesXXHash64FullAndSafeToEjectDestination() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .safeToFormat,
                mode: .full,
                verificationStatus: .passed,
                verifiedFiles: 10,
                passedFiles: 10,
                failedFiles: 0
            ),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("Final Status:        SAFE TO EJECT"))
        XCTAssertTrue(text.contains("SAFE TO EJECT DESTINATION: YES"))
        XCTAssertTrue(text.contains("Verification Mode:   xxHash64 Full 100%"))
        XCTAssertTrue(text.contains("Verification Scope:  FULL 100%"))
        XCTAssertTrue(text.contains("Hash Algorithm:      xxHash64"))
        XCTAssertTrue(text.contains("Fast non-cryptographic hash verification"))
        XCTAssertTrue(text.contains("Verified Files:      10"))
        XCTAssertTrue(text.contains("Passed Files:        10"))
        XCTAssertTrue(text.contains("Failed Files:        0"))
    }

    func testVerificationFailureReportRequiresManualCheck() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .error,
                mode: .random33,
                verificationStatus: .failed,
                verifiedFiles: 3,
                passedFiles: 2,
                failedFiles: 1,
                failureReason: "MANUAL CHECK REQUIRED: Verification failed."
            ),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("Final Status:        MANUAL CHECK REQUIRED"))
        XCTAssertTrue(text.contains("SAFE TO EJECT DESTINATION: NO"))
        XCTAssertTrue(text.contains("Verification Mode:   SHA256 Sample 33%"))
        XCTAssertTrue(text.contains("Verification Result: FAILED"))
        XCTAssertTrue(text.contains("- MANUAL CHECK REQUIRED: Verification failed."))
        XCTAssertTrue(text.contains("Failed Files:        1"))
        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
    }

    func testTransferFailureReportIsTransferError() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .error,
                mode: .random33,
                verificationStatus: nil,
                failureReason: "TRANSFER ERROR: rsync failed."
            ),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("Final Status:        TRANSFER ERROR"))
        XCTAssertTrue(text.contains("SAFE TO EJECT DESTINATION: NO"))
        XCTAssertTrue(text.contains("- TRANSFER ERROR: rsync failed."))
        XCTAssertFalse(text.contains("Final Status:        TRANSFER COMPLETE"))
        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
    }

    func testCancelledReportIsCancelledAndNotSafeToEject() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .cancelled,
                mode: .random33,
                verificationStatus: .cancelled,
                failureReason: "Transfer was cancelled."
            ),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("Final Status:        CANCELLED"))
        XCTAssertTrue(text.contains("SAFE TO EJECT DESTINATION: NO"))
        XCTAssertTrue(text.contains("Copy Result:         CANCELLED"))
        XCTAssertTrue(text.contains("Verification Result: CANCELLED"))
        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
    }

    func testTruthfulnessGuardBlocksInvalidSafeToEjectFacts() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .safeToFormat, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )

        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
        XCTAssertTrue(text.contains("Final Status:        MANUAL CHECK REQUIRED"))
        XCTAssertTrue(text.contains("SAFE TO EJECT DESTINATION: NO"))
    }

    func testWarningsAndErrorsRenderNoneWhenEmpty() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil,
            logs: []
        )

        XCTAssertTrue(text.contains("Warnings\n- None"))
        XCTAssertTrue(text.contains("Errors\nError Count:         0\n- None"))
        XCTAssertTrue(text.contains("TECHNICAL LOG"))
        XCTAssertTrue(text.contains("No log entries recorded."))
    }

    func testWarningsAndErrorsRenderLogEvidenceWhenPresent() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .error,
                mode: .full,
                verificationStatus: .failed,
                failureReason: "MANUAL CHECK REQUIRED: Verification failed."
            ),
            bandwidthLimit: nil,
            logs: [
                LogEntry(category: .warning, message: "Low destination free space warning."),
                LogEntry(category: .error, message: "Hash mismatch detected.")
            ]
        )

        XCTAssertTrue(text.contains("Warnings\n- Low destination free space warning."))
        XCTAssertTrue(text.contains("- MANUAL CHECK REQUIRED: Verification failed."))
        XCTAssertTrue(text.contains("- Hash mismatch detected."))
    }

    func testTechnicalLogPreservesRawDiagnosticLinesWhenProvided() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil,
            logs: [
                LogEntry(category: .info, message: "Starting transfer workflow"),
                LogEntry(category: .progress, message: "DIAG [COORDINATOR] First progress forwarded: 1.0% at +1s")
            ]
        )

        XCTAssertTrue(text.contains("FULL TECHNICAL LOG"))
        XCTAssertTrue(text.contains("Starting transfer workflow"))
        XCTAssertTrue(text.contains("DIAG [COORDINATOR]"))
    }

    func testFilenameIsSafeUniqueDestinationSideAndUsesJobID() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let source = root.appendingPathComponent("A/B:Card 01", isDirectory: true)
        let destination = root.appendingPathComponent("Reports", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let engine = ReportEngine()
        let jobID = "FST-20260622-053000-1234ABCD"
        let firstURL = await engine.uniqueReportURL(jobID: jobID, in: destination)
        try "existing".write(to: firstURL, atomically: true, encoding: .utf8)
        let secondURL = await engine.uniqueReportURL(jobID: jobID, in: destination)

        XCTAssertTrue(firstURL.lastPathComponent.contains(jobID))
        XCTAssertFalse(firstURL.lastPathComponent.contains("Card"))
        XCTAssertNotEqual(firstURL.lastPathComponent, secondURL.lastPathComponent)

        let savedURL = try await engine.saveReport(
            report: report(
                finalStatus: .copyComplete,
                mode: .none,
                verificationStatus: nil,
                sourcePath: source.path,
                destinationPath: destination.path,
                sourceName: source.lastPathComponent
            ),
            bandwidthLimit: nil,
            to: destination
        )

        XCTAssertEqual(savedURL.deletingLastPathComponent().path, destination.path)
        XCTAssertFalse(savedURL.path.hasPrefix(source.path))
        XCTAssertTrue(savedURL.lastPathComponent.contains(jobID))
        XCTAssertFalse(savedURL.lastPathComponent.contains(source.lastPathComponent))
    }

    private func report(
        finalStatus: TransferState,
        mode: VerificationMode,
        verificationStatus: VerificationStatus?,
        verifiedFiles: Int = 0,
        passedFiles: Int = 0,
        failedFiles: Int = 0,
        failureReason: String? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 1_782_604_800),
        sourcePath: String = "/Volumes/CARD_A",
        destinationPath: String = "/Volumes/RAID/CARD_A",
        sourceName: String = "CARD_A",
        copyDuration: TimeInterval? = 20,
        verificationDuration: TimeInterval? = nil,
        totalDuration: TimeInterval = 100,
        copyAverageSpeed: Double? = 50
    ) -> TransferReport {
        let effectiveVerificationDuration = mode == .none ? verificationDuration : (verificationDuration ?? 80)

        return TransferReport(
            jobID: "FST-20260622-053000-1234ABCD",
            date: "2026-06-22",
            time: "05:30:00",
            createdAt: createdAt,
            startedAt: Date(timeIntervalSince1970: 1_782_604_700),
            endedAt: Date(timeIntervalSince1970: 1_782_604_800),
            sourcePath: sourcePath,
            destinationPath: destinationPath,
            sourceName: sourceName,
            destinationName: URL(fileURLWithPath: destinationPath).lastPathComponent,
            totalSize: 1_048_576_000,
            fileCount: 10,
            copyDuration: copyDuration,
            verificationDuration: effectiveVerificationDuration,
            totalDuration: totalDuration,
            copyAverageSpeed: copyAverageSpeed,
            verificationMode: mode,
            verificationResult: verificationStatus,
            verifiedFiles: verifiedFiles,
            passedFiles: passedFiles,
            failedFiles: failedFiles,
            failureReason: failureReason,
            rsyncBinaryPath: "/App/Contents/Resources/rsync",
            rsyncVersion: "3.4.4",
            errorCount: finalStatus == .error ? 1 : 0,
            finalStatus: finalStatus
        )
    }
}
