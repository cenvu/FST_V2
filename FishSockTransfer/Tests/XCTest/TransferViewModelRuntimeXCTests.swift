// FST / CenVu | (+84) 842 841 222

import XCTest

@MainActor
final class TransferViewModelRuntimeXCTests: XCTestCase {
    // MARK: - Prompt 5 deterministic Retry admission ordering

    /// Proves the required terminal-ordering invariant directly: while the
    /// first workflow's terminal-tail cleanup is deterministically paused
    /// (report save in flight), `workflowTask` ownership is still held, so
    /// `.error` must not yet be externally observable and a new admission
    /// attempt must be rejected. The instant the gate is released and `.error`
    /// becomes visible, ownership has already been handed back — one
    /// immediate `startTransfer` call (no polling, no delay) is admitted.
    func testErrorStateNotExternallyVisibleUntilWorkflowOwnershipReleasedThenImmediateRetryAdmits() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTTerminalOrdering-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let missingSource = root.appendingPathComponent("missing-source", isDirectory: true)
        let coordinator = TransferCoordinator()
        let recorder = CancelTestRecorder()
        let terminalTailGate = TerminalTailAsyncGate()

        await coordinator.configureCallbacks(
            onStateChanged: { state in recorder.appendState(state) },
            onProgress: { _ in },
            onSpeed: { _ in },
            onTransferTime: { _ in },
            onCurrentFile: { _ in },
            onError: { _ in },
            onLog: { _ in },
            onLogsSnapshot: { [] }
        )
        await coordinator.setTerminalReportTailHookForTesting {
            await terminalTailGate.pause()
        }

        let firstAdmitted = await coordinator.startTransfer(
            source: missingSource,
            destination: root,
            bandwidthLimit: nil,
            mode: .none
        )
        XCTAssertTrue(firstAdmitted)
        await terminalTailGate.waitUntilPaused()

        XCTAssertFalse(
            recorder.snapshotStates().contains(.error),
            "The terminal .error state must not be externally visible before terminal-tail cleanup completes."
        )
        let admittedWhilePaused = await coordinator.startTransfer(
            source: missingSource,
            destination: root,
            bandwidthLimit: nil,
            mode: .none
        )
        XCTAssertFalse(
            admittedWhilePaused,
            "A new workflow must not be admitted while the previous one still owns cleanup."
        )

        await terminalTailGate.resume()
        try await waitForState(.error, in: recorder)

        let retryAdmitted = await coordinator.startTransfer(
            source: missingSource,
            destination: root,
            bandwidthLimit: nil,
            mode: .none
        )
        XCTAssertTrue(
            retryAdmitted,
            "Retry must be admitted by a single immediate call the instant the terminal state is visible."
        )
    }

    /// Holds terminal-tail cleanup open deterministically (a continuation-based
    /// gate, never a wall-clock sleep) well past the old 20-attempt / 0.1s
    /// (2-second) polling ceiling, and repeatedly issues immediate admission
    /// attempts during the hold. Every attempt is rejected purely because
    /// ownership is still held — never because of elapsed time — proving no
    /// attempt counter or timeout exists anywhere in production code. The
    /// moment the gate releases, a single immediate call admits.
    func testSlowTerminalCleanupNeverTimesOutAndRetryStartsImmediatelyAfterRelease() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTSlowCleanup-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let missingSource = root.appendingPathComponent("missing-source", isDirectory: true)
        let coordinator = TransferCoordinator()
        let recorder = CancelTestRecorder()
        let terminalTailGate = TerminalTailAsyncGate()

        await coordinator.configureCallbacks(
            onStateChanged: { state in recorder.appendState(state) },
            onProgress: { _ in },
            onSpeed: { _ in },
            onTransferTime: { _ in },
            onCurrentFile: { _ in },
            onError: { _ in },
            onLog: { _ in },
            onLogsSnapshot: { [] }
        )
        await coordinator.setTerminalReportTailHookForTesting {
            await terminalTailGate.pause()
        }

        let admitted = await coordinator.startTransfer(
            source: missingSource,
            destination: root,
            bandwidthLimit: nil,
            mode: .none
        )
        XCTAssertTrue(admitted)
        await terminalTailGate.waitUntilPaused()

        for _ in 0..<25 {
            let rejected = await coordinator.startTransfer(
                source: missingSource,
                destination: root,
                bandwidthLimit: nil,
                mode: .none
            )
            XCTAssertFalse(
                rejected,
                "Admission must stay rejected for as long as cleanup holds ownership, with no give-up point."
            )
            await Task.yield()
        }
        XCTAssertFalse(recorder.snapshotStates().contains(.error))

        await terminalTailGate.resume()
        try await waitForState(.error, in: recorder)

        let retryAdmitted = await coordinator.startTransfer(
            source: missingSource,
            destination: root,
            bandwidthLimit: nil,
            mode: .none
        )
        XCTAssertTrue(retryAdmitted, "There is no minimum wait once ownership is released.")
    }

    /// From a genuinely active (non-error) workflow, a second immediate
    /// request must be rejected exactly once with no retry loop, and no
    /// delayed admission may occur later once the first workflow is
    /// cancelled and ends.
    func testAdmissionRejectedWhileWorkflowActiveDoesNotPollOrStartLater() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTActiveRejection-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("media".utf8).write(to: source.appendingPathComponent("A001_C001.mov"))
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let coordinator = TransferCoordinator(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: fakeRsync)
        )
        let recorder = CancelTestRecorder()
        await coordinator.configureCallbacks(
            onStateChanged: { state in recorder.appendState(state) },
            onProgress: { _ in },
            onSpeed: { _ in },
            onTransferTime: { _ in },
            onCurrentFile: { _ in },
            onError: { _ in },
            onLog: { _ in },
            onLogsSnapshot: { [] }
        )

        await coordinator.startTransfer(source: source, destination: destination, bandwidthLimit: nil, mode: .random33)
        let marker = destination.appendingPathComponent(".fst-fake-rsync-started")
        try await waitForFile(at: marker)

        let rejected = await coordinator.startTransfer(source: source, destination: destination, bandwidthLimit: nil, mode: .random33)
        XCTAssertFalse(rejected, "A legitimate non-error busy Coordinator must reject a second immediate request.")
        XCTAssertEqual(recorder.snapshotStates().last, .copying, "No phantom workflow may appear from the rejected request.")

        await coordinator.cancelTransfer()
        try await waitForState(.cancelled, in: recorder)
    }

    /// Two immediate Retry requests issued with no suspension between them
    /// must result in exactly one admitted workflow; the loser is rejected
    /// synchronously, never queued for later.
    func testDuplicateRetryAdmitsExactlyOneWorkflowWithNoDelayedSecondAttempt() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTDuplicateRetryCoordinator-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let missingSource = root.appendingPathComponent("missing-source", isDirectory: true)
        let coordinator = TransferCoordinator()
        let recorder = CancelTestRecorder()

        await coordinator.configureCallbacks(
            onStateChanged: { state in recorder.appendState(state) },
            onProgress: { _ in },
            onSpeed: { _ in },
            onTransferTime: { _ in },
            onCurrentFile: { _ in },
            onError: { _ in },
            onLog: { _ in },
            onLogsSnapshot: { [] }
        )

        await coordinator.startTransfer(source: missingSource, destination: root, bandwidthLimit: nil, mode: .none)
        try await waitForState(.error, in: recorder)

        let (first, second) = await issueTwoImmediateStartAttempts(
            on: coordinator,
            source: missingSource,
            destination: root
        )

        XCTAssertTrue(first, "Exactly one of the two immediate requests must be admitted.")
        XCTAssertFalse(second, "The losing request must be rejected immediately, not queued.")
    }

    func testCopyRuntimeCallbacksUpdatePublishedMetricsOnMainActor() {
        let viewModel = makeViewModel()

        viewModel.applyTransferState(.copying)
        viewModel.applyTransferProgress(42.5)
        viewModel.applyTransferSpeed(120.25)
        viewModel.applyTransferTime(90)
        viewModel.applyCurrentFile("clip.mov")

        XCTAssertTrue(Thread.isMainThread)
        XCTAssertEqual(viewModel.transferState, .copying)
        XCTAssertEqual(viewModel.progress, 42.5, accuracy: 0.0001)
        XCTAssertEqual(viewModel.speed, 120.25, accuracy: 0.0001)
        XCTAssertEqual(viewModel.eta, 90, accuracy: 0.0001)
        XCTAssertEqual(viewModel.currentFile, "clip.mov")
    }

    func testRepeatedCopyingStateDoesNotClearRuntimeProgressMetrics() {
        let viewModel = makeViewModel()

        viewModel.applyTransferState(.copying)
        viewModel.applyTransferProgress(55)
        viewModel.applyTransferSpeed(80)
        viewModel.applyTransferTime(30)
        viewModel.applyCurrentFile("")
        viewModel.applyTransferState(.copying)

        XCTAssertEqual(viewModel.progress, 55, accuracy: 0.0001)
        XCTAssertEqual(viewModel.speed, 80, accuracy: 0.0001)
        XCTAssertEqual(viewModel.eta, 30, accuracy: 0.0001)
        XCTAssertEqual(viewModel.currentFile, "")
    }

    func testRuntimeDiagnosticsAreAppliedOnlyOncePerMetric() {
        let viewModel = makeViewModel()

        viewModel.applyTransferProgress(10)
        viewModel.applyTransferProgress(20)
        viewModel.applyTransferSpeed(5)
        viewModel.applyTransferSpeed(6)
        viewModel.applyTransferTime(30)
        viewModel.applyTransferTime(45)

        let diagnosticMessages = viewModel.logs.map(\.message).filter { $0.hasPrefix("DIAG [VIEWMODEL]") }
        XCTAssertEqual(diagnosticMessages.count, 3)
        XCTAssertTrue(diagnosticMessages.contains("DIAG [VIEWMODEL] First progress applied: 10.0%"))
        XCTAssertTrue(diagnosticMessages.contains("DIAG [VIEWMODEL] First speed applied: 5.00 MB/s"))
        XCTAssertTrue(diagnosticMessages.contains("DIAG [VIEWMODEL] First rsync time applied: 00:30"))
    }

    func testCopyPhaseEmptyCurrentFileUsesTruthfulTotalProgressWording() {
        XCTAssertEqual(
            TransferRuntimeMetricPresentation.currentFileTitle(currentFile: "", state: .copying),
            "CURRENT ITEM"
        )
        XCTAssertEqual(
            TransferRuntimeMetricPresentation.currentFileValue(currentFile: "", state: .copying),
            "Waiting for first file..."
        )
        XCTAssertNotEqual(
            TransferRuntimeMetricPresentation.currentFileValue(currentFile: "", state: .copying),
            "Initializing..."
        )
    }

    func testRsyncTimePresentationDoesNotUseETAWording() {
        XCTAssertEqual(TransferRuntimeMetricPresentation.timeValue(seconds: 90), "01:30")
        XCTAssertEqual(TransferRuntimeMetricPresentation.timeValue(seconds: 0), "-")
    }

    func testZeroPercentProgressWithSpeedAndTimeStillUpdatesRuntimeMetrics() {
        let viewModel = makeViewModel()

        viewModel.applyTransferState(.copying)
        viewModel.applyTransferProgress(0)
        viewModel.applyTransferSpeed(117.04)
        viewModel.applyTransferTime(150)

        XCTAssertEqual(viewModel.progress, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.speed, 117.04, accuracy: 0.0001)
        XCTAssertEqual(viewModel.eta, 150, accuracy: 0.0001)
    }

    func testBlankCurrentFileDoesNotClearUsefulFileDuringActiveCopy() {
        let viewModel = makeViewModel()

        viewModel.applyTransferState(.copying)
        viewModel.applyCurrentFile("MACOS-APP/A Better File.dmg")
        viewModel.applyCurrentFile("")

        XCTAssertEqual(viewModel.currentFile, "MACOS-APP/A Better File.dmg")
    }

    func testTerminalAndVerifyTransitionsClearCurrentItemAndRuntimeMetrics() {
        let viewModel = makeViewModel()

        viewModel.applyTransferState(.copying)
        viewModel.applyTransferProgress(42.5)
        viewModel.applyTransferSpeed(120.25)
        viewModel.applyTransferTime(90)
        viewModel.applyCurrentFile("MACOS-APP/A Better File.dmg")

        viewModel.applyTransferState(.verifying)

        XCTAssertEqual(viewModel.progress, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.speed, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.currentFile, "")

        viewModel.applyTransferState(.copying)
        viewModel.applyTransferProgress(42.5)
        viewModel.applyTransferSpeed(120.25)
        viewModel.applyTransferTime(90)
        viewModel.applyCurrentFile("MACOS-APP/A Better File.dmg")

        viewModel.applyTransferState(.cancelled)

        XCTAssertEqual(viewModel.speed, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.currentFile, "")
    }

    func testViewModelUsesObserverMetricsWhenRsyncProgressUnavailable() {
        let viewModel = makeViewModel()
        let observedAt = Date()
        let snapshot = CopyRuntimeSnapshot(
            elapsedSeconds: 15,
            currentItem: "MACOS-APP/observed.mov",
            copiedBytes: 50 * 1_048_576,
            totalBytes: 100 * 1_048_576,
            copiedFiles: 3,
            totalFiles: 6,
            progressFraction: 0.5,
            currentSpeedBytesPerSecond: 10 * 1_048_576,
            averageSpeedBytesPerSecond: 5 * 1_048_576,
            etaSeconds: 5,
            signalSource: .destinationObserver,
            lastObservedAt: observedAt,
            activityState: .observingDestination
        )

        viewModel.applyTransferState(.copying)
        viewModel.applyCopyRuntimeSnapshot(snapshot)

        XCTAssertEqual(viewModel.transferState, .copying)
        XCTAssertEqual(viewModel.progress, 50, accuracy: 0.0001)
        XCTAssertEqual(viewModel.speed, 10, accuracy: 0.0001)
        XCTAssertEqual(viewModel.eta, 5, accuracy: 0.0001)
        XCTAssertEqual(viewModel.currentFile, "MACOS-APP/observed.mov")
        XCTAssertEqual(viewModel.copyElapsedSeconds, 15)
        XCTAssertEqual(viewModel.copyRuntimeSignalSource, .destinationObserver)
    }

    func testViewModelPrefersRsyncCurrentFileWhenObserverAlsoHasCurrentItem() {
        let viewModel = makeViewModel()
        let snapshot = CopyRuntimeSnapshot(
            elapsedSeconds: 15,
            currentItem: "MACOS-APP/observed.mov",
            copiedBytes: 50 * 1_048_576,
            totalBytes: 100 * 1_048_576,
            copiedFiles: 3,
            totalFiles: 6,
            progressFraction: 0.5,
            currentSpeedBytesPerSecond: 10 * 1_048_576,
            averageSpeedBytesPerSecond: 5 * 1_048_576,
            etaSeconds: 5,
            signalSource: .destinationObserver,
            lastObservedAt: Date().addingTimeInterval(20),
            activityState: .observingDestination
        )

        viewModel.applyTransferState(.copying)
        viewModel.applyCurrentFile("MACOS-APP/rsync.mov")
        viewModel.applyCopyRuntimeSnapshot(snapshot)

        XCTAssertEqual(viewModel.currentFile, "MACOS-APP/rsync.mov")
        XCTAssertEqual(viewModel.copyRuntimeSignalSource, .mixed)
    }

    func testObserverMetricsDoNotAffectSafeToEjectGate() {
        let viewModel = makeViewModel()
        let snapshot = CopyRuntimeSnapshot(
            elapsedSeconds: 20,
            currentItem: "clip.mov",
            copiedBytes: 100,
            totalBytes: 100,
            copiedFiles: 1,
            totalFiles: 1,
            progressFraction: 1,
            currentSpeedBytesPerSecond: nil,
            averageSpeedBytesPerSecond: 5,
            etaSeconds: nil,
            signalSource: .destinationObserver,
            lastObservedAt: Date(),
            activityState: .observingDestination
        )

        viewModel.applyTransferState(.copying)
        viewModel.applyCopyRuntimeSnapshot(snapshot)

        XCTAssertEqual(viewModel.transferState, .copying)
        XCTAssertNotEqual(viewModel.transferState, .safeToFormat)
        XCTAssertLessThan(viewModel.progress, 100)
    }

    func testVerifyPhaseClearsObserverMetricsAndUsesVerifyPresentation() {
        let viewModel = makeViewModel()
        let snapshot = CopyRuntimeSnapshot(
            elapsedSeconds: 15,
            currentItem: "MACOS-APP/observed.mov",
            copiedBytes: 50,
            totalBytes: 100,
            copiedFiles: 3,
            totalFiles: 6,
            progressFraction: 0.5,
            currentSpeedBytesPerSecond: 10,
            averageSpeedBytesPerSecond: 5,
            etaSeconds: 5,
            signalSource: .destinationObserver,
            lastObservedAt: Date(),
            activityState: .observingDestination
        )

        viewModel.applyTransferState(.copying)
        viewModel.applyCopyRuntimeSnapshot(snapshot)
        viewModel.applyTransferState(.verifying)

        XCTAssertNil(viewModel.copyRuntimeSnapshot)
        XCTAssertEqual(viewModel.speed, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(TransferRuntimeMetricPresentation.progressTitle(for: .verifying), "Verify Progress")
        XCTAssertEqual(
            TransferRuntimeMetricPresentation.currentFileTitle(currentFile: "", state: .verifying),
            "CURRENT VERIFY FILE"
        )
        XCTAssertFalse(TransferRuntimeMetricPresentation.shouldShowRsyncTime(for: .verifying))
    }

    func testVerifyETABeforeProgressIsEstimating() {
        let viewModel = makeViewModel()
        viewModel.applyTransferState(.verifying)

        XCTAssertEqual(viewModel.progress, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.verifyElapsedSeconds, 0)
    }

    func testVerifyETAAt25PercentAfter30SecondsIs90Seconds() {
        let viewModel = makeViewModel()
        viewModel.applyTransferState(.verifying)
        viewModel.setVerifyElapsedSecondsForTesting(30)
        viewModel.applyTransferProgress(0.25) // 25%

        XCTAssertEqual(viewModel.eta, 90, accuracy: 0.0001)
    }

    func testVerifyETAZeroPercentDoesNotDivideByZero() {
        let viewModel = makeViewModel()
        viewModel.applyTransferState(.verifying)
        viewModel.setVerifyElapsedSecondsForTesting(30)
        viewModel.applyTransferProgress(0.0) // 0%

        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertFalse(viewModel.eta.isNaN)
        XCTAssertFalse(viewModel.eta.isInfinite)
    }

    func testVerifyETAHundredPercentHandledSafely() {
        let viewModel = makeViewModel()
        viewModel.applyTransferState(.verifying)
        viewModel.setVerifyElapsedSecondsForTesting(30)
        viewModel.applyTransferProgress(1.0) // 100%

        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertFalse(viewModel.eta.isNaN)
        XCTAssertFalse(viewModel.eta.isInfinite)
    }

    func testVerifyETAClearsOnVerifyCompleted() {
        let viewModel = makeViewModel()
        viewModel.applyTransferState(.verifying)
        viewModel.setVerifyElapsedSecondsForTesting(30)
        viewModel.applyTransferProgress(0.5)
        XCTAssertEqual(viewModel.eta, 30, accuracy: 0.0001)

        viewModel.applyTransferState(.safeToFormat)
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.verifyElapsedSeconds, 0)
    }

    func testVerifyETAClearsOnCancelFailureResetNewJob() {
        let viewModel = makeViewModel()

        viewModel.applyTransferState(.verifying)
        viewModel.setVerifyElapsedSecondsForTesting(30)
        viewModel.applyTransferProgress(0.5)
        XCTAssertEqual(viewModel.eta, 30, accuracy: 0.0001)

        viewModel.applyTransferState(.cancelled)
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.verifyElapsedSeconds, 0)

        viewModel.applyTransferState(.verifying)
        viewModel.setVerifyElapsedSecondsForTesting(30)
        viewModel.applyTransferProgress(0.5)
        XCTAssertEqual(viewModel.eta, 30, accuracy: 0.0001)

        viewModel.applyTransferState(.error)
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.verifyElapsedSeconds, 0)

        viewModel.applyTransferState(.verifying)
        viewModel.setVerifyElapsedSecondsForTesting(30)
        viewModel.applyTransferProgress(0.5)
        XCTAssertEqual(viewModel.eta, 30, accuracy: 0.0001)

        viewModel.applyTransferState(.ready)
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.verifyElapsedSeconds, 0)

        viewModel.applyTransferState(.verifying)
        viewModel.setVerifyElapsedSecondsForTesting(30)
        viewModel.applyTransferProgress(0.5)
        XCTAssertEqual(viewModel.eta, 30, accuracy: 0.0001)

        viewModel.applyTransferState(.validating) // New job
        XCTAssertEqual(viewModel.eta, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.verifyElapsedSeconds, 0)
    }

    func testTelegramTestMessageIsIgnoredWhileSendIsInFlight() async throws {
        let service = RuntimeMockNotificationService(delayNanoseconds: 150_000_000)
        let viewModel = makeViewModel(notificationService: service)
        viewModel.notificationSettings = NotificationSettings(isTelegramEnabled: true, chatID: "123")
        viewModel.telegramBotToken = "token"

        viewModel.testTelegramNotification()
        viewModel.testTelegramNotification()

        XCTAssertTrue(viewModel.isSendingTelegramTestMessage)
        try await waitForSendCount(service, expectedCount: 1)
        let sendCountDuringFirstSend = await service.sendCount()
        XCTAssertEqual(sendCountDuringFirstSend, 1)

        try await waitForTelegramTestSendToFinish(viewModel)
        XCTAssertFalse(viewModel.isSendingTelegramTestMessage)
        let finalSendCount = await service.sendCount()
        XCTAssertEqual(finalSendCount, 1)
    }

    func testIdenticalTelegramWarningsAreRateLimited() async throws {
        let service = RuntimeMockNotificationService(error: TelegramNotificationError.cannotReachAPIHost)
        let viewModel = makeViewModel(notificationService: service)
        viewModel.notificationSettings = NotificationSettings(isTelegramEnabled: true, chatID: "123")
        viewModel.telegramBotToken = "token"

        viewModel.testTelegramNotification()
        try await waitForTelegramTestSendToFinish(viewModel)

        viewModel.testTelegramNotification()
        try await waitForTelegramTestSendToFinish(viewModel)

        let telegramWarnings = viewModel.logs.filter {
            $0.message == "Telegram notification warning: Cannot reach Telegram API host. Check internet/DNS/VPN/firewall."
        }
        let sendCount = await service.sendCount()
        XCTAssertEqual(sendCount, 2)
        XCTAssertEqual(telegramWarnings.count, 1)
    }

    // MARK: - Clear Source

    func testClearSourceFolderResetsSelectionMetadataAndStartEligibility() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTClearSource-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let sourceFile = source.appendingPathComponent("A001_C001.mov")
        try Data("media".utf8).write(to: sourceFile)
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        XCTAssertTrue(viewModel.selectSourceFolder(source))
        XCTAssertTrue(viewModel.selectDestinationFolder(destination))
        // Await metadata deterministically so the assertions exercise a fully loaded state.
        await viewModel.sourceMetadataTaskForTesting?.value
        await viewModel.destinationMetadataTaskForTesting?.value
        XCTAssertNotNil(viewModel.sourceMetadata)
        XCTAssertNotNil(viewModel.destinationMetadata)
        XCTAssertTrue(viewModel.canStartTransfer)

        viewModel.clearSourceFolder()

        XCTAssertNil(viewModel.sourceURL)
        XCTAssertNil(viewModel.sourceMetadata)
        XCTAssertNil(viewModel.sourceMetadataTaskForTesting)
        XCTAssertFalse(viewModel.canStartTransfer)
        XCTAssertEqual(viewModel.destinationURL, destination, "Destination selection must remain unchanged")
        XCTAssertNotNil(viewModel.destinationMetadata, "Destination metadata must remain unchanged")
        // The real folder is never deleted or modified.
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceFile.path))
        XCTAssertEqual(try Data(contentsOf: sourceFile), Data("media".utf8))
    }

    func testClearSourceFolderIsInertWhileConfigurationLocked() {
        let viewModel = makeViewModel()
        let sourceURL = URL(fileURLWithPath: "/Volumes/CARD_A")
        viewModel.sourceURL = sourceURL
        viewModel.sourceMetadata = SourceStorageMetadata(
            folderName: "CARD_A",
            fullPath: sourceURL.path,
            totalSizeBytes: 1024,
            fileCount: 1,
            folderCount: 0
        )
        viewModel.applyTransferState(.copying)

        viewModel.clearSourceFolder()

        XCTAssertEqual(viewModel.sourceURL, sourceURL)
        XCTAssertNotNil(viewModel.sourceMetadata)
    }

    func testStaleSourceMetadataTaskCannotRepopulateClearedSource() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTStaleSource-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data("media".utf8).write(to: source.appendingPathComponent("A001_C001.mov"))
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        XCTAssertTrue(viewModel.selectSourceFolder(source))
        let inFlightTask = viewModel.sourceMetadataTaskForTesting
        XCTAssertNotNil(inFlightTask, "selectSourceFolder must start a Source metadata task")

        viewModel.clearSourceFolder()
        XCTAssertNil(viewModel.sourceURL)
        XCTAssertNil(viewModel.sourceMetadata)

        // Let the old metadata task finish completely. It must not repopulate
        // the cleared Source whether it observes cancellation at its checkpoint
        // or was already inside the apply closure (URL-identity guard).
        await inFlightTask?.value

        XCTAssertNil(viewModel.sourceURL)
        XCTAssertNil(viewModel.sourceMetadata)
        XCTAssertFalse(viewModel.canStartTransfer)
    }

    // MARK: - Clear Destination

    func testClearDestinationFolderResetsSelectionKeepsSourceAndFolderUntouched() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTClearDestination-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("media".utf8).write(to: source.appendingPathComponent("A001_C001.mov"))
        let destinationFile = destination.appendingPathComponent("D001.mov")
        try Data("already here".utf8).write(to: destinationFile)
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        XCTAssertTrue(viewModel.selectSourceFolder(source))
        XCTAssertTrue(viewModel.selectDestinationFolder(destination))
        await viewModel.sourceMetadataTaskForTesting?.value
        await viewModel.destinationMetadataTaskForTesting?.value
        XCTAssertNotNil(viewModel.destinationMetadata)
        XCTAssertTrue(viewModel.canStartTransfer)

        viewModel.clearDestinationFolder()

        XCTAssertNil(viewModel.destinationURL)
        XCTAssertNil(viewModel.destinationMetadata)
        XCTAssertNil(viewModel.destinationMetadataTaskForTesting)
        XCTAssertFalse(viewModel.canStartTransfer)
        XCTAssertEqual(viewModel.sourceURL, source, "Source selection must remain unchanged")
        XCTAssertNotNil(viewModel.sourceMetadata, "Source metadata must remain unchanged")
        // The real folder and its contents are never deleted or modified.
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destinationFile.path))
        XCTAssertEqual(try Data(contentsOf: destinationFile), Data("already here".utf8))
    }

    func testClearDestinationFolderClearsInsufficientSpaceWarning() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTClearDestWarning-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data(repeating: 0x41, count: 4096).write(to: source.appendingPathComponent("A001_C001.mov"))
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        XCTAssertTrue(viewModel.selectSourceFolder(source))
        await viewModel.sourceMetadataTaskForTesting?.value
        XCTAssertNotNil(viewModel.sourceMetadata)

        // Replace the real destination metadata with a free-space figure that
        // cannot fit the source, then re-select the Source so the real
        // metadata apply path re-derives the warning against the current
        // (insufficient) destination metadata and publishes it.
        viewModel.destinationURL = destination
        viewModel.destinationMetadata = DestinationStorageMetadata(
            freeSpaceBytes: 64,
            filesystem: "Test",
            isWritable: true
        )
        XCTAssertTrue(viewModel.hasInsufficientDestinationSpace)
        XCTAssertTrue(viewModel.selectSourceFolder(source))
        await viewModel.sourceMetadataTaskForTesting?.value
        XCTAssertNotNil(viewModel.storageWarningMessage, "Insufficient-space warning must be visible")
        XCTAssertFalse(viewModel.canStartTransfer)

        viewModel.clearDestinationFolder()

        XCTAssertNil(viewModel.destinationURL)
        XCTAssertNil(viewModel.destinationMetadata)
        XCTAssertNil(viewModel.storageWarningMessage, "Insufficient-space warning must disappear")
        XCTAssertFalse(viewModel.hasInsufficientDestinationSpace)
        XCTAssertEqual(viewModel.sourceURL, source, "Source selection must remain unchanged")
    }

    func testClearDestinationFolderIsInertWhileConfigurationLocked() {
        let viewModel = makeViewModel()
        let destinationURL = URL(fileURLWithPath: "/Volumes/RAID")
        viewModel.destinationURL = destinationURL
        viewModel.applyTransferState(.verifying)

        viewModel.clearDestinationFolder()

        XCTAssertEqual(viewModel.destinationURL, destinationURL)
    }

    func testStaleDestinationMetadataTaskCannotRepopulateClearedDestination() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTStaleDestination-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        XCTAssertTrue(viewModel.selectDestinationFolder(destination))
        let inFlightTask = viewModel.destinationMetadataTaskForTesting
        XCTAssertNotNil(inFlightTask, "selectDestinationFolder must start a Destination metadata task")

        viewModel.clearDestinationFolder()
        XCTAssertNil(viewModel.destinationURL)
        XCTAssertNil(viewModel.destinationMetadata)

        await inFlightTask?.value

        XCTAssertNil(viewModel.destinationURL)
        XCTAssertNil(viewModel.destinationMetadata)
        XCTAssertFalse(viewModel.canStartTransfer)
    }

    // MARK: - Start / Cancel presentation

    func testActionPresentationReadyWithValidInputsPresentsStart() {
        XCTAssertEqual(TransferActionPresentation.title(for: .ready, canStartTransfer: true), "START")
        XCTAssertEqual(TransferActionPresentation.title(for: .ready, canStartTransfer: false), "START")
        XCTAssertFalse(TransferActionPresentation.isActiveCancellableState(.ready))
    }

    func testActionPresentationCopyingPresentsCancel() {
        XCTAssertEqual(TransferActionPresentation.title(for: .copying), "CANCEL")
        XCTAssertTrue(TransferActionPresentation.isActiveCancellableState(.copying))
        XCTAssertTrue(TransferCancelRequestGuard().allowsNewCancellationRequest(for: .copying))
    }

    func testActionPresentationVerifyingPresentsCancel() {
        XCTAssertEqual(TransferActionPresentation.title(for: .verifying), "CANCEL")
        XCTAssertTrue(TransferActionPresentation.isActiveCancellableState(.verifying))
        XCTAssertTrue(TransferCancelRequestGuard().allowsNewCancellationRequest(for: .verifying))
    }

    func testActionPresentationValidatingIsNotAdvertisedAsCancellable() {
        XCTAssertEqual(TransferActionPresentation.title(for: .validating), "PREPARING TRANSFER")
        // Validation has no cancellable task in the current Coordinator, so no
        // cancellation request may be presented for it.
        XCTAssertFalse(TransferActionPresentation.isActiveCancellableState(.validating))
        XCTAssertFalse(TransferCancelRequestGuard().allowsNewCancellationRequest(for: .validating))
    }

    func testActionPresentationCancelledPreservesStartNewTransfer() {
        XCTAssertEqual(
            TransferActionPresentation.title(for: .cancelled, canStartTransfer: true),
            "START NEW TRANSFER"
        )
        XCTAssertEqual(TransferActionPresentation.title(for: .cancelled, canStartTransfer: false), "CANCELLED")
        XCTAssertFalse(TransferActionPresentation.isActiveCancellableState(.cancelled))
    }

    func testActionPresentationErrorPresentsRetryWhenValid() {
        XCTAssertEqual(
            TransferActionPresentation.title(for: .error, canStartTransfer: true),
            "RETRY"
        )
        XCTAssertEqual(
            TransferActionPresentation.actionIcon(for: .error, canStartTransfer: true),
            "arrow.clockwise"
        )
        XCTAssertEqual(
            TransferActionPresentation.accessibilityLabel(for: .error, canStartTransfer: true),
            "Retry Transfer"
        )
        XCTAssertFalse(TransferActionPresentation.isActiveCancellableState(.error))
        XCTAssertFalse(TransferCancelRequestGuard().allowsNewCancellationRequest(for: .error))
    }

    func testActionPresentationErrorPresentsDisabledErrorWhenInvalid() {
        XCTAssertEqual(
            TransferActionPresentation.title(for: .error, canStartTransfer: false),
            "TRANSFER ERROR"
        )
        XCTAssertNil(TransferActionPresentation.actionIcon(for: .error, canStartTransfer: false))
        XCTAssertNil(TransferActionPresentation.accessibilityLabel(for: .error, canStartTransfer: false))
        XCTAssertFalse(TransferActionPresentation.isActiveCancellableState(.error))
        XCTAssertFalse(TransferCancelRequestGuard().allowsNewCancellationRequest(for: .error))
    }

    // MARK: - Cancel confirmation and duplicate suppression

    func testCancelRequestGuardRequestsConfirmationAndSendsExactlyOneRequest() {
        var guardState = TransferCancelRequestGuard()
        var cancelRequestCount = 0

        // Clicking the active Cancel button first requests confirmation; no
        // ViewModel cancellation request is sent before confirmation.
        XCTAssertTrue(guardState.allowsNewCancellationRequest(for: .copying))
        XCTAssertEqual(cancelRequestCount, 0)

        // Operator confirms "Cancel Transfer".
        guardState.confirmCancellationRequest()
        cancelRequestCount += 1
        XCTAssertEqual(cancelRequestCount, 1)

        // The button is disabled and a second click cannot send another request.
        XCTAssertTrue(guardState.isCancellationRequested)
        XCTAssertFalse(guardState.allowsNewCancellationRequest(for: .copying))
        XCTAssertFalse(guardState.allowsNewCancellationRequest(for: .verifying))
        XCTAssertEqual(cancelRequestCount, 1)
    }

    func testCancelRequestGuardContinueSendsNoCancellationRequest() {
        let guardState = TransferCancelRequestGuard()

        // "Continue Transfer" takes no confirm action: nothing is recorded and
        // the workflow may still be cancelled by a later click.
        XCTAssertTrue(guardState.allowsNewCancellationRequest(for: .verifying))
        XCTAssertFalse(guardState.isCancellationRequested)
        XCTAssertTrue(guardState.allowsNewCancellationRequest(for: .verifying))
        XCTAssertEqual(guardState.isCancellationRequested, false)
    }

    func testCancelRequestGuardBlocksRequestsOutsideActiveStates() {
        let guardState = TransferCancelRequestGuard()
        for state in [TransferState.ready, .validating, .copyComplete, .safeToFormat, .error, .cancelled] {
            XCTAssertFalse(
                guardState.allowsNewCancellationRequest(for: state),
                "State \(state) must never allow a cancellation request"
            )
        }
        XCTAssertTrue(guardState.allowsNewCancellationRequest(for: .copying))
        XCTAssertTrue(guardState.allowsNewCancellationRequest(for: .verifying))
    }

    func testCancelRequestGuardResetsAfterLeavingActiveState() {
        var guardState = TransferCancelRequestGuard()
        guardState.confirmCancellationRequest()
        XCTAssertFalse(guardState.allowsNewCancellationRequest(for: .copying))

        // The workflow leaves the active state (cancelled or error): the guard
        // resets and does not retain the request permanently.
        guardState.reset(for: .cancelled)
        XCTAssertFalse(guardState.allowsNewCancellationRequest(for: .cancelled))
        XCTAssertTrue(guardState.allowsNewCancellationRequest(for: .copying))

        guardState.confirmCancellationRequest()
        XCTAssertFalse(guardState.allowsNewCancellationRequest(for: .verifying))
        guardState.reset(for: .error)
        XCTAssertTrue(guardState.allowsNewCancellationRequest(for: .verifying))
    }

    // MARK: - Cancellation outcome evidence

    func testCopyCancellationEndsCancelledAndNeverProducesSafeToEject() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTCopyCancel-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("media".utf8).write(to: source.appendingPathComponent("A001_C001.mov"))
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let coordinator = TransferCoordinator(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: fakeRsync)
        )
        let recorder = CancelTestRecorder()
        await coordinator.configureCallbacks(
            onStateChanged: { state in recorder.appendState(state) },
            onProgress: { _ in },
            onSpeed: { _ in },
            onTransferTime: { _ in },
            onCurrentFile: { _ in },
            onError: { _ in },
            onLog: { log in recorder.appendLog(log) },
            onLogsSnapshot: { [] }
        )

        await coordinator.startTransfer(
            source: source,
            destination: destination,
            bandwidthLimit: nil,
            mode: .random33
        )

        // Deterministic gate: the fake rsync process only starts the "copy"
        // after it touches a marker file in the destination, and it never
        // exits on its own — the copy phase is guaranteed active here, so
        // cancellation is the only way the workflow can end.
        let marker = destination.appendingPathComponent(".fst-fake-rsync-started")
        try await waitForFile(at: marker)

        await coordinator.cancelTransfer()
        try await waitForState(.cancelled, in: recorder)

        let states = recorder.snapshotStates()
        let logMessages = recorder.snapshotLogMessages()
        XCTAssertEqual(states.last, .cancelled, "Copy cancellation must end in .cancelled, got: \(states)")
        XCTAssertFalse(states.contains(.safeToFormat), "Cancellation must never reach SAFE TO EJECT")
        XCTAssertFalse(states.contains(.copyComplete), "Cancellation must never report copy completion")
        XCTAssertFalse(logMessages.contains("Verification Passed. SAFE TO EJECT."))
        XCTAssertFalse(logMessages.contains("TRANSFER COMPLETE. Verification disabled."))
    }

    // MARK: - Prompt 5 configuration-change safety before Retry

    func testClearingSourceBeforeRetryPreventsAutomaticWorkflowStart() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTClearSourceBeforeRetry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        viewModel.sourceURL = root.appendingPathComponent("source")
        viewModel.destinationURL = root.appendingPathComponent("destination")
        viewModel.applyTransferState(.error)
        viewModel.errorMessage = "TRANSFER ERROR: sample failure"

        viewModel.clearSourceFolder()

        XCTAssertNil(viewModel.sourceURL)
        XCTAssertFalse(viewModel.canStartTransfer, "Retry must be disabled once Source is cleared.")

        viewModel.startTransfer()

        XCTAssertEqual(viewModel.transferState, .error, "No workflow may start automatically while Source is missing.")
        XCTAssertEqual(viewModel.errorMessage, "Please select both source and destination folders.")
    }

    func testClearingDestinationBeforeRetryPreventsAutomaticWorkflowStart() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTClearDestinationBeforeRetry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        viewModel.sourceURL = root.appendingPathComponent("source")
        viewModel.destinationURL = root.appendingPathComponent("destination")
        viewModel.applyTransferState(.error)
        viewModel.errorMessage = "TRANSFER ERROR: sample failure"

        viewModel.clearDestinationFolder()

        XCTAssertNil(viewModel.destinationURL)
        XCTAssertFalse(viewModel.canStartTransfer, "Retry must be disabled once Destination is cleared.")

        viewModel.startTransfer()

        XCTAssertEqual(viewModel.transferState, .error, "No workflow may start automatically while Destination is missing.")
        XCTAssertEqual(viewModel.errorMessage, "Please select both source and destination folders.")
    }

    func testChangingVerificationModeBeforeRetryUsesTheNewModeNotAStaleCapture() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTSettingsChangeBeforeRetry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let missingSource = root.appendingPathComponent("missing-source", isDirectory: true)
        let realSource = root.appendingPathComponent("real-source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: realSource, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("media".utf8).write(to: realSource.appendingPathComponent("A001_C001.mov"))
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeSucceedingFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        viewModel.sourceURL = missingSource
        viewModel.destinationURL = destination
        viewModel.verificationMode = .full
        viewModel.startTransfer()
        try await waitForViewModelState(.error, on: viewModel)

        XCTAssertTrue(viewModel.selectSourceFolder(realSource))
        await viewModel.sourceMetadataTaskForTesting?.value
        // Changed after the error and before Retry: the request Retry uses
        // must reflect this immediately, not a stale .full capture from the
        // original failed attempt.
        viewModel.verificationMode = .none

        viewModel.startTransfer()

        try await waitForViewModelState(.copyComplete, on: viewModel)
        XCTAssertNotEqual(
            viewModel.transferState,
            .safeToFormat,
            "A stale .full capture would have entered verification instead of fast-exiting at copy-complete."
        )
    }

    // MARK: - Prompt 5 full-workflow Retry and duplicate-Retry evidence

    func testFullWorkflowRetryValidatesCopiesAndVerifiesAgainUsingCurrentConfiguration() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTFullWorkflowRetry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let missingSource = root.appendingPathComponent("missing-source", isDirectory: true)
        let realSource = root.appendingPathComponent("real-source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: realSource, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("media".utf8).write(to: realSource.appendingPathComponent("A001_C001.mov"))
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeSucceedingFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)
        viewModel.sourceURL = missingSource
        viewModel.destinationURL = destination
        viewModel.verificationMode = .full
        viewModel.startTransfer()
        try await waitForViewModelState(.error, on: viewModel)
        XCTAssertEqual(viewModel.logs.filter { $0.message == "Validating transfer requirements..." }.count, 1)

        XCTAssertTrue(viewModel.selectSourceFolder(realSource))
        await viewModel.sourceMetadataTaskForTesting?.value
        XCTAssertTrue(viewModel.canStartTransfer)

        viewModel.startTransfer()

        try await waitForViewModelState(.safeToFormat, on: viewModel)

        let validatingLogCount = viewModel.logs.filter { $0.message == "Validating transfer requirements..." }.count
        XCTAssertEqual(validatingLogCount, 2, "Retry must validate again exactly once, not resume or skip validation.")
        XCTAssertTrue(viewModel.logs.contains { $0.message == "Verification Passed. SAFE TO EJECT." })
    }

    func testViewModelDuplicateRetryRequestsAdmitOnlyOneWorkflow() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTViewModelDuplicateRetry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("source", isDirectory: true)
        let missingSource = root.appendingPathComponent("missing-source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("media".utf8).write(to: source.appendingPathComponent("A001_C001.mov"))
        let fakeRsync = root.appendingPathComponent("fake-rsync")
        try writeFakeRsyncScript(at: fakeRsync)

        let viewModel = makeViewModelWithBundledRsync(fakeRsyncURL: fakeRsync)

        viewModel.sourceURL = missingSource
        viewModel.destinationURL = destination
        viewModel.startTransfer()
        try await waitForViewModelState(.error, on: viewModel)

        XCTAssertTrue(viewModel.selectSourceFolder(source))
        await viewModel.sourceMetadataTaskForTesting?.value

        // Two immediate Retry requests issued from the same visible .error
        // state, with no delay between them.
        viewModel.startTransfer()
        viewModel.startTransfer()

        try await waitForViewModelState(.copying, on: viewModel)

        let validatingLogCount = viewModel.logs.filter { $0.message == "Validating transfer requirements..." }.count
        XCTAssertEqual(
            validatingLogCount,
            2,
            "Exactly one workflow generation must run per admitted request: one from the initial failed attempt and one from the single admitted duplicate Retry."
        )

        viewModel.cancelTransfer()
        try await waitForViewModelState(.cancelled, on: viewModel)
    }

    // MARK: - Prompt 2 FR-003 BookmarkAccessCoordinator (generation-aware lease safety)

    func testBookmarkAccessCoordinatorStopsSuccessfulAccessExactlyOnce() async throws {
        let provider = FakeSecurityScopedAccessProvider()
        let coordinator = BookmarkAccessCoordinator(accessProvider: provider)
        let url = try makeBookmarkTestDirectory(name: "access-stop-once")
        defer { try? FileManager.default.removeItem(at: url) }

        let started = await coordinator.beginAccess(for: url, role: .source, generation: 1)
        XCTAssertEqual(started, .started)
        await coordinator.endAccess(for: .source, url: url, generation: 1)
        await coordinator.endAccess(for: .source, url: url, generation: 1)

        let stopCount = await provider.stopCount(for: url)
        XCTAssertEqual(stopCount, 1, "A second endAccess for an already-released lease must be a no-op.")
    }

    func testBookmarkAccessCoordinatorNeverStopsFailedStart() async throws {
        let provider = FakeSecurityScopedAccessProvider()
        let url = try makeBookmarkTestDirectory(name: "access-failed-start")
        defer { try? FileManager.default.removeItem(at: url) }
        await provider.failToStart(for: url)
        let coordinator = BookmarkAccessCoordinator(accessProvider: provider)

        let result = await coordinator.beginAccess(for: url, role: .source, generation: 1)
        await coordinator.endAccess(for: .source, url: url, generation: 1)

        XCTAssertEqual(result, .failedToStart)
        let stopCount = await provider.stopCount(for: url)
        XCTAssertEqual(stopCount, 0, "Nothing was started, so nothing may be stopped.")
    }

    func testBookmarkAccessCoordinatorDoesNotStartSameURLTwiceAcrossGenerations() async throws {
        let provider = FakeSecurityScopedAccessProvider()
        let url = try makeBookmarkTestDirectory(name: "access-same-url-generation")
        defer { try? FileManager.default.removeItem(at: url) }
        let coordinator = BookmarkAccessCoordinator(accessProvider: provider)

        let firstResult = await coordinator.beginAccess(for: url, role: .source, generation: 1)
        let secondResult = await coordinator.beginAccess(for: url, role: .source, generation: 2)
        let startCount = await provider.startCount(for: url)
        let stopCount = await provider.stopCount(for: url)
        XCTAssertEqual(firstResult, .started)
        XCTAssertEqual(secondResult, .started)
        XCTAssertEqual(startCount, 1)
        XCTAssertEqual(stopCount, 0)

        await coordinator.endAccess(for: .source, url: url, generation: 2)
        let finalStopCount = await provider.stopCount(for: url)
        XCTAssertEqual(finalStopCount, 1)
    }

    func testBookmarkAccessCoordinatorReplacingRoleBalancesOnlyThatRolesLease() async throws {
        let provider = FakeSecurityScopedAccessProvider()
        let coordinator = BookmarkAccessCoordinator(accessProvider: provider)
        let oldSource = try makeBookmarkTestDirectory(name: "replace-old-source")
        let newSource = try makeBookmarkTestDirectory(name: "replace-new-source")
        let destination = try makeBookmarkTestDirectory(name: "replace-destination")
        defer {
            try? FileManager.default.removeItem(at: oldSource)
            try? FileManager.default.removeItem(at: newSource)
            try? FileManager.default.removeItem(at: destination)
        }

        _ = await coordinator.beginAccess(for: oldSource, role: .source, generation: 1)
        _ = await coordinator.beginAccess(for: destination, role: .destination, generation: 1)

        let replaced = await coordinator.beginAccess(for: newSource, role: .source, generation: 2)

        XCTAssertEqual(replaced, .started)
        let oldSourceStops = await provider.stopCount(for: oldSource)
        let destinationStops = await provider.stopCount(for: destination)
        XCTAssertEqual(oldSourceStops, 1, "Replacing Source must balance the old Source lease exactly once.")
        XCTAssertEqual(destinationStops, 0, "Replacing Source must never touch the Destination lease.")
    }

    func testBookmarkAccessCoordinatorSupersededAttemptReleasesAcquiredAccessAndNeverWins() async throws {
        let provider = FakeSecurityScopedAccessProvider()
        let coordinator = BookmarkAccessCoordinator(accessProvider: provider)
        let staleURL = try makeBookmarkTestDirectory(name: "superseded-stale")
        let freshURL = try makeBookmarkTestDirectory(name: "superseded-fresh")
        defer {
            try? FileManager.default.removeItem(at: staleURL)
            try? FileManager.default.removeItem(at: freshURL)
        }
        let gate = TerminalTailAsyncGate()
        await provider.gateStart(for: staleURL, using: gate)

        async let staleResult = coordinator.beginAccess(for: staleURL, role: .source, generation: 1)
        await gate.waitUntilPaused()

        let freshResult = await coordinator.beginAccess(for: freshURL, role: .source, generation: 2)
        XCTAssertEqual(freshResult, .started)

        await gate.resume()
        let resolvedStaleResult = await staleResult

        XCTAssertEqual(resolvedStaleResult, .superseded)
        let staleStops = await provider.stopCount(for: staleURL)
        XCTAssertEqual(staleStops, 1, "The superseded stale attempt must release the access it just acquired.")
        let freshStops = await provider.stopCount(for: freshURL)
        XCTAssertEqual(freshStops, 0, "The winning fresh lease must never be touched by the loser.")
    }

    // MARK: - Prompt 2 FR-003 Selection saves a bookmark

    func testValidSourceSelectionSavesSourceBookmark() async throws {
        let source = try makeBookmarkTestDirectory(name: "select-save-source")
        defer { try? FileManager.default.removeItem(at: source) }
        let persistence = FakeBookmarkPersisting()
        let access = FakeSecurityScopedAccessProvider()
        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)

        XCTAssertTrue(viewModel.selectSourceFolder(source))
        await viewModel.sourceBookmarkTaskForTesting?.value

        let saveCount = await persistence.saveCallCount(for: .source)
        XCTAssertEqual(saveCount, 1)
        let destinationStored = await persistence.isStored(role: .destination)
        XCTAssertFalse(destinationStored, "Selecting Source must never persist anything under Destination.")
    }

    func testValidDestinationSelectionSavesDestinationBookmark() async throws {
        let destination = try makeBookmarkTestDirectory(name: "select-save-destination", withFile: false)
        defer { try? FileManager.default.removeItem(at: destination) }
        let persistence = FakeBookmarkPersisting()
        let access = FakeSecurityScopedAccessProvider()
        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)

        XCTAssertTrue(viewModel.selectDestinationFolder(destination))
        await viewModel.destinationBookmarkTaskForTesting?.value

        let saveCount = await persistence.saveCallCount(for: .destination)
        XCTAssertEqual(saveCount, 1)
        let sourceStored = await persistence.isStored(role: .source)
        XCTAssertFalse(sourceStored, "Selecting Destination must never persist anything under Source.")
    }

    func testLateSourceSaveCannotOverwriteNewerSelectionOnRelaunch() async throws {
        let sourceA = try makeBookmarkTestDirectory(name: "ordering-source-a")
        let sourceB = try makeBookmarkTestDirectory(name: "ordering-source-b")
        defer {
            try? FileManager.default.removeItem(at: sourceA)
            try? FileManager.default.removeItem(at: sourceB)
        }
        let persistence = FakeBookmarkPersisting()
        let gate = TerminalTailAsyncGate()
        await persistence.gateSave(for: sourceA, role: .source, using: gate)
        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())

        XCTAssertTrue(viewModel.selectSourceFolder(sourceA))
        await gate.waitUntilPaused()
        XCTAssertTrue(viewModel.selectSourceFolder(sourceB))
        await viewModel.sourceBookmarkTaskForTesting?.value
        let storedSource = await persistence.storedURL(for: .source)
        XCTAssertEqual(storedSource, sourceB)
        await gate.resume()

        let relaunched = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())
        await relaunched.sourceRestoreTaskForTesting?.value
        XCTAssertEqual(relaunched.sourceURL, sourceB)
        XCTAssertNotEqual(relaunched.sourceURL, sourceA)
    }

    func testLateDestinationSaveCannotOverwriteNewerSelectionOnRelaunch() async throws {
        let destinationA = try makeBookmarkTestDirectory(name: "ordering-destination-a", withFile: false)
        let destinationB = try makeBookmarkTestDirectory(name: "ordering-destination-b", withFile: false)
        defer {
            try? FileManager.default.removeItem(at: destinationA)
            try? FileManager.default.removeItem(at: destinationB)
        }
        let persistence = FakeBookmarkPersisting()
        let gate = TerminalTailAsyncGate()
        await persistence.gateSave(for: destinationA, role: .destination, using: gate)
        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())

        XCTAssertTrue(viewModel.selectDestinationFolder(destinationA))
        await gate.waitUntilPaused()
        XCTAssertTrue(viewModel.selectDestinationFolder(destinationB))
        await viewModel.destinationBookmarkTaskForTesting?.value
        let storedDestination = await persistence.storedURL(for: .destination)
        XCTAssertEqual(storedDestination, destinationB)
        await gate.resume()

        let relaunched = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())
        await relaunched.destinationRestoreTaskForTesting?.value
        XCTAssertEqual(relaunched.destinationURL, destinationB)
        XCTAssertNotEqual(relaunched.destinationURL, destinationA)
    }

    func testInvalidSourceSelectionIsNotPersisted() async throws {
        let notAFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTBookmarkInvalidSource-\(UUID().uuidString).txt")
        try Data("not a folder".utf8).write(to: notAFolder)
        defer { try? FileManager.default.removeItem(at: notAFolder) }
        let persistence = FakeBookmarkPersisting()
        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())

        XCTAssertFalse(viewModel.selectSourceFolder(notAFolder))

        let saveCount = await persistence.saveCallCount(for: .source)
        XCTAssertEqual(saveCount, 0, "An invalid Source selection must never be persisted.")
    }

    func testInvalidDestinationSelectionIsNotPersisted() async throws {
        let notAFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTBookmarkInvalidDestination-\(UUID().uuidString).txt")
        try Data("not a folder".utf8).write(to: notAFolder)
        defer { try? FileManager.default.removeItem(at: notAFolder) }
        let persistence = FakeBookmarkPersisting()
        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())

        XCTAssertFalse(viewModel.selectDestinationFolder(notAFolder))

        let saveCount = await persistence.saveCallCount(for: .destination)
        XCTAssertEqual(saveCount, 0, "An invalid Destination selection must never be persisted.")
    }

    // MARK: - Prompt 2 FR-003 Relaunch restoration

    func testFreshViewModelRestoresSourceAndDestinationFromSameIsolatedStore() async throws {
        let source = try makeBookmarkTestDirectory(name: "restore-source")
        let destination = try makeBookmarkTestDirectory(name: "restore-destination", withFile: false)
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: destination)
        }
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .source, url: source)
        await persistence.seed(role: .destination, url: destination)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())
        await viewModel.sourceRestoreTaskForTesting?.value
        await viewModel.destinationRestoreTaskForTesting?.value
        await viewModel.sourceMetadataTaskForTesting?.value
        await viewModel.destinationMetadataTaskForTesting?.value

        XCTAssertEqual(viewModel.sourceURL, source)
        XCTAssertEqual(viewModel.destinationURL, destination)
        XCTAssertNotNil(viewModel.sourceMetadata, "Restored Source must go through the normal metadata refresh path.")
        XCTAssertNotNil(viewModel.destinationMetadata, "Restored Destination must go through the normal metadata refresh path.")
        XCTAssertEqual(viewModel.transferState, .ready, "Restoration must never start a transfer.")
    }

    func testValidSourceAndCorruptDestinationRestoresOnlySource() async throws {
        let source = try makeBookmarkTestDirectory(name: "restore-mixed-source")
        defer { try? FileManager.default.removeItem(at: source) }
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .source, url: source)
        await persistence.seedCorrupt(role: .destination)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())
        await viewModel.sourceRestoreTaskForTesting?.value
        await viewModel.destinationRestoreTaskForTesting?.value
        await viewModel.sourceMetadataTaskForTesting?.value

        XCTAssertEqual(viewModel.sourceURL, source)
        XCTAssertNil(viewModel.destinationURL)
        XCTAssertEqual(viewModel.errorMessage, "Saved Destination access could not be restored. Choose the Destination folder again.")
        let destinationRemoveCount = await persistence.removeCallCount(for: .destination)
        let sourceRemoveCount = await persistence.removeCallCount(for: .source)
        XCTAssertEqual(destinationRemoveCount, 1)
        XCTAssertEqual(sourceRemoveCount, 0, "A corrupt Destination bookmark must never affect Source.")
    }

    func testCorruptSourceAndValidDestinationRestoresOnlyDestination() async throws {
        let destination = try makeBookmarkTestDirectory(name: "restore-mixed-destination", withFile: false)
        defer { try? FileManager.default.removeItem(at: destination) }
        let persistence = FakeBookmarkPersisting()
        await persistence.seedCorrupt(role: .source)
        await persistence.seed(role: .destination, url: destination)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())
        await viewModel.sourceRestoreTaskForTesting?.value
        await viewModel.destinationRestoreTaskForTesting?.value
        await viewModel.destinationMetadataTaskForTesting?.value

        XCTAssertEqual(viewModel.destinationURL, destination)
        XCTAssertNil(viewModel.sourceURL)
        XCTAssertEqual(viewModel.errorMessage, "Saved Source access could not be restored. Choose the Source folder again.")
        let sourceRemoveCount = await persistence.removeCallCount(for: .source)
        let destinationRemoveCount = await persistence.removeCallCount(for: .destination)
        XCTAssertEqual(sourceRemoveCount, 1)
        XCTAssertEqual(destinationRemoveCount, 0, "A corrupt Source bookmark must never affect Destination.")
    }

    func testDeletedRestoredSourceFolderFailsClosedAndRemovesBookmark() async throws {
        let source = try makeBookmarkTestDirectory(name: "restore-deleted-source")
        try FileManager.default.removeItem(at: source) // simulate: folder existed at save time, gone by relaunch
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .source, url: source)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())
        await viewModel.sourceRestoreTaskForTesting?.value

        XCTAssertNil(viewModel.sourceURL)
        XCTAssertNil(viewModel.sourceMetadata)
        XCTAssertFalse(viewModel.canStartTransfer)
        XCTAssertEqual(viewModel.errorMessage, "Saved Source access could not be restored. Choose the Source folder again.")
        let removeCount = await persistence.removeCallCount(for: .source)
        XCTAssertEqual(removeCount, 1)
    }

    // MARK: - Prompt 2 FR-003 Stale bookmark behavior

    func testStaleUsableSourceBookmarkRefreshesAndRestoresSelection() async throws {
        let source = try makeBookmarkTestDirectory(name: "stale-usable-source")
        defer { try? FileManager.default.removeItem(at: source) }
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .source, url: source, isStale: true)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())
        await viewModel.sourceRestoreTaskForTesting?.value
        await viewModel.sourceMetadataTaskForTesting?.value

        XCTAssertEqual(viewModel.sourceURL, source)
        let refreshCount = await persistence.refreshCalls.count
        XCTAssertEqual(refreshCount, 1)
        let stillStored = await persistence.isStored(role: .source)
        XCTAssertTrue(stillStored, "A successful stale refresh must re-persist under the same role.")
    }

    func testStaleRefreshFailureRemovesOnlyTheBadRoleAndPreservesTheOther() async throws {
        let staleSource = try makeBookmarkTestDirectory(name: "stale-refresh-fail-source")
        let destination = try makeBookmarkTestDirectory(name: "stale-refresh-fail-destination", withFile: false)
        defer {
            try? FileManager.default.removeItem(at: staleSource)
            try? FileManager.default.removeItem(at: destination)
        }
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .source, url: staleSource, isStale: true)
        await persistence.seed(role: .destination, url: destination)
        await persistence.failRefresh(for: staleSource)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: FakeSecurityScopedAccessProvider())
        await viewModel.sourceRestoreTaskForTesting?.value
        await viewModel.destinationRestoreTaskForTesting?.value
        await viewModel.destinationMetadataTaskForTesting?.value

        XCTAssertNil(viewModel.sourceURL, "A stale bookmark whose refresh fails must not be applied.")
        XCTAssertEqual(viewModel.destinationURL, destination, "Destination restoration must be unaffected by a Source stale-refresh failure.")
        XCTAssertEqual(viewModel.errorMessage, "Saved Source access could not be restored. Choose the Source folder again.")
        let sourceRemoveCount = await persistence.removeCallCount(for: .source)
        let destinationRemoveCount = await persistence.removeCallCount(for: .destination)
        XCTAssertEqual(sourceRemoveCount, 1)
        XCTAssertEqual(destinationRemoveCount, 0)
    }

    // MARK: - Prompt 2 FR-003 Restore-vs-Select/Clear race safety

    func testManualSourceSelectionWinsOverLateRestore() async throws {
        let staleSource = try makeBookmarkTestDirectory(name: "race-select-stale-source")
        let freshSource = try makeBookmarkTestDirectory(name: "race-select-fresh-source")
        defer {
            try? FileManager.default.removeItem(at: staleSource)
            try? FileManager.default.removeItem(at: freshSource)
        }
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .source, url: staleSource)
        let access = FakeSecurityScopedAccessProvider()
        let gate = TerminalTailAsyncGate()
        await access.gateStart(for: staleSource, using: gate)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)
        let restoreTask = viewModel.sourceRestoreTaskForTesting
        await gate.waitUntilPaused()

        XCTAssertTrue(viewModel.selectSourceFolder(freshSource))
        await gate.resume()
        await restoreTask?.value
        await viewModel.sourceBookmarkTaskForTesting?.value

        XCTAssertEqual(viewModel.sourceURL, freshSource, "A manual Select issued while restore is paused must win.")
        let staleStops = await access.stopCount(for: staleSource)
        XCTAssertEqual(staleStops, 1, "The superseded restore attempt must release the access it acquired for the stale URL.")
    }

    func testManualDestinationSelectionWinsOverLateRestore() async throws {
        let staleDestination = try makeBookmarkTestDirectory(name: "race-select-stale-destination", withFile: false)
        let freshDestination = try makeBookmarkTestDirectory(name: "race-select-fresh-destination", withFile: false)
        defer {
            try? FileManager.default.removeItem(at: staleDestination)
            try? FileManager.default.removeItem(at: freshDestination)
        }
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .destination, url: staleDestination)
        let access = FakeSecurityScopedAccessProvider()
        let gate = TerminalTailAsyncGate()
        await access.gateStart(for: staleDestination, using: gate)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)
        let restoreTask = viewModel.destinationRestoreTaskForTesting
        await gate.waitUntilPaused()

        XCTAssertTrue(viewModel.selectDestinationFolder(freshDestination))
        await gate.resume()
        await restoreTask?.value
        await viewModel.destinationBookmarkTaskForTesting?.value

        XCTAssertEqual(viewModel.destinationURL, freshDestination, "A manual Select issued while restore is paused must win.")
        let staleStops = await access.stopCount(for: staleDestination)
        XCTAssertEqual(staleStops, 1, "The superseded restore attempt must release the access it acquired for the stale URL.")
    }

    func testClearSourceWinsOverLateRestore() async throws {
        let staleSource = try makeBookmarkTestDirectory(name: "race-clear-stale-source")
        defer { try? FileManager.default.removeItem(at: staleSource) }
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .source, url: staleSource)
        let access = FakeSecurityScopedAccessProvider()
        let gate = TerminalTailAsyncGate()
        await access.gateStart(for: staleSource, using: gate)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)
        let restoreTask = viewModel.sourceRestoreTaskForTesting
        await gate.waitUntilPaused()

        viewModel.clearSourceFolder()
        await gate.resume()
        await restoreTask?.value

        XCTAssertNil(viewModel.sourceURL, "A Clear issued while restore is paused must never be repopulated by the late restore.")
        let staleStops = await access.stopCount(for: staleSource)
        XCTAssertEqual(staleStops, 1, "The abandoned restore attempt must release the access it acquired.")
    }

    func testClearDestinationWinsOverLateRestore() async throws {
        let staleDestination = try makeBookmarkTestDirectory(name: "race-clear-stale-destination", withFile: false)
        defer { try? FileManager.default.removeItem(at: staleDestination) }
        let persistence = FakeBookmarkPersisting()
        await persistence.seed(role: .destination, url: staleDestination)
        let access = FakeSecurityScopedAccessProvider()
        let gate = TerminalTailAsyncGate()
        await access.gateStart(for: staleDestination, using: gate)

        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)
        let restoreTask = viewModel.destinationRestoreTaskForTesting
        await gate.waitUntilPaused()

        viewModel.clearDestinationFolder()
        await gate.resume()
        await restoreTask?.value

        XCTAssertNil(viewModel.destinationURL, "A Clear issued while restore is paused must never be repopulated by the late restore.")
        let staleStops = await access.stopCount(for: staleDestination)
        XCTAssertEqual(staleStops, 1, "The abandoned restore attempt must release the access it acquired.")
    }

    // MARK: - Prompt 2 FR-003 Clear integration

    func testClearSourceRemovesPersistenceAndReleasesAccessExactlyOncePreservingDestination() async throws {
        let source = try makeBookmarkTestDirectory(name: "clear-source-integration")
        let destination = try makeBookmarkTestDirectory(name: "clear-source-integration-destination", withFile: false)
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: destination)
        }
        let persistence = FakeBookmarkPersisting()
        let access = FakeSecurityScopedAccessProvider()
        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)

        XCTAssertTrue(viewModel.selectSourceFolder(source))
        await viewModel.sourceBookmarkTaskForTesting?.value
        XCTAssertTrue(viewModel.selectDestinationFolder(destination))
        await viewModel.destinationBookmarkTaskForTesting?.value

        viewModel.clearSourceFolder()
        // Deterministic settle: the release/removal Task has no externally
        // observable completion signal, so yield until the actor-hop work
        // finishes — bounded, not a correctness-by-sleep mechanism.
        for _ in 0..<50 {
            let removed = await persistence.removeCallCount(for: .source)
            if removed > 0 { break }
            await Task.yield()
        }

        XCTAssertNil(viewModel.sourceURL)
        XCTAssertEqual(viewModel.destinationURL, destination, "Clearing Source must never affect Destination.")
        let sourceRemoveCount = await persistence.removeCallCount(for: .source)
        XCTAssertEqual(sourceRemoveCount, 1)
        let sourceStops = await access.stopCount(for: source)
        XCTAssertEqual(sourceStops, 1)
        let destinationStops = await access.stopCount(for: destination)
        XCTAssertEqual(destinationStops, 0)
        // The real folders are never touched.
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
    }

    func testClearDestinationRemovesPersistenceAndReleasesAccessExactlyOncePreservingSource() async throws {
        let source = try makeBookmarkTestDirectory(name: "clear-destination-integration-source")
        let destination = try makeBookmarkTestDirectory(name: "clear-destination-integration", withFile: false)
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: destination)
        }
        let persistence = FakeBookmarkPersisting()
        let access = FakeSecurityScopedAccessProvider()
        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)

        XCTAssertTrue(viewModel.selectSourceFolder(source))
        await viewModel.sourceBookmarkTaskForTesting?.value
        XCTAssertTrue(viewModel.selectDestinationFolder(destination))
        await viewModel.destinationBookmarkTaskForTesting?.value

        viewModel.clearDestinationFolder()
        for _ in 0..<50 {
            let removed = await persistence.removeCallCount(for: .destination)
            if removed > 0 { break }
            await Task.yield()
        }

        XCTAssertNil(viewModel.destinationURL)
        XCTAssertEqual(viewModel.sourceURL, source, "Clearing Destination must never affect Source.")
        let destinationRemoveCount = await persistence.removeCallCount(for: .destination)
        XCTAssertEqual(destinationRemoveCount, 1)
        let destinationStops = await access.stopCount(for: destination)
        XCTAssertEqual(destinationStops, 1)
        let sourceStops = await access.stopCount(for: source)
        XCTAssertEqual(sourceStops, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
    }

    // MARK: - Prompt 2 FR-003 Replacement lifecycle

    func testReplacingSourceReleasesOldAccessExactlyOnceAndPreservesDestination() async throws {
        let oldSource = try makeBookmarkTestDirectory(name: "replace-lifecycle-old-source")
        let newSource = try makeBookmarkTestDirectory(name: "replace-lifecycle-new-source")
        let destination = try makeBookmarkTestDirectory(name: "replace-lifecycle-destination", withFile: false)
        defer {
            try? FileManager.default.removeItem(at: oldSource)
            try? FileManager.default.removeItem(at: newSource)
            try? FileManager.default.removeItem(at: destination)
        }
        let persistence = FakeBookmarkPersisting()
        let access = FakeSecurityScopedAccessProvider()
        let viewModel = makeViewModel(persistence: persistence, accessProvider: access)

        XCTAssertTrue(viewModel.selectDestinationFolder(destination))
        await viewModel.destinationBookmarkTaskForTesting?.value
        XCTAssertTrue(viewModel.selectSourceFolder(oldSource))
        await viewModel.sourceBookmarkTaskForTesting?.value
        let oldSourceStartsBeforeReplace = await access.startCount(for: oldSource)
        XCTAssertEqual(oldSourceStartsBeforeReplace, 1)

        XCTAssertTrue(viewModel.selectSourceFolder(newSource))
        await viewModel.sourceBookmarkTaskForTesting?.value

        XCTAssertEqual(viewModel.sourceURL, newSource)
        let oldSourceStops = await access.stopCount(for: oldSource)
        XCTAssertEqual(oldSourceStops, 1, "Replacing Source must balance exactly the old Source lease.")
        let newSourceStarts = await access.startCount(for: newSource)
        XCTAssertEqual(newSourceStarts, 1)
        let destinationStops = await access.stopCount(for: destination)
        XCTAssertEqual(destinationStops, 0, "Replacing Source must never touch the Destination lease.")
        XCTAssertEqual(viewModel.destinationURL, destination)
    }

    private func makeViewModel(notificationService: NotificationService? = nil) -> TransferViewModel {
        let notificationCoordinator = NotificationCoordinator(
            service: notificationService ?? RuntimeMockNotificationService()
        )

        return TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil),
            notificationCoordinator: notificationCoordinator
        )
    }

    /// ViewModel whose bundled-rsync resolution succeeds against a fake
    /// executable that answers `--version` canonically. Used by Clear tests
    /// that assert Start eligibility (canStartTransfer requires bundled
    /// rsync availability). The availability flag is assigned directly
    /// (established pattern); the async refresh resolves to the same
    /// available value, so the assignment is deterministic either way.
    private func makeViewModelWithBundledRsync(fakeRsyncURL: URL) -> TransferViewModel {
        let viewModel = TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: fakeRsyncURL),
            notificationCoordinator: NotificationCoordinator(service: RuntimeMockNotificationService())
        )
        viewModel.bundledRsyncInfo = BundledRsyncInfo(
            executableURL: fakeRsyncURL,
            version: BundledRsyncService.bundledVersion,
            diagnostics: []
        )
        return viewModel
    }

    /// ViewModel with explicit, deterministic bookmark persistence/access
    /// doubles injected — never touches `UserDefaults` or a real
    /// security-scope syscall.
    private func makeViewModel(
        persistence: BookmarkPersisting,
        accessProvider: SecurityScopedAccessing,
        fakeRsyncURL: URL? = nil
    ) -> TransferViewModel {
        let viewModel = TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: fakeRsyncURL),
            bookmarkPersistence: persistence,
            bookmarkAccessProvider: accessProvider,
            notificationCoordinator: NotificationCoordinator(service: RuntimeMockNotificationService())
        )
        if let fakeRsyncURL {
            viewModel.bundledRsyncInfo = BundledRsyncInfo(
                executableURL: fakeRsyncURL,
                version: BundledRsyncService.bundledVersion,
                diagnostics: []
            )
        }
        return viewModel
    }

    @discardableResult
    private func makeBookmarkTestDirectory(name: String, withFile: Bool = true) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTBookmark-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        if withFile {
            try Data("media".utf8).write(to: url.appendingPathComponent("A001_C001.mov"))
        }
        return url
    }

    private func writeFakeRsyncScript(at url: URL) throws {
        // Answers --version canonically so BundledRsyncService resolves it as
        // rsync 3.4.4, then (for copy runs) touches a marker file inside the
        // destination argument and never exits on its own — a deterministic
        // stand-in for an active copy that only cancellation can stop.
        let script = """
        #!/bin/sh
        if [ "$1" = "--version" ]; then
            echo "rsync version 3.4.4 protocol version 31"
            exit 0
        fi
        destination=""
        for arg in "$@"; do
            destination="$arg"
        done
        touch "${destination}.fst-fake-rsync-started" 2>/dev/null || true
        while true; do :; done
        """
        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    /// Answers `--version` canonically, then performs a real recursive copy
    /// of the source folder into the destination argument and exits 0 — a
    /// deterministic stand-in for a successful rsync run. Because the copy is
    /// byte-for-byte real (not simulated), VerifyEngine hash comparison has
    /// genuine matching content to check, letting full-workflow Retry tests
    /// reach a real `.safeToFormat`/`.copyComplete` outcome.
    private func writeSucceedingFakeRsyncScript(at url: URL) throws {
        let script = """
        #!/bin/sh
        if [ "$1" = "--version" ]; then
            echo "rsync version 3.4.4 protocol version 31"
            exit 0
        fi
        prev=""
        cur=""
        for arg in "$@"; do
            prev="$cur"
            cur="$arg"
        done
        src="$prev"
        dest="$cur"
        mkdir -p "$dest"
        cp -R "$src" "$dest"
        exit 0
        """
        try script.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    private func waitForFile(at url: URL) async throws {
        for _ in 0..<100 {
            if FileManager.default.fileExists(atPath: url.path) {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for file: \(url.path)")
    }

    private func waitForState(_ expected: TransferState, in recorder: CancelTestRecorder) async throws {
        for _ in 0..<100 {
            if recorder.snapshotStates().contains(expected) {
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for state \(expected).")
    }

    private func waitForViewModelState(_ expected: TransferState, on viewModel: TransferViewModel) async throws {
        for _ in 0..<100 {
            if viewModel.transferState == expected {
                return
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for ViewModel state \(expected).")
    }

    private func waitForTelegramTestSendToFinish(_ viewModel: TransferViewModel) async throws {
        for _ in 0..<30 {
            if !viewModel.isSendingTelegramTestMessage {
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTFail("Timed out waiting for Telegram test send to finish.")
    }

    private func waitForSendCount(_ service: RuntimeMockNotificationService, expectedCount: Int) async throws {
        for _ in 0..<30 {
            if await service.sendCount() == expectedCount {
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTFail("Timed out waiting for Telegram send count \(expectedCount).")
    }

    /// Issues two `startTransfer` requests back-to-back with no suspension
    /// point between them (an `isolated` actor parameter guarantees both
    /// calls run synchronously on the Coordinator's executor), the strongest
    /// possible proof that admission is a single atomic reservation and not
    /// something a race could split across two winners.
    private func issueTwoImmediateStartAttempts(
        on coordinator: isolated TransferCoordinator,
        source: URL,
        destination: URL
    ) -> (first: Bool, second: Bool) {
        let first = coordinator.startTransfer(source: source, destination: destination, bandwidthLimit: nil, mode: .none)
        let second = coordinator.startTransfer(source: source, destination: destination, bandwidthLimit: nil, mode: .none)
        return (first, second)
    }
}

actor TerminalTailAsyncGate {
    private var isPaused = false
    private var hasPaused = false
    private var pauseWaiter: CheckedContinuation<Void, Never>?
    private var resumeWaiter: CheckedContinuation<Void, Never>?

    func pause() async {
        guard !hasPaused else { return }
        hasPaused = true
        isPaused = true
        pauseWaiter?.resume()
        pauseWaiter = nil
        await withCheckedContinuation { resumeWaiter = $0 }
    }

    func waitUntilPaused() async {
        if isPaused { return }
        await withCheckedContinuation { pauseWaiter = $0 }
    }

    func resume() {
        resumeWaiter?.resume()
        resumeWaiter = nil
    }
}

private final class RuntimeMockNotificationService: NotificationService, @unchecked Sendable {
    private let counter = RuntimeSendCounter()
    private let delayNanoseconds: UInt64
    private let error: Error?

    init(delayNanoseconds: UInt64 = 0, error: Error? = nil) {
        self.delayNanoseconds = delayNanoseconds
        self.error = error
    }

    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        await counter.increment()

        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        if let error {
            throw error
        }
    }

    func sendCount() async -> Int {
        await counter.value()
    }
}

private actor RuntimeSendCounter {
    private var count = 0

    func increment() {
        count += 1
    }

    func value() -> Int {
        count
    }
}

private final class CancelTestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var states: [TransferState] = []
    private var logMessages: [String] = []

    func appendState(_ state: TransferState) {
        lock.lock()
        states.append(state)
        lock.unlock()
    }

    func appendLog(_ log: LogEntry) {
        lock.lock()
        logMessages.append(log.message)
        lock.unlock()
    }

    func snapshotStates() -> [TransferState] {
        lock.lock()
        let snapshot = states
        lock.unlock()
        return snapshot
    }

    func snapshotLogMessages() -> [String] {
        lock.lock()
        let snapshot = logMessages
        lock.unlock()
        return snapshot
    }
}

// MARK: - FR-003 bookmark test doubles

/// Deterministic in-memory stand-in for `BookmarkPersisting`. Never touches
/// `UserDefaults`, so it can never write into the user's production defaults
/// domain. Lets tests seed usable/stale/corrupt starting state per role and
/// force save/refresh failures for specific URLs.
actor FakeBookmarkPersisting: BookmarkPersisting {
    private struct Stored {
        var url: URL
        var isStale: Bool
    }

    private var stored: [BookmarkRole: Stored] = [:]
    private var corruptRoles: Set<BookmarkRole> = []
    private var saveFailureURLs: Set<URL> = []
    private var refreshFailureURLs: Set<URL> = []
    private var latestGeneration: [BookmarkRole: Int] = [:]
    private var gatedSaveURL: URL?
    private var gatedSaveRole: BookmarkRole?
    private var saveGate: TerminalTailAsyncGate?
    private(set) var saveCalls: [(url: URL, role: BookmarkRole)] = []
    private(set) var refreshCalls: [(url: URL, role: BookmarkRole)] = []
    private(set) var removeCalls: [BookmarkRole] = []

    func seed(role: BookmarkRole, url: URL, isStale: Bool = false) {
        stored[role] = Stored(url: url, isStale: isStale)
    }

    func seedCorrupt(role: BookmarkRole) {
        corruptRoles.insert(role)
    }

    func failSave(for url: URL) {
        saveFailureURLs.insert(url)
    }

    func failRefresh(for url: URL) {
        refreshFailureURLs.insert(url)
    }

    func gateSave(for url: URL, role: BookmarkRole, using gate: TerminalTailAsyncGate) {
        gatedSaveURL = url
        gatedSaveRole = role
        saveGate = gate
    }

    func saveBookmark(for url: URL, role: BookmarkRole, generation: Int) async -> Bool {
        saveCalls.append((url, role))
        if gatedSaveURL == url, gatedSaveRole == role, let saveGate {
            await saveGate.pause()
        }
        guard generation >= (latestGeneration[role] ?? Int.min) else { return false }
        latestGeneration[role] = generation
        guard !saveFailureURLs.contains(url) else { return false }
        stored[role] = Stored(url: url, isStale: false)
        return true
    }

    func resolveBookmark(for role: BookmarkRole) async -> BookmarkResolution {
        if corruptRoles.contains(role) { return .corrupt }
        guard let entry = stored[role] else { return .none }
        return .usable(url: entry.url, wasStale: entry.isStale)
    }

    func refreshBookmark(for url: URL, role: BookmarkRole, generation: Int) async -> Bool {
        refreshCalls.append((url, role))
        guard generation >= (latestGeneration[role] ?? Int.min) else { return false }
        latestGeneration[role] = generation
        guard !refreshFailureURLs.contains(url) else { return false }
        stored[role] = Stored(url: url, isStale: false)
        return true
    }

    func removeBookmark(for role: BookmarkRole, generation: Int) async {
        guard generation >= (latestGeneration[role] ?? Int.min) else { return }
        latestGeneration[role] = generation
        removeCalls.append(role)
        stored[role] = nil
        corruptRoles.remove(role)
    }

    func removeCallCount(for role: BookmarkRole) -> Int {
        removeCalls.filter { $0 == role }.count
    }

    func saveCallCount(for role: BookmarkRole) -> Int {
        saveCalls.filter { $0.role == role }.count
    }

    func isStored(role: BookmarkRole) -> Bool {
        stored[role] != nil
    }

    func storedURL(for role: BookmarkRole) -> URL? {
        stored[role]?.url
    }
}

/// Deterministic stand-in for `SecurityScopedAccessing`. Records start/stop
/// counts per URL, can be told to fail a specific URL's start, and can gate
/// a specific URL's start call on a `TerminalTailAsyncGate` so restore-vs-
/// Select/Clear races are reproducible without any wall-clock wait.
actor FakeSecurityScopedAccessProvider: SecurityScopedAccessing {
    private var startCounts: [URL: Int] = [:]
    private var stopCounts: [URL: Int] = [:]
    private var failToStartURLs: Set<URL> = []
    private var gatedURL: URL?
    private var gate: TerminalTailAsyncGate?

    func failToStart(for url: URL) {
        failToStartURLs.insert(url)
    }

    func gateStart(for url: URL, using gate: TerminalTailAsyncGate) {
        gatedURL = url
        self.gate = gate
    }

    func startAccessing(_ url: URL) async -> Bool {
        startCounts[url, default: 0] += 1
        if gatedURL == url, let gate {
            await gate.pause()
        }
        return !failToStartURLs.contains(url)
    }

    func stopAccessing(_ url: URL) async {
        stopCounts[url, default: 0] += 1
    }

    func startCount(for url: URL) -> Int { startCounts[url] ?? 0 }
    func stopCount(for url: URL) -> Int { stopCounts[url] ?? 0 }
}
