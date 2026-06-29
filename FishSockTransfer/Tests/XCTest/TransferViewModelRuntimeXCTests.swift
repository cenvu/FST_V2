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
            "COPY PROGRESS"
        )
        XCTAssertEqual(
            TransferRuntimeMetricPresentation.currentFileValue(currentFile: "", state: .copying),
            "Tracking total rsync progress"
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

    private func makeViewModel() -> TransferViewModel {
        TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil)
        )
    }
}
