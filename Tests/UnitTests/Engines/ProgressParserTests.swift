import XCTest

final class ProgressParserTests: XCTestCase {
    func testParseProgress() {
        let parser = ProgressParser()
        let result = parser.parse(line: "12,451,023,872  48%  118.34MB/s  0:03:12")
        XCTAssertEqual(result?.progress, 48.0)
        XCTAssertEqual(result?.speedMBps, 118.34)
        XCTAssertEqual(result?.eta, 192)
    }
    
    func testParseMalformedLine() {
        let parser = ProgressParser()
        XCTAssertNil(parser.parse(line: "building file list..."))
    }
}
