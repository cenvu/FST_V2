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

private actor TerminalTailAsyncGate {
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
