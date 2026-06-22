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
        XCTAssertTrue(text.contains("Verification Result: PASSED"))
        XCTAssertTrue(text.contains("Verified Files:      10"))
        XCTAssertTrue(text.contains("Passed Files:        10"))
        XCTAssertTrue(text.contains("Failed Files:        0"))
        XCTAssertTrue(text.contains("Rsync Binary Path:   /App/Contents/Resources/rsync"))
        XCTAssertTrue(text.contains("Rsync Version:       3.4.4"))
        XCTAssertFalse(text.contains(formerFormatLabel))
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

    private var formerFormatLabel: String {
        ["SAFE", "TO", "FORMAT"].joined(separator: " ")
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
        sourceName: String = "CARD_A"
    ) -> TransferReport {
        TransferReport(
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
            transferDuration: 100,
            averageSpeed: 10,
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
