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

private func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

@main
struct ReportEngineMVPReportTests {
    static func main() async throws {
        let engine = ReportEngine()
        let formerFormatLabel = ["SAFE", "TO", "FORMAT"].joined(separator: " ")

        let copyOnly = await engine.generateReportText(
            report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )
        assertContains(copyOnly, "App Name:            FishSockTransfer", "copy-only app name")
        assertContains(copyOnly, "Final Status:        TRANSFER COMPLETE", "copy-only final status")
        assertContains(copyOnly, "Verification Result: OFF - NOT VERIFIED BY FST", "copy-only verification off")
        assertContains(copyOnly, "Copy completed, but this transfer was not verified by FST.", "copy-only warning")
        assertNotContains(copyOnly, "Final Status:        SAFE TO EJECT", "copy-only must not be safe eject")
        assertNotContains(copyOnly, formerFormatLabel, "copy-only must not use old format wording")

        let verified = await engine.generateReportText(
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
        assertContains(verified, "Final Status:        SAFE TO EJECT", "verified final status")
        assertContains(verified, "Verification Mode:   xxHash64 Full 100%", "verified mode")
        assertContains(verified, "Hash Algorithm:      xxHash64", "verified hash algorithm")
        assertContains(verified, "Fast non-cryptographic hash verification", "xxHash64 note")
        assertContains(verified, "Verification Result: PASSED", "verified result")
        assertContains(verified, "Verified Files:      10", "verified count")
        assertContains(verified, "Passed Files:        10", "passed count")
        assertContains(verified, "Failed Files:        0", "failed count")
        assertContains(verified, "Rsync Binary Path:   /App/Contents/Resources/rsync", "rsync path")
        assertContains(verified, "Rsync Version:       3.4.4", "rsync version")
        assertNotContains(verified, formerFormatLabel, "verified report must not use old format wording")

        let verificationFailed = await engine.generateReportText(
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
        assertContains(verificationFailed, "Final Status:        MANUAL CHECK REQUIRED", "verification failure final status")
        assertContains(verificationFailed, "Verification Mode:   SHA256 Sample 33%", "verification failure mode")
        assertContains(verificationFailed, "Hash Algorithm:      SHA256", "verification failure hash algorithm")
        assertContains(verificationFailed, "Failure Reason:      MANUAL CHECK REQUIRED: Verification failed.", "verification failure reason")
        assertContains(verificationFailed, "Failed Files:        1", "verification failure count")
        assertNotContains(verificationFailed, "Final Status:        SAFE TO EJECT", "verification failure must not be safe eject")
        assertNotContains(verificationFailed, formerFormatLabel, "verification failure must not use old format wording")

        let transferFailed = await engine.generateReportText(
            report: report(
                finalStatus: .error,
                mode: .random33,
                verificationStatus: nil,
                failureReason: "TRANSFER ERROR: rsync failed."
            ),
            bandwidthLimit: nil
        )
        assertContains(transferFailed, "Final Status:        TRANSFER ERROR", "transfer failure final status")
        assertContains(transferFailed, "Failure Reason:      TRANSFER ERROR: rsync failed.", "transfer failure reason")
        assertNotContains(transferFailed, "Final Status:        TRANSFER COMPLETE", "transfer failure must not be complete")
        assertNotContains(transferFailed, "Final Status:        SAFE TO EJECT", "transfer failure must not be safe eject")
        assertNotContains(transferFailed, formerFormatLabel, "transfer failure must not use old format wording")

        let invalidSafeEjectFacts = await engine.generateReportText(
            report: report(finalStatus: .safeToFormat, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )
        assertNotContains(invalidSafeEjectFacts, "Final Status:        SAFE TO EJECT", "truthfulness guard must block invalid safe eject")
        assertNotContains(invalidSafeEjectFacts, formerFormatLabel, "truthfulness guard must not use old format wording")

        try await testFilenameAndDestination(engine: engine)

        print("ReportEngineMVPReportTests passed")
    }

    private static func testFilenameAndDestination(engine: ReportEngine) async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let source = root.appendingPathComponent("A/B:Card 01", isDirectory: true)
        let destination = root.appendingPathComponent("Reports", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let createdAt = Date(timeIntervalSince1970: 1_782_604_800)
        let firstURL = await engine.uniqueReportURL(sourceName: source.lastPathComponent, createdAt: createdAt, in: destination)
        try "existing".write(to: firstURL, atomically: true, encoding: .utf8)
        let secondURL = await engine.uniqueReportURL(sourceName: source.lastPathComponent, createdAt: createdAt, in: destination)

        assertNotContains(firstURL.lastPathComponent, ":", "report filename should be sanitized")
        assertNotContains(firstURL.lastPathComponent, " ", "report filename should be sanitized")
        assertNotContains(firstURL.lastPathComponent, "/", "report filename should be sanitized")
        assertNotContains(secondURL.lastPathComponent, firstURL.lastPathComponent, "report filename should be unique")

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

        assertEqual(savedURL.deletingLastPathComponent().path, destination.path, "report should be saved in destination side")
        guard !savedURL.path.hasPrefix(source.path) else {
            fatalError("report must not be saved in source")
        }
    }

    private static func report(
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
