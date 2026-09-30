// FST / CenVu | (+84) 842 841 222

import Foundation

private func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

private func assertNotEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual != expected else {
        fatalError("\(message): expected value different from \(expected)")
    }
}

private func assertFalse(_ condition: Bool, _ message: String) {
    guard !condition else {
        fatalError(message)
    }
}

private func assertTrue(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError(message)
    }
}

private func assertNil<T>(_ value: T?, _ message: String) {
    guard value == nil else {
        fatalError(message)
    }
}

@main
struct TransferControlsLabelTests {
    static func main() async throws {
        try await MainActor.run {
            try testBandwidthPickerUsesMegabytesPerSecond()
        }
        if CommandLine.arguments.contains("--bandwidth-only") {
            print("TransferControlsLabelTests bandwidth regression passed")
            return
        }
        testActionPresentation()
        testActiveStateAndActionSeparation()
        testTerminalStateAndActionSeparation()
        testPhaseMetricContract()
        testDistinctCopySpeedValues()
        testCinemaDNGSuppression()
        try await MainActor.run {
            try testViewModelStartGateAndSelectionLock()
            testTechnicalLogCallback()
        }

        print("TransferControlsLabelTests passed")
    }

    @MainActor
    private static func testBandwidthPickerUsesMegabytesPerSecond() throws {
        let viewModel = TransferViewModel(bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil))
        viewModel.sourceURL = URL(fileURLWithPath: "/test/source")
        viewModel.destinationURL = URL(fileURLWithPath: "/test/destination")
        viewModel.bundledRsyncInfo = BundledRsyncInfo(
            executableURL: URL(fileURLWithPath: "/test/rsync"), version: "3.4.4", diagnostics: []
        )
        // Read the actual private table used by Picker/ForEach without adding a production test API.
        let view = TransferControlsView(viewModel: viewModel)
        guard let options = Mirror(reflecting: view).children.first(where: { $0.label == "bandwidthOptions" })?.value
            as? [(label: String, value: Int?)] else {
            fatalError("Cannot inspect the production bandwidth Picker options")
        }
        let sequence: [(label: String, megabytesPerSecond: Int?, kibPerSecond: Int?)] = [
            ("Unlimited", nil, nil), ("50 MB/s", 50, 51_200),
            ("75 MB/s", 75, 76_800), ("100 MB/s", 100, 102_400),
            ("125 MB/s", 125, 128_000), ("150 MB/s", 150, 153_600),
            ("175 MB/s", 175, 179_200), ("200 MB/s", 200, 204_800), ("Unlimited", nil, nil)
        ]
        assertEqual(options.count, 8, "bandwidth option count")
        assertEqual(options.map(\.label), ["50 MB/s", "75 MB/s", "100 MB/s", "125 MB/s", "150 MB/s", "175 MB/s", "200 MB/s", "Unlimited"], "actual Picker labels")
        assertEqual(options.map(\.value), [50, 75, 100, 125, 150, 175, 200, nil], "actual Picker MB/s values")
        for step in sequence {
            guard let option = options.first(where: { $0.label == step.label }) else {
                fatalError("Missing bandwidth option: \(step.label)")
            }
            assertEqual(option.value, step.megabytesPerSecond, "Picker \(step.label) must bind MB/s")
            viewModel.bandwidthLimit = option.value
            assertTrue(viewModel.canStartTransfer, "Picker \(step.label) must not trap or block Start")
            assertNil(viewModel.startBlockedReason, "Picker \(step.label) validation")
            let converted = try option.value.map {
                try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: Double($0))
            }
            assertEqual(converted, step.kibPerSecond, "Picker \(step.label) conversion")
        }
    }

    private static func testActionPresentation() {
        let sourceURL = URL(fileURLWithPath: "/Volumes/CARD_A", isDirectory: true)
        let destinationURL = URL(fileURLWithPath: "/Volumes/BACKUP_01", isDirectory: true)

        assertEqual(
            TransferDestinationPreview.message(source: sourceURL, destination: destinationURL),
            "Will create: BACKUP_01/CARD_A",
            "destination target preview"
        )
        assertNil(
            TransferDestinationPreview.message(source: nil, destination: destinationURL),
            "missing source must not render target preview"
        )
        assertNil(
            TransferDestinationPreview.message(source: sourceURL, destination: nil),
            "missing destination must not render target preview"
        )

        assertEqual(
            VerificationMode.none.operatorDescription,
            "Copy only. No hash verification by FST.",
            "none verification description"
        )
        assertTrue(
            VerificationMode.none.operatorDescription.localizedCaseInsensitiveContains("No hash verification"),
            "none description must not imply verification"
        )
        assertEqual(
            VerificationMode.random33.operatorDescription,
            "SHA256 sample verification. Approximately 33% coverage.",
            "random33 verification description"
        )
        assertTrue(
            VerificationMode.random33.operatorDescription.localizedCaseInsensitiveContains("SHA256"),
            "random33 description must disclose SHA256"
        )
        assertEqual(
            VerificationMode.full.operatorDescription,
            "xxHash64 full verification. Fast, non-cryptographic.",
            "full verification description"
        )
        assertTrue(
            VerificationMode.full.operatorDescription.localizedCaseInsensitiveContains("non-cryptographic"),
            "full description must disclose xxHash64 is non-cryptographic"
        )
        assertEqual(VerificationMode.none.selectionLabel, "COPY ONLY — Fastest", "copy-only picker label")
        assertEqual(VerificationMode.random33.selectionLabel, "SAMPLE 33% — Balanced", "random33 picker label")
        assertEqual(VerificationMode.full.selectionLabel, "FULL 100% — Maximum confidence", "full picker label")
        assertEqual(VerificationMode.random33.operatorLabel, "SHA256 Sample 33%", "random33 technical label")
        assertEqual(VerificationMode.full.operatorLabel, "xxHash64 Full 100%", "full technical label")

        assertEqual(
            TransferReportStatusPresentation.message(forLogMessage: "Report saved: /tmp/FST_Report.txt"),
            "Report saved: /tmp/FST_Report.txt",
            "report saved status"
        )
        assertEqual(
            TransferReportStatusPresentation.message(forLogMessage: "Report skipped: no report was written because the destination was unsafe for report output."),
            "Report skipped: no report was written because the destination was unsafe for report output.",
            "report skipped status"
        )
        assertEqual(
            TransferReportStatusPresentation.message(forLogMessage: "Report write failed: Disk full."),
            "Report warning: Disk full.",
            "report warning status"
        )
        assertNotEqual(
            TransferReportStatusPresentation.message(forLogMessage: "Report skipped: no report was written because the destination was unsafe for report output."),
            "Report saved: unsafe destination for report",
            "report skipped must not imply saved success"
        )
        assertTrue(
            TransferReportStatusPresentation.message(forLogMessage: "Report skipped: no report was written because the destination was unsafe for report output.")?.contains("no report was written") == true,
            "report skipped must say no report was written"
        )

        assertEqual(
            TransferControlsActionPresentation.title(for: .ready),
            "START TRANSFER",
            "ready action label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .copying),
            "CANCEL",
            "copying action label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .validating),
            "PREPARING TRANSFER",
            "validating preparation label"
        )
        assertNotEqual(
            TransferControlsActionPresentation.title(for: .validating),
            "TRANSFERRING",
            "validating must not display transferring label before rsync starts"
        )
        assertEqual(
            TransferControlsActionPresentation.subtitle(for: .validating),
            "Scanning source and checking destination...",
            "validating preparation subtitle"
        )
        assertEqual(
            TransferControlsActionPresentation.visualRole(for: .validating),
            .preparing,
            "validating preparation visual role"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .verifying),
            "CANCEL",
            "verifying action label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .copyComplete),
            "TRANSFER COMPLETE",
            "copyComplete copy-only label"
        )
        assertNotEqual(
            TransferControlsActionPresentation.title(for: .copyComplete),
            "SAFE TO EJECT",
            "copyComplete must not display safe-to-eject label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .safeToFormat),
            "SAFE TO EJECT",
            "safeToFormat label"
        )
        let formerFormatLabel = ["SAFE", "TO", "FORMAT"].joined(separator: " ")
        for state in [TransferState.ready, .validating, .copying, .verifying, .copyComplete, .safeToFormat, .error, .cancelled] {
            assertNotEqual(
                TransferControlsActionPresentation.title(for: state),
                formerFormatLabel,
                "state \(state.rawValue) must not display old format wording"
            )
        }
        assertEqual(
            TransferControlsActionPresentation.title(for: .error),
            "TRANSFER ERROR",
            "transfer error label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(
                for: .error,
                errorMessage: "MANUAL CHECK REQUIRED: Verification failed."
            ),
            "MANUAL CHECK REQUIRED",
            "verification failure label"
        )
        assertEqual(
            TransferControlsActionPresentation.visualRole(
                for: .error,
                errorMessage: "MANUAL CHECK REQUIRED: Verification failed."
            ),
            .manualCheckRequired,
            "manual check visual role"
        )
        assertNotEqual(
            TransferControlsActionPresentation.visualRole(
                for: .error,
                errorMessage: "MANUAL CHECK REQUIRED: Verification failed."
            ),
            TransferControlsActionPresentation.visualRole(for: .error),
            "manual check role must differ from transfer error role"
        )
        assertNotEqual(
            TransferControlsActionPresentation.icon(
                for: .error,
                errorMessage: "MANUAL CHECK REQUIRED: Verification failed."
            ),
            TransferControlsActionPresentation.icon(for: .error),
            "manual check icon must differ from transfer error icon"
        )
        assertEqual(
            TransferControlsActionPresentation.icon(for: .copyComplete),
            "doc.on.doc",
            "copyComplete copy-only icon"
        )
        assertNotEqual(
            TransferControlsActionPresentation.icon(for: .copyComplete),
            TransferControlsActionPresentation.icon(for: .safeToFormat),
            "copyComplete icon must differ from safeToFormat icon"
        )
        assertNotEqual(
            TransferControlsActionPresentation.icon(for: .copyComplete),
            "checkmark.circle.fill",
            "copyComplete must not use safe checkmark icon"
        )
        assertEqual(
            TransferControlsActionPresentation.icon(for: .safeToFormat),
            "checkmark.circle.fill",
            "safeToFormat safe checkmark icon"
        )
        assertEqual(
            TransferControlsActionPresentation.visualRole(for: .copyComplete),
            .copyOnlyComplete,
            "copyComplete visual role"
        )
        assertEqual(
            TransferControlsActionPresentation.visualRole(for: .safeToFormat),
            .safeToFormat,
            "safeToFormat visual role"
        )
        assertNotEqual(
            TransferControlsActionPresentation.visualRole(for: .copyComplete),
            TransferControlsActionPresentation.visualRole(for: .safeToFormat),
            "copyComplete button color role must differ from safeToFormat"
        )
        assertEqual(
            TransferState.copyComplete.statusVisualRole,
            .copyOnlyComplete,
            "copyComplete status color role"
        )
        assertEqual(
            TransferState.safeToFormat.statusVisualRole,
            .safeToFormat,
            "safeToFormat status color role"
        )
        assertNotEqual(
            TransferState.copyComplete.statusVisualRole,
            TransferState.safeToFormat.statusVisualRole,
            "copyComplete status color role must differ from safeToFormat"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .error),
            "TRANSFER ERROR",
            "default error label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .cancelled),
            "CANCELLED",
            "cancelled label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .cancelled, canStartTransfer: true),
            "START NEW TRANSFER",
            "cancelled restart action label"
        )

        assertEqual(
            TransferControlsActionPresentation.visualRole(for: .cancelled),
            .cancelled,
            "cancelled visual role"
        )
        assertNotEqual(
            TransferControlsActionPresentation.visualRole(for: .cancelled),
            TransferControlsActionPresentation.visualRole(for: .safeToFormat),
            "cancelled role must not look safe"
        )
        assertNotEqual(
            TransferControlsActionPresentation.icon(for: .cancelled),
            TransferControlsActionPresentation.icon(for: .safeToFormat),
            "cancelled icon must not look safe"
        )
        assertNotEqual(
            TransferControlsActionPresentation.title(for: .cancelled),
            "SAFE TO EJECT",
            "cancelled must not display safe-to-eject label"
        )
    }

    private static func testActiveStateAndActionSeparation() {
        let states: [(TransferState, String, String, TransferControlsVisualRole)] = [
            (.ready, "READY", "START TRANSFER", .idle),
            (.validating, "PREPARING", "PREPARING TRANSFER", .preparing),
            (.copying, "COPYING", "CANCEL", .transferring),
            (.verifying, "VERIFYING", "CANCEL", .verifying)
        ]
        for (state, phase, action, role) in states {
            assertEqual(TransferControlsActionPresentation.stateTitle(for: state, canStartTransfer: true), phase, "state identity")
            assertEqual(TransferControlsActionPresentation.title(for: state), action, "operator action")
            assertEqual(TransferControlsActionPresentation.visualRole(for: state), role, "active visual role")
            for label in [phase, action, TransferControlsActionPresentation.stateSubtitle(for: state, canStartTransfer: true)] {
                assertFalse(label.contains("SAFE TO EJECT"), "active state must not imply verified success")
            }
            assertNotEqual(role, .safeToFormat, "active state must not use success role")
            assertNotEqual(TransferControlsActionPresentation.stateIcon(for: state), "checkmark.circle.fill", "active phase must not use verified-success icon")
        }
        assertEqual(TransferControlsActionPresentation.stateSubtitle(for: .ready, canStartTransfer: true), "Ready to transfer", "ready message")
        assertEqual(TransferControlsActionPresentation.stateTitle(for: .ready), "SETUP REQUIRED", "blocked setup must not pretend ready")
        assertEqual(TransferControlsActionPresentation.stateSubtitle(for: .ready, startBlockedReason: "Select a source folder."), "Select a source folder.", "backend start-blocked reason")
        assertEqual(TransferControlsActionPresentation.stateSubtitle(for: .validating), "Scanning source and checking destination...", "preparation fallback")
        assertEqual(TransferControlsActionPresentation.stateSubtitle(for: .validating, workflowPhaseTitle: "Scanning source", workflowPhaseMessage: "Building inventory"), "Scanning source — Building inventory", "truthful backend phase detail")
        assertEqual(TransferControlsActionPresentation.stateSubtitle(for: .copying), "Copy in progress. Do not remove media.", "copy message")
        assertEqual(TransferControlsActionPresentation.stateSubtitle(for: .verifying), "Verification in progress. Do not remove media.", "verify message")
        assertFalse(TransferActionPresentation.isEnabled(for: .validating, canStartTransfer: true), "preparing has no action even with a stale start flag")

        var guardState = TransferCancelRequestGuard()
        var requests = 0
        for state in [TransferState.copying, .verifying] {
            if guardState.allowsNewCancellationRequest(for: state) {
                guardState.confirmCancellationRequest()
                requests += 1
            }
            assertFalse(TransferActionPresentation.isEnabled(for: state, canStartTransfer: false, isCancellationRequested: guardState.isCancellationRequested), "confirmed Cancel disables button across active phases")
        }
        assertEqual(requests, 1, "one confirmed cancellation per workflow")
        for state in [TransferState.ready, .validating, .copyComplete, .safeToFormat, .error, .cancelled] {
            guardState.confirmCancellationRequest()
            guardState.reset(for: state)
            assertFalse(guardState.isCancellationRequested, "leaving active phases resets guard")
            assertFalse(guardState.allowsNewCancellationRequest(for: state), "no cancellation outside copying/verifying")
            assertTrue(guardState.allowsNewCancellationRequest(for: .copying), "next workflow can cancel")
        }
    }

    private static func testTerminalStateAndActionSeparation() {
        let cases: [(TransferState, String?, String, String, TransferControlsVisualRole, String)] = [
            (.copyComplete, nil, "TRANSFER COMPLETE", "Copy completed. Verification was disabled.", .copyOnlyComplete, "START NEW TRANSFER"),
            (.safeToFormat, nil, "SAFE TO EJECT", "Verification completed successfully.", .safeToFormat, "START NEW TRANSFER"),
            (.error, "MANUAL CHECK REQUIRED: File mismatch.", "MANUAL CHECK REQUIRED", "File mismatch.", .manualCheckRequired, "RETRY"),
            (.error, "The destination location is unavailable or cannot be written.", "TRANSFER ERROR", "The destination location is unavailable or cannot be written.", .error, "RETRY"),
            (.cancelled, nil, "CANCELLED", "Transfer was cancelled.", .cancelled, "START NEW TRANSFER")
        ]
        for (state, error, outcome, message, role, action) in cases {
            for canStart in [false, true] {
                assertEqual(TransferControlsActionPresentation.stateTitle(for: state, canStartTransfer: canStart, errorMessage: error), outcome, "terminal outcome independent of admission")
                assertEqual(TransferControlsActionPresentation.stateSubtitle(for: state, canStartTransfer: canStart, errorMessage: error), message, "terminal evidence independent of admission")
                assertEqual(TransferControlsActionPresentation.visualRole(for: state, errorMessage: error), role, "terminal role")
                assertEqual(TransferActionPresentation.terminalActionTitle(for: state, canStartTransfer: canStart), canStart ? action : nil, "only admissible explicit terminal actions")
                if canStart {
                    assertEqual(TransferControlsActionPresentation.title(for: state, errorMessage: error, canStartTransfer: true), action, "action title cannot be a hidden outcome")
                    assertNotEqual(action, outcome, "state and action differ")
                }
            }
            if state != .safeToFormat {
                assertNotEqual(role, .safeToFormat, "unverified or failed/cancelled outcome cannot be success")
                assertFalse(message.contains("SAFE TO EJECT"), "message cannot overstate safety")
                assertNotEqual(TransferControlsActionPresentation.stateIcon(for: state, errorMessage: error), "checkmark.circle.fill", "only verified success uses safe icon")
            }
        }
        assertEqual(TransferControlsActionPresentation.stateIcon(for: .safeToFormat), "checkmark.circle.fill", "verified-success icon")
        assertNotEqual(TransferControlsActionPresentation.stateIcon(for: .error, errorMessage: "MANUAL CHECK REQUIRED: File mismatch."), TransferControlsActionPresentation.stateIcon(for: .error), "warning and generic error icons distinct")

        let raw = "MANUAL CHECK REQUIRED: File mismatch.\nsource=A001.mov\ndestination checksum differs"
        assertEqual(TransferControlsActionPresentation.stateSubtitle(for: .error, errorMessage: raw), "File mismatch.", "operator summary from real first line")
        assertEqual(TransferControlsActionPresentation.terminalErrorDetail(for: .error, errorMessage: raw), "source=A001.mov\ndestination checksum differs", "remaining diagnostic lines preserved without repeated summary")
        assertNil(TransferControlsActionPresentation.terminalErrorDetail(for: .error, errorMessage: "Transfer process exited with error code 23."), "single-line truth already shown; log provides diagnostics")
        assertNil(TransferControlsActionPresentation.terminalErrorDetail(for: .safeToFormat, errorMessage: raw), "stale error does not contaminate verified outcome")
        assertNil(TransferControlsActionPresentation.visibleStartBlockedReason(for: .error, reason: raw, errorMessage: raw), "error must not repeat as a start blocker")
        assertEqual(TransferControlsActionPresentation.visibleStartBlockedReason(for: .error, reason: "Select a destination folder.", errorMessage: raw), "Select a destination folder.", "different genuine setup blocker remains visible")
        assertEqual(TransferControlsActionPresentation.visibleStartBlockedReason(for: .ready, reason: raw, errorMessage: raw), raw, "active blocking evidence remains unchanged")
        for state in [TransferState.ready, .validating, .copying, .verifying] {
            assertNil(TransferActionPresentation.terminalActionTitle(for: state, canStartTransfer: true), "no terminal action in active states")
            assertFalse(TransferControlsActionPresentation.stateTitle(for: state, canStartTransfer: true, errorMessage: raw).contains("SAFE TO EJECT"), "active state must not render safe banner from stale error")
            assertFalse(TransferControlsActionPresentation.stateSubtitle(for: state, canStartTransfer: true).contains("SAFE TO EJECT: NO"), "no active false-negative safety banner")
        }
    }

    private static func testPhaseMetricContract() {
        let copy = TransferRuntimeMetricPresentation.heroTitles(for: .copying)
        assertEqual(copy?.progress, "COPY PROGRESS", "copy progress hero")
        assertEqual(copy?.eta, "COPY ETA", "copy ETA hero")
        assertEqual(copy?.third, "CURRENT COPY SPEED", "copy speed hero")
        assertEqual(TransferRuntimeMetricPresentation.averageCopySpeedTitle(for: .copying), "AVERAGE COPY SPEED", "secondary average title")
        assertNotEqual(copy?.third, TransferRuntimeMetricPresentation.averageCopySpeedTitle(for: .copying), "current and average speed are distinct concepts")

        let verify = TransferRuntimeMetricPresentation.heroTitles(for: .verifying)
        assertEqual(verify?.progress, "VERIFY PROGRESS", "verify progress hero")
        assertEqual(verify?.eta, "VERIFY ETA", "verify ETA hero")
        assertEqual(verify?.third, "VERIFY ELAPSED", "verify third hero")
        assertFalse([verify?.progress, verify?.eta, verify?.third].contains("CURRENT COPY SPEED"), "verify has no copy speed")
        assertNil(TransferRuntimeMetricPresentation.averageCopySpeedTitle(for: .verifying), "verify has no average copy speed")

        for state in [TransferState.ready, .validating, .copyComplete, .safeToFormat, .error, .cancelled] {
            assertNil(TransferRuntimeMetricPresentation.heroTitles(for: state), "\(state.rawValue) has no active hero or phase bar")
            assertNil(TransferRuntimeMetricPresentation.averageCopySpeedTitle(for: state), "\(state.rawValue) has no active average")
        }
    }

    private static func testDistinctCopySpeedValues() {
        let snapshot = CopyRuntimeSnapshot(
            elapsedSeconds: 20, currentItem: "clip.mov", copiedBytes: 100, totalBytes: 200,
            copiedFiles: 1, totalFiles: 2, progressFraction: 0.5,
            currentSpeedBytesPerSecond: 12 * 1_048_576,
            averageSpeedBytesPerSecond: 6 * 1_048_576,
            etaSeconds: 10, signalSource: .destinationObserver, lastObservedAt: Date(),
            activityState: .observingDestination
        )
        let current = TransferRuntimeMetricPresentation.speedValue(bytesPerSecond: snapshot.currentSpeedBytesPerSecond)
        let average = TransferRuntimeMetricPresentation.averageCopySpeedValue(snapshot: snapshot)
        assertEqual(current, "12.00 MB/s", "current uses existing formatter")
        assertEqual(average, "6.00 MB/s", "average reads snapshot average using existing formatter")
        assertNotEqual(current, average, "current and average can display distinct values")
        assertEqual(TransferRuntimeMetricPresentation.averageCopySpeedValue(snapshot: nil), "-", "unknown average stays unavailable")
        assertEqual(TransferRuntimeMetricPresentation.speedValue(bytesPerSecond: nil), "-", "unknown speed")
        assertEqual(TransferRuntimeMetricPresentation.speedValue(bytesPerSecond: 0), "-", "zero speed")
    }

    private static func testCinemaDNGSuppression() {
        let normalFile = "A001_C001_010101.mov"
        let dngFile1 = "A001_C001_010101_00000.dng"
        let dngFile2 = "A001_C001_010101_00001.DNG"

        assertEqual(
            TransferRuntimeMetricPresentation.currentFileValue(currentFile: normalFile, state: .copying),
            normalFile,
            "Normal files should display their name"
        )

        assertEqual(
            TransferRuntimeMetricPresentation.currentFileValue(currentFile: dngFile1, state: .copying),
            "Processing CinemaDNG frame sequence...",
            "Lowercase .dng should be suppressed"
        )

        assertEqual(
            TransferRuntimeMetricPresentation.currentFileValue(currentFile: dngFile2, state: .copying),
            "Processing CinemaDNG frame sequence...",
            "Uppercase .DNG should be suppressed"
        )
    }

    @MainActor
    private static func testTechnicalLogCallback() {
        let viewModel = TransferViewModel(bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil))
        var navigations = 0
        let view = TransferControlsView(viewModel: viewModel, onOpenTechnicalLog: { navigations += 1 })
        for error in ["MANUAL CHECK REQUIRED: File mismatch.", "Transfer process exited with error code 23."] {
            viewModel.transferState = .error
            viewModel.errorMessage = error
            assertTrue(view.openTechnicalLogAction != nil, "terminal errors expose supplied callback used by native Button")
            view.openTechnicalLogAction?()
        }
        assertEqual(navigations, 2, "both error outcomes invoke exact provided navigation callback")
        for state in [TransferState.ready, .validating, .copying, .verifying, .copyComplete, .safeToFormat, .cancelled] {
            viewModel.transferState = state
            assertNil(view.openTechnicalLogAction, "technical-log error action absent in other states")
        }
        viewModel.transferState = .error
        assertNil(TransferControlsView(viewModel: viewModel).openTechnicalLogAction, "no dead navigation button without callback")
    }

    @MainActor
    private static func testViewModelStartGateAndSelectionLock() throws {
        let temporaryRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FSTTransferControlsLabelTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryRoot)
        }

        let sourceURL = try folder(named: "SOURCE", in: temporaryRoot)
        let destinationURL = try folder(named: "DESTINATION", in: temporaryRoot)
        let alternateSourceURL = try folder(named: "ALT_SOURCE", in: temporaryRoot)
        let alternateDestinationURL = try folder(named: "ALT_DESTINATION", in: temporaryRoot)

        let viewModel = TransferViewModel()
        viewModel.bundledRsyncInfo = BundledRsyncInfo(
            executableURL: URL(fileURLWithPath: "/tmp/fst-test-rsync"),
            version: "3.4.4",
            diagnostics: []
        )

        assertFalse(viewModel.canStartTransfer, "missing source must disable start")
        assertFalse(TransferActionPresentation.isEnabled(for: .ready, canStartTransfer: viewModel.canStartTransfer), "control bar start must use ViewModel readiness")
        assertEqual(viewModel.startBlockedReason, "Select a source folder.", "missing source reason")

        viewModel.sourceURL = sourceURL
        assertFalse(viewModel.canStartTransfer, "missing destination must disable start")
        assertEqual(viewModel.startBlockedReason, "Select a destination folder.", "missing destination reason")

        viewModel.destinationURL = destinationURL
        assertTrue(viewModel.canStartTransfer, "selected source and destination should enable ready start")
        assertTrue(TransferActionPresentation.isEnabled(for: .ready, canStartTransfer: viewModel.canStartTransfer), "valid readiness enables control bar start")

        viewModel.transferState = .cancelled
        assertTrue(viewModel.canStartTransfer, "cancelled with valid selections must allow restart")
        assertNil(viewModel.startBlockedReason, "cancelled restart must not show blocked reason")

        viewModel.sourceURL = nil
        assertFalse(viewModel.canStartTransfer, "cancelled missing source must disable start")
        assertEqual(viewModel.startBlockedReason, "Select a source folder.", "cancelled missing source reason")

        viewModel.sourceURL = sourceURL
        viewModel.destinationURL = nil
        assertFalse(viewModel.canStartTransfer, "cancelled missing destination must disable start")
        assertEqual(viewModel.startBlockedReason, "Select a destination folder.", "cancelled missing destination reason")

        viewModel.destinationURL = destinationURL

        for state in [TransferState.validating, .copying, .verifying] {
            viewModel.transferState = state
            assertFalse(viewModel.canStartTransfer, "\(state.rawValue) must disable start")
            assertTrue(
                TransferInteractionLock.isConfigurationLocked(for: state),
                "\(state.rawValue) must lock source, destination, and settings"
            )
            assertEqual(
                viewModel.startBlockedReason,
                "Transfer in progress. Source, destination, and settings locked.",
                "\(state.rawValue) lock reason"
            )
        }

        viewModel.transferState = .validating
        assertFalse(viewModel.selectSourceFolder(alternateSourceURL), "active validation must reject source changes")
        assertEqual(viewModel.sourceURL, sourceURL, "locked source selection must remain unchanged")
        assertFalse(viewModel.selectDestinationFolder(alternateDestinationURL), "active validation must reject destination changes")
        assertEqual(viewModel.destinationURL, destinationURL, "locked destination selection must remain unchanged")

        for state in [TransferState.ready, .copyComplete, .safeToFormat, .error, .cancelled] {
            assertFalse(
                TransferInteractionLock.isConfigurationLocked(for: state),
                "\(state.rawValue) must not be treated as active lock state"
            )
        }

        viewModel.transferState = .ready
        viewModel.sourceURL = sourceURL
        viewModel.destinationURL = destinationURL
        viewModel.bandwidthLimit = 1
        assertFalse(viewModel.canStartTransfer, "invalid bandwidth must disable start")
        assertEqual(
            viewModel.startBlockedReason,
            RsyncBandwidthLimitError.belowMinimum.localizedDescription,
            "invalid bandwidth should use exact model validation text"
        )

        viewModel.bandwidthLimit = nil
        viewModel.sourceMetadata = SourceStorageMetadata(
            folderName: "SOURCE",
            fullPath: sourceURL.path,
            totalSizeBytes: 2048,
            fileCount: 1,
            folderCount: 0
        )
        viewModel.destinationMetadata = DestinationStorageMetadata(
            freeSpaceBytes: 1024,
            filesystem: "TestFS",
            isWritable: true
        )
        assertFalse(viewModel.canStartTransfer, "insufficient space must disable start")
        assertEqual(
            viewModel.startBlockedReason,
            "Insufficient destination space. Required: 2 KB (2,048 bytes), Available: 1 KB (1,024 bytes).",
            "insufficient space should use human-readable units"
        )
    }

    private static func folder(named name: String, in parentURL: URL) throws -> URL {
        let folderURL = parentURL.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL
    }
}
