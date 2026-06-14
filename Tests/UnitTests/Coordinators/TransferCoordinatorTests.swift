import XCTest

@MainActor
final class TransferCoordinatorTests: XCTestCase {
    
    func testValidationFailureTransitionsToError() async {
        let coordinator = TransferCoordinator()
        
        let invalidSource = URL(fileURLWithPath: "/NonExistentSource123")
        let dest = FileManager.default.temporaryDirectory
        
        let expectation = XCTestExpectation(description: "Validation fails and transitions to error")
        var states: [TransferState] = []
        
        coordinator.onStateChanged = { state in
            states.append(state)
            if state == .error {
                expectation.fulfill()
            }
        }
        
        coordinator.startTransfer(source: invalidSource, destination: dest, bandwidthLimit: nil, mode: .none)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(states.contains(.validating))
        XCTAssertTrue(states.contains(.error))
        XCTAssertFalse(states.contains(.copying))
        XCTAssertFalse(states.contains(.safeToFormat))
    }
    
    func testStateTransitionsWithNoVerification() async throws {
        let fm = FileManager.default
        let sourceURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let destURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try fm.createDirectory(at: sourceURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: destURL, withIntermediateDirectories: true)
        
        let testFile = sourceURL.appendingPathComponent("test.txt")
        try "test data".write(to: testFile, atomically: true, encoding: .utf8)
        
        defer {
            try? fm.removeItem(at: sourceURL)
            try? fm.removeItem(at: destURL)
        }
        
        let coordinator = TransferCoordinator()
        let expectation = XCTestExpectation(description: "Transfer completes without verification")
        var states: [TransferState] = []
        
        coordinator.onStateChanged = { state in
            states.append(state)
            if state == .copyComplete || state == .error {
                expectation.fulfill()
            }
        }
        
        coordinator.startTransfer(source: sourceURL, destination: destURL, bandwidthLimit: nil, mode: .none)
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        XCTAssertTrue(states.contains(.validating))
        XCTAssertTrue(states.contains(.copying))
        XCTAssertTrue(states.contains(.copyComplete))
        // Absolute Rule: Mode None MUST NEVER reach .safeToFormat
        XCTAssertFalse(states.contains(.safeToFormat))
        XCTAssertEqual(coordinator.state, .copyComplete)
    }

    func testSafeToFormatRuleWithFullVerification() async throws {
        let fm = FileManager.default
        let sourceURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let destURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try fm.createDirectory(at: sourceURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: destURL, withIntermediateDirectories: true)
        
        let testFile = sourceURL.appendingPathComponent("test.txt")
        try "test data".write(to: testFile, atomically: true, encoding: .utf8)
        
        defer {
            try? fm.removeItem(at: sourceURL)
            try? fm.removeItem(at: destURL)
        }
        
        let coordinator = TransferCoordinator()
        let expectation = XCTestExpectation(description: "Transfer verification completes safely")
        var states: [TransferState] = []
        
        coordinator.onStateChanged = { state in
            states.append(state)
            if state == .safeToFormat || state == .error {
                expectation.fulfill()
            }
        }
        
        coordinator.startTransfer(source: sourceURL, destination: destURL, bandwidthLimit: nil, mode: .full)
        
        await fulfillment(of: [expectation], timeout: 15.0)
        
        XCTAssertTrue(states.contains(.validating))
        XCTAssertTrue(states.contains(.copying))
        XCTAssertTrue(states.contains(.verifying))
        // Confirm SAFE_TO_FORMAT is strictly reached
        XCTAssertTrue(states.contains(.safeToFormat))
        XCTAssertEqual(coordinator.state, .safeToFormat)
    }
}
