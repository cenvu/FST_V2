import XCTest

final class ProgressParserXCTests: XCTestCase {
    func testParsesKilobytesPerSecond() throws {
        let data = try XCTUnwrap(ProgressParser().parse(line: "        1,024   1%  512.00kB/s    0:00:10"))
        XCTAssertEqual(data.progress, 1.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 0.5, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 10.0, accuracy: 0.0001)
    }

    func testParsesMegabytesPerSecond() throws {
        let data = try XCTUnwrap(ProgressParser().parse(line: "1,245,890,560  48%  120.34MB/s    0:01:30"))
        XCTAssertEqual(data.progress, 48.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 120.34, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 90.0, accuracy: 0.0001)
    }

    func testParsesGigabytesPerSecond() throws {
        let data = try XCTUnwrap(ProgressParser().parse(line: "9,876,543,210  75%  1.50GB/s    0:00:03"))
        XCTAssertEqual(data.progress, 75.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 1536.0, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 3.0, accuracy: 0.0001)
    }

    func testParsesHumanReadableByteCounts() throws {
        let parser = ProgressParser()
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "32.77K  3%  512.00kB/s    0:00:10")).progress, 3.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "524.29K  7%  1.00MB/s    0:00:09")).progress, 7.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "1.23M  12%  4.00MB/s    0:00:08")).progress, 12.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "9.87G  88%  1.50GB/s    0:00:07")).progress, 88.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "1.00T  91%  900.00MB/s    0:00:06")).progress, 91.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "512K  6%  2.00MB/s    0:00:05")).progress, 6.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "1,024  1%  512.00kB/s    0:00:10")).progress, 1.0)
    }

    func testParsesETAFields() throws {
        let data = try XCTUnwrap(ProgressParser().parse(line: "10,000,000  25%  10.00MB/s    1:02:03"))
        XCTAssertEqual(data.eta, 3723.0, accuracy: 0.0001)
    }

    func testParsesCarriageReturnDelimitedRecordsWithHumanReadableByteCounts() throws {
        let line = "32.77K  10%  1.00MB/s    0:00:09\r1.23M  20%  2.00MB/s    0:00:08"
        let data = try XCTUnwrap(ProgressParser().parse(line: line))
        XCTAssertEqual(data.progress, 20.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 2.0, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 8.0, accuracy: 0.0001)
    }

    func testRejectsArbitraryFilenameTextContainingPercent() {
        let parser = ProgressParser()
        XCTAssertNil(parser.parse(line: "A001_100%_clip.mov"))
        XCTAssertNil(parser.parse(line: "clip 100% done.mov 0:00:01"))
        XCTAssertNil(parser.parse(line: "1,024 100% done.mov 0:00:01"))
        XCTAssertNil(parser.parse(line: "clip.mov 100% 1.00MB/s 0:00:01"))
    }

    func testRejectsMalformedHumanReadableByteCounts() {
        let parser = ProgressParser()
        XCTAssertNil(parser.parse(line: "32.K  12%  1.00MB/s    0:00:01"))
        XCTAssertNil(parser.parse(line: ".32K  12%  1.00MB/s    0:00:01"))
        XCTAssertNil(parser.parse(line: "1.2.3M  12%  1.00MB/s    0:00:01"))
        XCTAssertNil(parser.parse(line: "32.77KB  12%  1.00MB/s    0:00:01"))
        XCTAssertNil(parser.parse(line: "K32  12%  1.00MB/s    0:00:01"))
        XCTAssertNil(parser.parse(line: "32,77K  12%  1.00MB/s    0:00:01"))
        XCTAssertNil(parser.parse(line: "1,,024  12%  1.00MB/s    0:00:01"))
    }

    func testActiveCopyProgressClampsPrematureHundredPercent() throws {
        let data = try XCTUnwrap(ProgressParser().parse(line: "9.87G  100%  1.50GB/s    0:00:00"))
        XCTAssertEqual(data.progress, 100.0, accuracy: 0.0001)
        XCTAssertEqual(ProgressParser.activeCopyProgress(data.progress), 99.0, accuracy: 0.0001)
        XCTAssertEqual(ProgressParser.activeCopyProgress(98.8), 98.8, accuracy: 0.0001)
        XCTAssertEqual(ProgressParser.activeCopyProgress(150.0), 99.0, accuracy: 0.0001)
        XCTAssertEqual(ProgressParser.activeCopyProgress(-1.0), 0.0, accuracy: 0.0001)
        XCTAssertEqual(ProgressParser.completedCopyProgress, 100.0)
        XCTAssertNotEqual(ProgressParser.activeCopyProgress(100.0), ProgressParser.completedCopyProgress)
    }
}
