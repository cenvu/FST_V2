// FST / CenVu | (+84) 842 841 222

import XCTest

final class ModelsTests: XCTestCase {
    
    func testTransferRequestInitialization() {
        let source = URL(fileURLWithPath: "/Source")
        let destination = URL(fileURLWithPath: "/Destination")
        let request = TransferRequest(sourceURL: source, destinationURL: destination, bandwidthLimit: 120000)
        
        XCTAssertEqual(request.sourceURL, source)
        XCTAssertEqual(request.destinationURL, destination)
        XCTAssertEqual(request.bandwidthLimit, 120000)
    }

    func testTransferRequestDefaultBandwidth() {
        let source = URL(fileURLWithPath: "/Source")
        let destination = URL(fileURLWithPath: "/Destination")
        let request = TransferRequest(sourceURL: source, destinationURL: destination)
        
        XCTAssertNil(request.bandwidthLimit)
    }

    func testLogEntryInitialization() {
        let entry = LogEntry(category: .info, message: "Test log message")
        
        XCTAssertEqual(entry.category, .info)
        XCTAssertEqual(entry.message, "Test log message")
        XCTAssertNotNil(entry.id)
        XCTAssertNotNil(entry.timestamp)
    }
    
    func testVerificationResultInitialization() {
        let result = VerificationResult(
            totalFiles: 100,
            verifiedFiles: 33,
            passedFiles: 33,
            failedFiles: 0,
            duration: 12.5,
            status: .passed
        )
        
        XCTAssertEqual(result.totalFiles, 100)
        XCTAssertEqual(result.verifiedFiles, 33)
        XCTAssertEqual(result.passedFiles, 33)
        XCTAssertEqual(result.failedFiles, 0)
        XCTAssertEqual(result.duration, 12.5)
        XCTAssertEqual(result.status, .passed)
    }
}
