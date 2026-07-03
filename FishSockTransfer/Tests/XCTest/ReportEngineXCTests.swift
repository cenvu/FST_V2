import XCTest

final class ReportEngineXCTests: XCTestCase {
    func testCopyOnlyReportIsTransferCompleteAndNotSafeToEject() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("App Name:            FishSockTransfer"))
        XCTAssertTrue(text.contains("Final Status:        TRANSFER COMPLETE"))
        XCTAssertTrue(text.contains("Verification Result: OFF - NOT VERIFIED BY FST"))
        XCTAssertTrue(text.contains("Copy Duration:       00:00:20"))
        XCTAssertTrue(text.contains("Verify Duration:     N/A"))
        XCTAssertTrue(text.contains("Total Duration:      00:01:40"))
        XCTAssertTrue(text.contains(copyAverageSpeedLine("50.00 MB/s")))
        XCTAssertFalse(text.contains(oldTransferDurationLabel))
        XCTAssertFalse(text.contains(oldAverageSpeedLabel))
        XCTAssertTrue(text.contains("Copy completed, but this transfer was not verified by FST."))
        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
        XCTAssertFalse(text.contains(formerFormatLabel))
    }

    func testVerifiedPassReportIsSafeToEjectWithCountsAndRsyncInfo() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .safeToFormat,
                mode: .full,
                verificationStatus: .passed,
                verifiedFiles: 10,
                passedFiles: 10,
                failedFiles: 0
            ),
            bandwidthLimit: RsyncBandwidthLimit.kibPerSecond(for: 120)
        )

        XCTAssertTrue(text.contains("Final Status:        SAFE TO EJECT"))
        XCTAssertTrue(text.contains("Copy Duration:       00:00:20"))
        XCTAssertTrue(text.contains("Verify Duration:     00:01:20"))
        XCTAssertTrue(text.contains("Total Duration:      00:01:40"))
        XCTAssertTrue(text.contains(copyAverageSpeedLine("50.00 MB/s")))
        XCTAssertTrue(text.contains("Verification Mode:   xxHash64 Full 100%"))
        XCTAssertTrue(text.contains("Hash Algorithm:      xxHash64"))
        XCTAssertTrue(text.contains("Fast non-cryptographic hash verification"))
        XCTAssertTrue(text.contains("Verification Result: PASSED"))
        XCTAssertTrue(text.contains("Verified Files:      10"))
        XCTAssertTrue(text.contains("Passed Files:        10"))
        XCTAssertTrue(text.contains("Failed Files:        0"))
        XCTAssertTrue(text.contains("Rsync Binary Path:   /App/Contents/Resources/rsync"))
        XCTAssertTrue(text.contains("Rsync Version:       3.4.4"))
        XCTAssertFalse(text.contains(formerFormatLabel))
    }

    func testReportTimingUsesCopyDurationForCopyAverageSpeed() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .safeToFormat,
                mode: .full,
                verificationStatus: .passed,
                copyDuration: 10,
                verificationDuration: 90,
                totalDuration: 100,
                copyAverageSpeed: 100
            ),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("Copy Duration:       00:00:10"))
        XCTAssertTrue(text.contains("Verify Duration:     00:01:30"))
        XCTAssertTrue(text.contains("Total Duration:      00:01:40"))
        XCTAssertTrue(text.contains(copyAverageSpeedLine("100.00 MB/s")))
        XCTAssertFalse(text.contains(copyAverageSpeedLine("10.00 MB/s")))
        XCTAssertFalse(text.contains(oldTransferDurationLabel))
        XCTAssertFalse(text.contains(oldAverageSpeedLabel))
    }

    func testInvalidCopyDurationShowsCopyAverageSpeedNA() async {
        let text = await ReportEngine().generateReportText(
            report: report(
                finalStatus: .copyComplete,
                mode: .none,
                verificationStatus: nil,
                copyDuration: 0,
                verificationDuration: nil,
                totalDuration: 100,
                copyAverageSpeed: nil
            ),
            bandwidthLimit: nil
        )

        XCTAssertTrue(text.contains("Copy Duration:       00:00:00"))
        XCTAssertTrue(text.contains("Verify Duration:     N/A"))
        XCTAssertTrue(text.contains(copyAverageSpeedLine("N/A")))
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
        XCTAssertTrue(text.contains("Verification Mode:   SHA256 Sample 33%"))
        XCTAssertTrue(text.contains("Hash Algorithm:      SHA256"))
        XCTAssertTrue(text.contains("Failure Reason:      MANUAL CHECK REQUIRED: Verification failed."))
        XCTAssertTrue(text.contains("Failed Files:        1"))
        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
        XCTAssertFalse(text.contains(formerFormatLabel))
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
        XCTAssertTrue(text.contains("Failure Reason:      TRANSFER ERROR: rsync failed."))
        XCTAssertFalse(text.contains("Final Status:        TRANSFER COMPLETE"))
        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
        XCTAssertFalse(text.contains(formerFormatLabel))
    }

    func testTruthfulnessGuardBlocksInvalidSafeToEjectFacts() async {
        let text = await ReportEngine().generateReportText(
            report: report(finalStatus: .safeToFormat, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )

        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
        XCTAssertFalse(text.contains(formerFormatLabel))
    }

    func testFilenameIsSafeUniqueAndDestinationSide() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let source = root.appendingPathComponent("A/B:Card 01", isDirectory: true)
        let destination = root.appendingPathComponent("Reports", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let engine = ReportEngine()
        let createdAt = Date(timeIntervalSince1970: 1_782_604_800)
        let firstURL = await engine.uniqueReportURL(sourceName: source.lastPathComponent, createdAt: createdAt, in: destination)
        try "existing".write(to: firstURL, atomically: true, encoding: .utf8)
        let secondURL = await engine.uniqueReportURL(sourceName: source.lastPathComponent, createdAt: createdAt, in: destination)

        XCTAssertFalse(firstURL.lastPathComponent.contains(":"))
        XCTAssertFalse(firstURL.lastPathComponent.contains(" "))
        XCTAssertNotEqual(firstURL.lastPathComponent, secondURL.lastPathComponent)

        let savedURL = try await engine.saveReport(
            report: report(
                finalStatus: .copyComplete,
                mode: .none,
                verificationStatus: nil,
                createdAt: createdAt,
                sourcePath: source.path,
                destinationPath: destination.path,
                sourceName: source.lastPathComponent
            ),
            bandwidthLimit: nil,
            to: destination
        )

        XCTAssertEqual(savedURL.deletingLastPathComponent().path, destination.path)
        XCTAssertFalse(savedURL.path.hasPrefix(source.path))
    }

    func testSaveReportWritesToDestinationFolder() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let destination = root.appendingPathComponent("ExternalDestination", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let savedURL = try await ReportEngine().saveReport(
            report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil,
            to: destination
        )

        XCTAssertEqual(savedURL.deletingLastPathComponent().path, destination.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedURL.path))
        XCTAssertTrue(savedURL.lastPathComponent.hasPrefix("FST_Report_"))
    }

    func testVerificationFailureReportStillSavesAndPreservesFailureReason() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let destination = root.appendingPathComponent("ExternalDestination", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let savedURL = try await ReportEngine().saveReport(
            report: report(
                finalStatus: .error,
                mode: .random33,
                verificationStatus: .failed,
                verifiedFiles: 3,
                passedFiles: 2,
                failedFiles: 1,
                failureReason: "MANUAL CHECK REQUIRED: clip.mov hash mismatch."
            ),
            bandwidthLimit: nil,
            to: destination
        )

        let text = try String(contentsOf: savedURL, encoding: .utf8)
        XCTAssertTrue(text.contains("Final Status:        MANUAL CHECK REQUIRED"))
        XCTAssertTrue(text.contains("Verification Result: FAILED"))
        XCTAssertTrue(text.contains("Failure Reason:      MANUAL CHECK REQUIRED: clip.mov hash mismatch."))
        XCTAssertFalse(text.contains("Final Status:        SAFE TO EJECT"))
    }

    func testReportWriteFailureIncludesAttemptedPathAndSystemError() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let missingDestination = root.appendingPathComponent("MissingDestination", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        do {
            _ = try await ReportEngine().saveReport(
                report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
                bandwidthLimit: nil,
                to: missingDestination
            )
            XCTFail("Report save should fail for a missing destination folder.")
        } catch let error as ReportWriteError {
            XCTAssertTrue(error.attemptedPath.hasPrefix(missingDestination.path))
            XCTAssertTrue(error.attemptedPath.contains("/FST_Report_CARD_A_"))
            XCTAssertFalse(error.systemErrorDescription.isEmpty)
            XCTAssertTrue(error.localizedDescription.contains(error.attemptedPath))
            XCTAssertTrue(error.localizedDescription.contains("System error:"))
        }
    }

    private var formerFormatLabel: String {
        ["SAFE", "TO", "FORMAT"].joined(separator: " ")
    }

    private var oldTransferDurationLabel: String {
        "\n" + ["Transfer", "Duration:"].joined(separator: " ")
    }

    private var oldAverageSpeedLabel: String {
        "\n" + ["Average", "Speed:"].joined(separator: " ")
    }

    private func copyAverageSpeedLine(_ value: String) -> String {
        ["Copy", "Average", "Speed:"].joined(separator: " ") + "  \(value)"
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
