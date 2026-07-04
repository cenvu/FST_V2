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
        testActionPresentation()
        try await MainActor.run {
            try testViewModelStartGateAndSelectionLock()
        }

        print("TransferControlsLabelTests passed")
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
            "SHA256 sample verification. 33% coverage.",
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
        assertEqual(VerificationMode.random33.operatorLabel, "SHA256 Sample 33%", "random33 picker label")
        assertEqual(VerificationMode.full.operatorLabel, "xxHash64 Full 100%", "full picker label")

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
            "START",
            "ready label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .copying),
            "TRANSFERRING",
            "copying label"
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
            "VERIFYING",
            "verifying label"
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
        assertEqual(viewModel.startBlockedReason, "Select a source folder.", "missing source reason")

        viewModel.sourceURL = sourceURL
        assertFalse(viewModel.canStartTransfer, "missing destination must disable start")
        assertEqual(viewModel.startBlockedReason, "Select a destination folder.", "missing destination reason")

        viewModel.destinationURL = destinationURL
        assertTrue(viewModel.canStartTransfer, "selected source and destination should enable ready start")

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
