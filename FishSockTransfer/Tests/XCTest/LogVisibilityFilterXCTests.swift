import XCTest

/// Tests for LogVisibilityFilter — the diagnostic classification helper.
///
/// Rule: filtering is UI-only.
/// - Diagnostic entries must be hidden from the operator view by default.
/// - Operator-evidence entries must always pass through.
/// - Full log (including diagnostics) must reach the TXT report.
final class LogVisibilityFilterXCTests: XCTestCase {

    // MARK: - Diagnostic: should be hidden by default

    func testDiagRsyncRawIsHidden() {
        XCTAssertTrue(isDiag("DIAG [RSYNC RAW] some raw rsync line"))
    }

    func testDiagRsyncTimingIsHidden() {
        XCTAssertTrue(isDiag("DIAG [RSYNC TIMING] parsed timing value"))
    }

    func testDiagCoordinatorIsHidden() {
        XCTAssertTrue(isDiag("DIAG [COORDINATOR] First progress forwarded: 1.0% at +2s"))
    }

    func testDiagViewModelIsHidden() {
        XCTAssertTrue(isDiag("DIAG [VIEWMODEL] First speed applied: 45.20 MB/s"))
    }

    func testVerifyDiagIsHidden() {
        XCTAssertTrue(isDiag("VERIFY [VERIFY DIAG] chunk comparison detail"))
    }

    func testHashSourcePathIsHidden() {
        XCTAssertTrue(isDiag("Hash source path: /Volumes/CARD/clip.mxf"))
    }

    func testHashDestinationPathIsHidden() {
        XCTAssertTrue(isDiag("Hash destination path: /Volumes/RAID/CARD/clip.mxf"))
    }

    func testHashGeneratedSourceIsHidden() {
        XCTAssertTrue(isDiag("Hash generated: Source sha256=abcdef1234567890"))
    }

    func testHashGeneratedDestinationIsHidden() {
        XCTAssertTrue(isDiag("Hash generated: Destination sha256=abcdef1234567890"))
    }

    // MARK: - Operator-facing: must always be visible

    func testStartingTransferWorkflowIsVisible() {
        XCTAssertFalse(isDiag("Starting transfer workflow"))
    }

    func testPreparingTransferIsVisible() {
        XCTAssertFalse(isDiag("Preparing transfer..."))
    }

    func testScanningSourceIsVisible() {
        XCTAssertFalse(isDiag("Scanning source and checking destination..."))
    }

    func testValidatingTransferIsVisible() {
        XCTAssertFalse(isDiag("Validating transfer requirements..."))
    }

    func testTransferStartedIsVisible() {
        XCTAssertFalse(isDiag("Transfer Started"))
    }

    func testTransferCompletedIsVisible() {
        XCTAssertFalse(isDiag("Transfer Completed"))
    }

    func testVerificationStartedIsVisible() {
        XCTAssertFalse(isDiag("Verification Started"))
    }

    func testVerificationCompletedIsVisible() {
        XCTAssertFalse(isDiag("Verification Completed"))
    }

    func testSafeToEjectIsVisible() {
        XCTAssertFalse(isDiag("Verification Passed. SAFE TO EJECT."))
    }

    func testReportSavedIsVisible() {
        XCTAssertFalse(isDiag("Report saved: /Volumes/RAID/FST_Report_CARD_20260630.txt"))
    }

    func testBundledRsyncPathIsVisible() {
        XCTAssertFalse(isDiag("Bundled rsync path: /Applications/FST.app/Contents/Resources/rsync"))
    }

    func testBundledRsyncVersionIsVisible() {
        XCTAssertFalse(isDiag("Bundled rsync version: 3.4.4"))
    }

    func testRsyncArgsIsVisible() {
        XCTAssertFalse(isDiag("Rsync Args: -a -h --info=progress2"))
    }

    func testRsyncCommandIsVisible() {
        XCTAssertFalse(isDiag("Rsync Command: /path/to/rsync -a -h --info=progress2 /src /dst"))
    }

    func testErrorIsVisible() {
        XCTAssertFalse(isDiag("TRANSFER ERROR: rsync exited with code 11"))
    }

    func testWarningIsVisible() {
        XCTAssertFalse(isDiag("WARNING: low destination space"))
    }

    func testManualCheckRequiredIsVisible() {
        XCTAssertFalse(isDiag("MANUAL CHECK REQUIRED: Verification failed."))
    }

    // MARK: - operatorVisible() array filtering

    func testOperatorVisibleFiltersOutDiagnostics() {
        let logs: [LogEntry] = [
            LogEntry(category: .info, message: "Starting transfer workflow"),
            LogEntry(category: .progress, message: "DIAG [COORDINATOR] First progress forwarded: 1.0% at +1s"),
            LogEntry(category: .verify, message: "Verification Passed. SAFE TO EJECT."),
            LogEntry(category: .verify, message: "Hash source path: /Volumes/CARD/A.mxf"),
            LogEntry(category: .error, message: "TRANSFER ERROR: rsync failed"),
        ]

        let visible = LogVisibilityFilter.operatorVisible(from: logs)

        XCTAssertEqual(visible.count, 3)
        XCTAssertTrue(visible.contains(where: { $0.message == "Starting transfer workflow" }))
        XCTAssertTrue(visible.contains(where: { $0.message == "Verification Passed. SAFE TO EJECT." }))
        XCTAssertTrue(visible.contains(where: { $0.message == "TRANSFER ERROR: rsync failed" }))
        XCTAssertFalse(visible.contains(where: { $0.message.contains("DIAG [") }))
        XCTAssertFalse(visible.contains(where: { $0.message.hasPrefix("Hash source path:") }))
    }

    func testOperatorVisibleDoesNotMutateOriginalArray() {
        let original: [LogEntry] = [
            LogEntry(category: .progress, message: "DIAG [VIEWMODEL] First speed applied: 45.20 MB/s"),
            LogEntry(category: .info, message: "Transfer Started"),
        ]
        _ = LogVisibilityFilter.operatorVisible(from: original)
        XCTAssertEqual(original.count, 2, "Source array must not be mutated by filtering")
    }

    // MARK: - Report must include DIAG entries

    func testReportIncludesFullLogWithDiagnostics() async {
        let engine = ReportEngine()
        let logs: [LogEntry] = [
            LogEntry(category: .info, message: "Starting transfer workflow"),
            LogEntry(category: .progress, message: "DIAG [COORDINATOR] First progress forwarded: 1.0% at +1s"),
            LogEntry(category: .verify, message: "VERIFY [VERIFY DIAG] chunk detail"),
            LogEntry(category: .verify, message: "Hash source path: /Volumes/CARD/A.mxf"),
            LogEntry(category: .verify, message: "Hash generated: Source sha256=abc123"),
            LogEntry(category: .system, message: "Verification Passed. SAFE TO EJECT."),
        ]

        let text = await engine.generateReportText(
            report: minimalReport(finalStatus: .safeToFormat, mode: .full, verificationStatus: .passed),
            bandwidthLimit: nil,
            logs: logs
        )

        XCTAssertTrue(text.contains("FULL TECHNICAL LOG"), "Report must include FULL TECHNICAL LOG section header")
        XCTAssertTrue(text.contains("DIAG [COORDINATOR]"), "Report must include DIAG [COORDINATOR] entries")
        XCTAssertTrue(text.contains("VERIFY [VERIFY DIAG]"), "Report must include VERIFY [VERIFY DIAG] entries")
        XCTAssertTrue(text.contains("Hash source path:"), "Report must include Hash source path entries")
        XCTAssertTrue(text.contains("Hash generated: Source"), "Report must include Hash generated entries")
        XCTAssertTrue(text.contains("Starting transfer workflow"), "Report must include operator entries")
        XCTAssertTrue(text.contains("Verification Passed. SAFE TO EJECT."), "Report must include safe eject evidence line")
    }

    func testReportWithNoLogsHasNoFullTechnicalLogSection() async {
        let engine = ReportEngine()
        let text = await engine.generateReportText(
            report: minimalReport(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil,
            logs: []
        )
        XCTAssertFalse(text.contains("FULL TECHNICAL LOG"), "Empty log array must not produce a log section")
    }

    func testReportDoesNotContainSafeToFormat() async {
        let engine = ReportEngine()
        let text = await engine.generateReportText(
            report: minimalReport(finalStatus: .safeToFormat, mode: .full, verificationStatus: .passed),
            bandwidthLimit: nil,
            logs: []
        )
        let forbidden = ["SAFE", "TO", "FORMAT"].joined(separator: " ")
        XCTAssertFalse(text.contains(forbidden), "Report must not contain 'SAFE TO FORMAT'")
    }

    // MARK: - Source-of-truth fix: DIAG [VIEWMODEL] in report

    /// Report FULL TECHNICAL LOG must include DIAG [VIEWMODEL] entries.
    /// These exist only in viewModel.logs, not in LoggerService.allLogs().
    func testReportIncludesDiagViewModelWhenFullSnapshotPassed() async {
        let engine = ReportEngine()
        // Simulate the full viewModel.logs snapshot (coordinator entries + viewmodel entries)
        let fullViewModelLogs: [LogEntry] = [
            LogEntry(category: .info, message: "Starting transfer workflow"),
            LogEntry(category: .progress, message: "DIAG [COORDINATOR] First progress forwarded: 1.0% at +1s"),
            LogEntry(category: .progress, message: "DIAG [VIEWMODEL] First progress applied: 1.0%"),
            LogEntry(category: .progress, message: "DIAG [VIEWMODEL] First speed applied: 45.20 MB/s"),
            LogEntry(category: .progress, message: "DIAG [VIEWMODEL] First rsync time applied: 00:32"),
            LogEntry(category: .success, message: "Transfer Completed"),
        ]

        let text = await engine.generateReportText(
            report: minimalReport(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil,
            logs: fullViewModelLogs
        )

        XCTAssertTrue(text.contains("FULL TECHNICAL LOG"), "Report must include FULL TECHNICAL LOG header")
        XCTAssertTrue(text.contains("DIAG [VIEWMODEL] First progress applied"), "Report must include DIAG [VIEWMODEL] progress entry")
        XCTAssertTrue(text.contains("DIAG [VIEWMODEL] First speed applied"), "Report must include DIAG [VIEWMODEL] speed entry")
        XCTAssertTrue(text.contains("DIAG [VIEWMODEL] First rsync time applied"), "Report must include DIAG [VIEWMODEL] time entry")
        XCTAssertTrue(text.contains("DIAG [COORDINATOR]"), "Report must include DIAG [COORDINATOR] entry")
        XCTAssertTrue(text.contains("Starting transfer workflow"), "Report must include operator entries")
    }

    /// If only filtered (operator-visible) logs were passed to the report,
    /// DIAG [VIEWMODEL] entries would be absent. This proves the fix is necessary.
    func testFilteredLogsWouldMissDiagViewModelEntries() async {
        let engine = ReportEngine()
        let fullViewModelLogs: [LogEntry] = [
            LogEntry(category: .info, message: "Starting transfer workflow"),
            LogEntry(category: .progress, message: "DIAG [VIEWMODEL] First speed applied: 45.20 MB/s"),
            LogEntry(category: .success, message: "Transfer Completed"),
        ]

        // Filtered (what UI shows by default — would be wrong to pass to report)
        let filteredLogs = LogVisibilityFilter.operatorVisible(from: fullViewModelLogs)
        let textWithFiltered = await engine.generateReportText(
            report: minimalReport(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil,
            logs: filteredLogs
        )

        // Full (what should go to report)
        let textWithFull = await engine.generateReportText(
            report: minimalReport(finalStatus: .copyComplete, mode: .none, verificationStatus: nil),
            bandwidthLimit: nil,
            logs: fullViewModelLogs
        )

        XCTAssertFalse(textWithFiltered.contains("DIAG [VIEWMODEL]"), "Filtered logs must NOT contain DIAG [VIEWMODEL] — confirms filtering removes it")
        XCTAssertTrue(textWithFull.contains("DIAG [VIEWMODEL]"), "Full logs MUST contain DIAG [VIEWMODEL] — confirms report source-of-truth fix is required")
    }

    /// UI default view (filtered) must hide DIAG [VIEWMODEL].
    func testUiDefaultViewHidesDiagViewModel() {
        let fullLogs: [LogEntry] = [
            LogEntry(category: .info, message: "Transfer Started"),
            LogEntry(category: .progress, message: "DIAG [VIEWMODEL] First progress applied: 1.0%"),
            LogEntry(category: .progress, message: "DIAG [VIEWMODEL] First speed applied: 45.20 MB/s"),
            LogEntry(category: .success, message: "Transfer Completed"),
        ]

        let visible = LogVisibilityFilter.operatorVisible(from: fullLogs)

        XCTAssertEqual(visible.count, 2, "Default UI view should show only operator-facing entries")
        XCTAssertFalse(visible.contains(where: { $0.message.contains("DIAG [VIEWMODEL]") }), "DIAG [VIEWMODEL] must be hidden in default UI view")
        XCTAssertTrue(visible.contains(where: { $0.message == "Transfer Started" }))
        XCTAssertTrue(visible.contains(where: { $0.message == "Transfer Completed" }))
    }

    /// With Show Diagnostics on (full logs passed), DIAG [VIEWMODEL] must be present.
    func testShowDiagnosticsIncludesDiagViewModel() {
        let fullLogs: [LogEntry] = [
            LogEntry(category: .info, message: "Transfer Started"),
            LogEntry(category: .progress, message: "DIAG [VIEWMODEL] First speed applied: 45.20 MB/s"),
            LogEntry(category: .success, message: "Transfer Completed"),
        ]

        // Show Diagnostics = true → pass full logs (no filter applied)
        XCTAssertTrue(fullLogs.contains(where: { $0.message.contains("DIAG [VIEWMODEL]") }), "Full logs must include DIAG [VIEWMODEL] for Show Diagnostics mode")
        XCTAssertEqual(fullLogs.count, 3, "Full logs must not lose any entries")
    }

    // MARK: - Helpers

    private func isDiag(_ message: String) -> Bool {
        LogVisibilityFilter.isDiagnostic(message)
    }

    private func minimalReport(
        finalStatus: TransferState,
        mode: VerificationMode,
        verificationStatus: VerificationStatus?
    ) -> TransferReport {
        TransferReport(
            date: "2026-06-30",
            time: "02:00:00",
            sourcePath: "/Volumes/CARD",
            destinationPath: "/Volumes/RAID/CARD",
            totalSize: 1_048_576,
            fileCount: 1,
            copyDuration: 10,
            verificationDuration: mode == .none ? nil : 50,
            totalDuration: 60,
            copyAverageSpeed: 100,
            verificationMode: mode,
            verificationResult: verificationStatus,
            errorCount: finalStatus == .error ? 1 : 0,
            finalStatus: finalStatus
        )
    }
}
