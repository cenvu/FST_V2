// FST / CenVu | (+84) 842 841 222

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
        let infoFlag = ["--", "info"].joined()
        let outbufFlag = ["--", "outbuf"].joined()
        let bwlimitFlag = ["--", "bwlimit="].joined()

        let copyOnly = await engine.generateReportText(
            report: report(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )
        assertContains(copyOnly, "App Name:            FishSockTransfer", "copy-only app name")
        assertContains(copyOnly, "Final Status:        TRANSFER COMPLETE", "copy-only final status")
        assertContains(copyOnly, "Verification Result: OFF - NOT VERIFIED BY FST", "copy-only verification off")
        assertContains(copyOnly, "Copy Duration:       00:00:20", "copy-only copy duration")
        assertContains(copyOnly, "Verify Duration:     N/A", "copy-only verify duration")
        assertContains(copyOnly, "Total Duration:      00:01:40", "copy-only total duration")
        assertContains(copyOnly, copyAverageSpeedLine("50.00 MB/s"), "copy-only copy average speed")
        assertContains(copyOnly, "SAFE TO EJECT DESTINATION: NO", "copy-only must not be safe eject")
        assertContains(copyOnly, "Source Change Detection: NOT AVAILABLE IN V1", "source change detection v1 disclosure")
        assertContains(copyOnly, "Skipped Count:       NOT RECORDED IN V1", "skipped count v1 disclosure")
        assertNotContains(copyOnly, oldTransferDurationLabel(), "copy-only old duration label")
        assertNotContains(copyOnly, oldAverageSpeedLabel(), "copy-only old speed label")
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
        assertContains(verified, "Copy Duration:       00:00:20", "verified copy duration")
        assertContains(verified, "Verify Duration:     00:01:20", "verified verify duration")
        assertContains(verified, "Total Duration:      00:01:40", "verified total duration")
        assertContains(verified, copyAverageSpeedLine("50.00 MB/s"), "verified copy average speed")
        assertContains(verified, "Verification Mode:   xxHash64 Full 100%", "verified mode")
        assertContains(verified, "Hash Algorithm:      xxHash64", "verified hash algorithm")
        assertContains(verified, "Fast non-cryptographic hash verification", "xxHash64 note")
        assertContains(verified, "Verification Result: PASSED", "verified result")
        assertContains(verified, "Verified Files:      10", "verified count")
        assertContains(verified, "Passed Files:        10", "passed count")
        assertContains(verified, "Failed Files:        0", "failed count")
        assertContains(verified, "SAFE TO EJECT DESTINATION: YES", "verified safe eject destination")
        assertContains(verified, "Transfer Engine:     rsync 3.4.4", "minimal rsync engine detail")
        assertContains(verified, "Bandwidth Limit:     120 MB/s", "operator bandwidth display")
        assertNotContains(verified, "Rsync Binary Path:", "operator report must not include rsync path")
        assertNotContains(verified, "Rsync Version:", "operator report must not include old rsync version field")
        assertNotContains(verified, infoFlag, "operator report must not include rsync flags")
        assertNotContains(verified, outbufFlag, "operator report must not include rsync flags")
        assertNotContains(verified, bwlimitFlag, "operator report must not include rsync bwlimit arg")
        assertNotContains(verified, "122880", "operator report must not include internal KiB/s value")
        assertNotContains(verified, formerFormatLabel, "verified report must not use old format wording")

        let timing = await engine.generateReportText(
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
        assertContains(timing, "Copy Duration:       00:00:10", "timing copy duration")
        assertContains(timing, "Verify Duration:     00:01:30", "timing verify duration")
        assertContains(timing, "Total Duration:      00:01:40", "timing total duration")
        assertContains(timing, copyAverageSpeedLine("100.00 MB/s"), "timing copy average speed")
        assertNotContains(timing, copyAverageSpeedLine("10.00 MB/s"), "copy average must not use total duration")
        assertNotContains(timing, oldTransferDurationLabel(), "timing old duration label")
        assertNotContains(timing, oldAverageSpeedLabel(), "timing old speed label")

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
        assertContains(verificationFailed, "SAFE TO EJECT DESTINATION: NO", "verification failure must not be safe eject")
        assertContains(verificationFailed, "Verification Mode:   SHA256 Sample 33%", "verification failure mode")
        assertContains(verificationFailed, "Verification Scope:  RANDOM SAMPLE", "verification failure scope")
        assertContains(verificationFailed, "Hash Algorithm:      SHA256", "verification failure hash algorithm")
        assertContains(verificationFailed, "- MANUAL CHECK REQUIRED: Verification failed.", "verification failure reason")
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
        assertContains(transferFailed, "SAFE TO EJECT DESTINATION: NO", "transfer failure must not be safe eject")
        assertContains(transferFailed, "- TRANSFER ERROR: rsync failed.", "transfer failure reason")
        assertNotContains(transferFailed, "Final Status:        TRANSFER COMPLETE", "transfer failure must not be complete")
        assertNotContains(transferFailed, "Final Status:        SAFE TO EJECT", "transfer failure must not be safe eject")
        assertNotContains(transferFailed, formerFormatLabel, "transfer failure must not use old format wording")

        let invalidSafeEjectFacts = await engine.generateReportText(
            report: report(finalStatus: .safeToFormat, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil
        )
        assertNotContains(invalidSafeEjectFacts, "Final Status:        SAFE TO EJECT", "truthfulness guard must block invalid safe eject")
        assertContains(invalidSafeEjectFacts, "Final Status:        MANUAL CHECK REQUIRED", "truthfulness guard requires manual check")
        assertContains(invalidSafeEjectFacts, "SAFE TO EJECT DESTINATION: NO", "truthfulness guard must not be safe eject")
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
        let jobID = "FST-20260622-053000-1234ABCD"
        let firstURL = await engine.uniqueReportURL(jobID: jobID, in: destination)
        try "existing".write(to: firstURL, atomically: true, encoding: .utf8)
        let secondURL = await engine.uniqueReportURL(jobID: jobID, in: destination)

        assertNotContains(firstURL.lastPathComponent, ":", "report filename should be sanitized")
        assertNotContains(firstURL.lastPathComponent, " ", "report filename should be sanitized")
        assertNotContains(firstURL.lastPathComponent, "/", "report filename should be sanitized")
        assertContains(firstURL.lastPathComponent, jobID, "report filename should use job id")
        assertNotContains(firstURL.lastPathComponent, source.lastPathComponent, "report filename should not use source name")
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
        assertContains(savedURL.lastPathComponent, jobID, "saved report filename should use job id")
        assertNotContains(savedURL.lastPathComponent, source.lastPathComponent, "saved report filename should not use source name")
        guard !savedURL.path.hasPrefix(source.path) else {
            fatalError("report must not be saved in source")
        }
    }

    private static func oldTransferDurationLabel() -> String {
        "\n" + ["Transfer", "Duration:"].joined(separator: " ")
    }

    private static func oldAverageSpeedLabel() -> String {
        "\n" + ["Average", "Speed:"].joined(separator: " ")
    }

    private static func copyAverageSpeedLine(_ value: String) -> String {
        ["Copy", "Average", "Speed:"].joined(separator: " ") + "  \(value)"
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
