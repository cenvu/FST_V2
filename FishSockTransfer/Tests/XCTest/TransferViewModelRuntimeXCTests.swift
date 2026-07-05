// FST / CenVu | (+84) 842 841 222

import XCTest

@MainActor
final class TransferViewModelRuntimeXCTests: XCTestCase {
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

    private func makeViewModel(notificationService: NotificationService? = nil) -> TransferViewModel {
        let notificationCoordinator = NotificationCoordinator(
            service: notificationService ?? RuntimeMockNotificationService()
        )

        return TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil),
            notificationCoordinator: notificationCoordinator
        )
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
