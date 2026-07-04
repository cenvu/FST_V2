// FST / CenVu | (+84) 842 841 222

import XCTest

final class RsyncEngineTests: XCTestCase {
    
    func testProgressParserPercentages() {
        let parser = ProgressParser()
        let result = parser.parse(line: "12,451,023,872  48%  118.34MB/s  0:03:12")
        
        XCTAssertEqual(result?.progress, 48.0)
        XCTAssertEqual(result?.speedMBps, 118.34)
    }
    
    func testProgressParserMultipleSpeedUnits() {
        let parser = ProgressParser()
        
        // KB/s
        let resultKB = parser.parse(line: "10,000  10%  1024.00kB/s  0:00:10")
        XCTAssertEqual(resultKB?.speedMBps, 1.0)
        
        // GB/s
        let resultGB = parser.parse(line: "50,000,000,000  90%  1.50GB/s  0:00:01")
        XCTAssertEqual(resultGB?.speedMBps, 1536.0)
    }
    
    func testProgressParserETAMinuteFormat() {
        let parser = ProgressParser()
        let result = parser.parse(line: "12,451,023  48%  118.34MB/s  0:03:12") // 0:03:12
        
        XCTAssertEqual(result?.eta, 192) // 3 mins * 60 + 12
    }
    
    func testProgressParserETAHourFormat() {
        let parser = ProgressParser()
        let result = parser.parse(line: "12,451,023  48%  118.34MB/s  1:05:10") // 1:05:10
        
        XCTAssertEqual(result?.eta, 3910) // 3600 + (5 * 60) + 10
    }
    
    func testMalformedLinesIgnored() {
        let parser = ProgressParser()
        
        XCTAssertNil(parser.parse(line: "building file list..."))
        XCTAssertNil(parser.parse(line: "sending incremental file list"))
        XCTAssertNil(parser.parse(line: "A001_C004_0614AB.mov"))
        XCTAssertNil(parser.parse(line: "12345 5%")) // Missing elements
    }
    
    func testRsyncCancellation() async throws {
        let engine = RsyncEngine()
        let fm = FileManager.default
        let sourceURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let destURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try fm.createDirectory(at: sourceURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: destURL, withIntermediateDirectories: true)
        
        // Create a large dummy file to give rsync something to do
        let testFile = sourceURL.appendingPathComponent("large.bin")
        let dummyData = Data(count: 10_000_000) // 10MB
        try dummyData.write(to: testFile)
        
        defer {
            try? fm.removeItem(at: sourceURL)
            try? fm.removeItem(at: destURL)
        }
        
        let expectation = XCTestExpectation(description: "Transfer Cancelled")
        var events: [TransferEvent] = []
        
        let request = TransferRequest(sourceURL: sourceURL, destinationURL: destURL, bandwidthLimit: 100) // 100 KB/s so it's slow
        
        Task {
            await engine.startTransfer(request: request) { event in
                events.append(event)
                if event == .cancelled {
                    expectation.fulfill()
                }
            }
        }
        
        // Wait briefly for transfer to start
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Calling cancel should resolve immediately without dedlocking since startTransfer does not block thread
        await engine.cancel()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(events.contains(.cancelled))
        XCTAssertFalse(events.contains(.completed))
    }
}
