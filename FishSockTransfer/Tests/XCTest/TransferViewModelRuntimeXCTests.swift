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
            "COPY STATUS"
        )
        XCTAssertEqual(
            TransferRuntimeMetricPresentation.currentFileValue(currentFile: "", state: .copying),
            "Waiting for rsync progress output..."
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

    func testProjectETAUnavailableBeforeTenSecondsElapsed() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 1_000)

        viewModel.beginCopyRuntime(at: Date(timeIntervalSince1970: 100))
        viewModel.applyTransferSpeed(10)
        viewModel.applyTransferredBytes(100, now: Date(timeIntervalSince1970: 109))

        XCTAssertEqual(viewModel.projectETA, 0, accuracy: 0.0001)
    }

    func testProjectETAUnavailableWhenSpeedIsZero() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 1_000)

        viewModel.beginCopyRuntime(at: Date(timeIntervalSince1970: 100))
        viewModel.applyTransferSpeed(0)
        viewModel.applyTransferredBytes(100, now: Date(timeIntervalSince1970: 120))

        XCTAssertEqual(viewModel.projectETA, 0, accuracy: 0.0001)
    }

    func testProjectETAUnavailableWhenSourceTotalIsZeroOrTransferredBytesMissing() {
        let viewModel = makeViewModel()

        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 0)
        viewModel.beginCopyRuntime(at: Date(timeIntervalSince1970: 100))
        viewModel.applyTransferSpeed(10)
        viewModel.applyTransferredBytes(100, now: Date(timeIntervalSince1970: 120))
        XCTAssertEqual(viewModel.projectETA, 0, accuracy: 0.0001)

        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 1_000)
        viewModel.applyTransferredBytes(nil, now: Date(timeIntervalSince1970: 121))
        XCTAssertEqual(viewModel.projectETA, 0, accuracy: 0.0001)
    }

    func testProjectETAReturnsSanePositiveValueWhenInputsAreValid() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 10 * 1024 * 1024)

        viewModel.beginCopyRuntime(at: Date(timeIntervalSince1970: 100))
        viewModel.applyTransferSpeed(2)
        viewModel.applyTransferredBytes(2 * 1024 * 1024, now: Date(timeIntervalSince1970: 120))

        XCTAssertEqual(viewModel.projectETA, 4, accuracy: 0.0001)
    }

    func testProjectETAClearsOnTransitionToVerifying() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 10 * 1024 * 1024)

        viewModel.beginCopyRuntime(at: Date(timeIntervalSince1970: 100))
        viewModel.applyTransferSpeed(2)
        viewModel.applyTransferredBytes(2 * 1024 * 1024, now: Date(timeIntervalSince1970: 120))
        XCTAssertGreaterThan(viewModel.projectETA, 0)

        viewModel.applyTransferState(.verifying)

        XCTAssertEqual(viewModel.projectETA, 0, accuracy: 0.0001)
    }

    func testProjectETAIsNotDerivedFromRsyncNativeETA() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 10 * 1024 * 1024)

        viewModel.beginCopyRuntime(at: Date(timeIntervalSince1970: 100))
        viewModel.applyTransferSpeed(2)
        viewModel.applyTransferTime(999)
        viewModel.applyTransferredBytes(2 * 1024 * 1024, now: Date(timeIntervalSince1970: 120))

        XCTAssertEqual(viewModel.eta, 999, accuracy: 0.0001)
        XCTAssertEqual(viewModel.projectETA, 4, accuracy: 0.0001)
    }

    func testEstimatedCopyTimeForFiniteBandwidthUsesSourceSizeAndSelectedLimit() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 46 * 120 * 1024 * 1024)
        viewModel.bandwidthLimit = RsyncBandwidthLimit.kibPerSecond(for: 120)

        XCTAssertEqual(viewModel.estimatedCopyTimeSeconds, 46, accuracy: 0.0001)
        XCTAssertEqual(
            TransferRuntimeMetricPresentation.estimatedCopyTimeValue(seconds: viewModel.estimatedCopyTimeSeconds),
            "~00:46"
        )
    }

    func testEstimatedCopyTimeUnavailableForUnlimitedBandwidth() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 46 * 120 * 1024 * 1024)
        viewModel.bandwidthLimit = nil

        XCTAssertEqual(viewModel.estimatedCopyTimeSeconds, 0, accuracy: 0.0001)
        XCTAssertEqual(TransferRuntimeMetricPresentation.estimatedCopyTimeValue(seconds: 0), "-")
    }

    func testEstimatedCopyTimeUnavailableWithoutSourceMetadata() {
        let viewModel = makeViewModel()
        viewModel.bandwidthLimit = RsyncBandwidthLimit.kibPerSecond(for: 120)

        XCTAssertNil(viewModel.sourceMetadata)
        XCTAssertEqual(viewModel.estimatedCopyTimeSeconds, 0, accuracy: 0.0001)
    }

    func testEstimatedCopyTimeDoesNotDependOnRsyncNativeETA() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 46 * 120 * 1024 * 1024)
        viewModel.bandwidthLimit = RsyncBandwidthLimit.kibPerSecond(for: 120)

        let estimateBeforeRsyncETA = viewModel.estimatedCopyTimeSeconds
        viewModel.applyTransferTime(999)

        XCTAssertEqual(viewModel.eta, 999, accuracy: 0.0001)
        XCTAssertEqual(viewModel.estimatedCopyTimeSeconds, estimateBeforeRsyncETA, accuracy: 0.0001)
    }

    func testEstimatedCopyTimeDoesNotAlterProjectETA() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 10 * 1024 * 1024)
        viewModel.bandwidthLimit = RsyncBandwidthLimit.kibPerSecond(for: 120)

        viewModel.beginCopyRuntime(at: Date(timeIntervalSince1970: 100))
        viewModel.applyTransferSpeed(2)
        viewModel.applyTransferredBytes(2 * 1024 * 1024, now: Date(timeIntervalSince1970: 120))

        let projectETABeforeEstimateRead = viewModel.projectETA
        XCTAssertGreaterThan(viewModel.estimatedCopyTimeSeconds, 0)
        XCTAssertEqual(viewModel.projectETA, projectETABeforeEstimateRead, accuracy: 0.0001)
    }

    func testReadyResetKeepsEstimatedCopyTimeAsPlanningValueAndClearsProjectETA() {
        let viewModel = makeViewModel()
        viewModel.sourceMetadata = sourceMetadata(totalSizeBytes: 46 * 120 * 1024 * 1024)
        viewModel.bandwidthLimit = RsyncBandwidthLimit.kibPerSecond(for: 120)

        viewModel.beginCopyRuntime(at: Date(timeIntervalSince1970: 100))
        viewModel.applyTransferSpeed(2)
        viewModel.applyTransferredBytes(2 * 1024 * 1024, now: Date(timeIntervalSince1970: 120))
        XCTAssertGreaterThan(viewModel.projectETA, 0)

        viewModel.applyTransferState(.ready)

        XCTAssertEqual(viewModel.projectETA, 0, accuracy: 0.0001)
        XCTAssertEqual(viewModel.estimatedCopyTimeSeconds, 46, accuracy: 0.0001)
        XCTAssertNotEqual(viewModel.transferState, .safeToFormat)
    }

    func testVerifyPreparingSignalTogglesUntilFirstVerificationProgress() {
        let viewModel = makeViewModel()

        viewModel.applyVerifyPreparing("Preparing verification inventory...")
        XCTAssertTrue(viewModel.isPreparingVerify)
        XCTAssertEqual(viewModel.verifyPhaseDescription, "Preparing verification inventory...")

        viewModel.applyVerifyPreparing("")
        XCTAssertFalse(viewModel.isPreparingVerify)
        XCTAssertEqual(viewModel.verifyPhaseDescription, "")
    }

    func testTerminalFailureAndCancellationDoNotBecomeSafeToEject() {
        let viewModel = makeViewModel()

        viewModel.applyTransferState(.cancelled)
        XCTAssertNotEqual(viewModel.transferState, .safeToFormat)

        viewModel.applyTransferState(.error)
        XCTAssertNotEqual(viewModel.transferState, .safeToFormat)
    }

    private func makeViewModel() -> TransferViewModel {
        TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil)
        )
    }

    private func sourceMetadata(totalSizeBytes: Int64) -> SourceStorageMetadata {
        SourceStorageMetadata(
            folderName: "CARD",
            fullPath: "/Volumes/CARD",
            totalSizeBytes: totalSizeBytes,
            fileCount: totalSizeBytes > 0 ? 1 : 0,
            folderCount: 0
        )
    }
}
