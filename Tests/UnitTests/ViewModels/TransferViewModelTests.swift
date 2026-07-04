// FST / CenVu | (+84) 842 841 222

import XCTest

@MainActor
final class TransferViewModelTests: XCTestCase {
    
    func testInitialState() {
        let coordinator = TransferCoordinator()
        let viewModel = TransferViewModel(coordinator: coordinator)
        
        XCTAssertNil(viewModel.sourceURL)
        XCTAssertNil(viewModel.destinationURL)
        XCTAssertNil(viewModel.bandwidthLimit)
        XCTAssertEqual(viewModel.verificationMode, .random33)
        XCTAssertEqual(viewModel.transferState, .ready)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertEqual(viewModel.speed, 0.0)
        XCTAssertEqual(viewModel.eta, 0.0)
        XCTAssertTrue(viewModel.currentFile.isEmpty)
        XCTAssertTrue(viewModel.logs.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testBindingsUpdateViewModelProperties() {
        let coordinator = TransferCoordinator()
        let viewModel = TransferViewModel(coordinator: coordinator)
        
        // Simulate Coordinator State Changes
        coordinator.onStateChanged?(.copying)
        XCTAssertEqual(viewModel.transferState, .copying)
        
        coordinator.onStateChanged?(.verifying)
        XCTAssertEqual(viewModel.transferState, .verifying)
        
        // Simulate Event Metrics
        coordinator.onProgress?(45.5)
        XCTAssertEqual(viewModel.progress, 45.5)
        
        coordinator.onSpeed?(150.2)
        XCTAssertEqual(viewModel.speed, 150.2)
        
        coordinator.onETA?(345.0)
        XCTAssertEqual(viewModel.eta, 345.0)
        
        coordinator.onCurrentFile?("A001_C012_0614AB.mov")
        XCTAssertEqual(viewModel.currentFile, "A001_C012_0614AB.mov")
        
        // Simulate Error
        let testError = NSError(domain: "TestDomain", code: 99, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        coordinator.onError?(testError)
        XCTAssertEqual(viewModel.errorMessage, "Test error message")
        XCTAssertTrue(viewModel.logs.last!.contains("[ERROR] Test error message"))
    }
    
    func testStartTransferMissingURLs() {
        let coordinator = TransferCoordinator()
        let viewModel = TransferViewModel(coordinator: coordinator)
        
        viewModel.startTransfer()
        
        XCTAssertEqual(viewModel.transferState, .ready)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Please select both source and destination folders.")
    }
    
    func testResetMetricsOnReadyState() {
        let coordinator = TransferCoordinator()
        let viewModel = TransferViewModel(coordinator: coordinator)
        
        coordinator.onProgress?(99.9)
        coordinator.onSpeed?(120.0)
        
        XCTAssertEqual(viewModel.progress, 99.9)
        
        // Simulating the state shifting back to ready (e.g. starting a fresh transfer)
        coordinator.onStateChanged?(.ready)
        
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertEqual(viewModel.speed, 0.0)
    }
}
