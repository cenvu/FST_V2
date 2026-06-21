import Foundation

private func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

private func assertApproximatelyEqual(_ actual: Double, _ expected: Double, _ message: String, accuracy: Double = 0.0001) {
    guard abs(actual - expected) <= accuracy else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

private func assertNil<T>(_ actual: T?, _ message: String) {
    guard actual == nil else {
        fatalError("\(message): expected nil, got \(String(describing: actual))")
    }
}

private func assertNotNil<T>(_ actual: T?, _ message: String) -> T {
    guard let value = actual else {
        fatalError("\(message): expected value, got nil")
    }

    return value
}

@main
struct ProgressParserTests {
    static func main() {
        testParsesKilobytesPerSecond()
        testParsesMegabytesPerSecond()
        testParsesGigabytesPerSecond()
        testParsesETAFields()
        testParsesCarriageReturnDelimitedRecords()
        testRejectsArbitraryFilenameTextContainingPercent()
        testActiveCopyProgressClampsPrematureHundredPercent()
        testCompletedCopyProgressIsOnlyFinalHundredConstant()

        print("ProgressParserTests passed")
    }

    private static func testParsesKilobytesPerSecond() {
        let data = assertNotNil(
            ProgressParser().parse(line: "        1,024   1%  512.00kB/s    0:00:10"),
            "kB/s progress2 line"
        )

        assertApproximatelyEqual(data.progress, 1.0, "kB/s progress")
        assertApproximatelyEqual(data.speedMBps, 0.5, "kB/s speed conversion")
        assertApproximatelyEqual(data.eta, 10.0, "kB/s ETA")
    }

    private static func testParsesMegabytesPerSecond() {
        let data = assertNotNil(
            ProgressParser().parse(line: "1,245,890,560  48%  120.34MB/s    0:01:30"),
            "MB/s progress2 line"
        )

        assertApproximatelyEqual(data.progress, 48.0, "MB/s progress")
        assertApproximatelyEqual(data.speedMBps, 120.34, "MB/s speed conversion")
        assertApproximatelyEqual(data.eta, 90.0, "MB/s ETA")
    }

    private static func testParsesGigabytesPerSecond() {
        let data = assertNotNil(
            ProgressParser().parse(line: "9,876,543,210  75%  1.50GB/s    0:00:03"),
            "GB/s progress2 line"
        )

        assertApproximatelyEqual(data.progress, 75.0, "GB/s progress")
        assertApproximatelyEqual(data.speedMBps, 1536.0, "GB/s speed conversion")
        assertApproximatelyEqual(data.eta, 3.0, "GB/s ETA")
    }

    private static func testParsesETAFields() {
        let data = assertNotNil(
            ProgressParser().parse(line: "10,000,000  25%  10.00MB/s    1:02:03"),
            "hour ETA progress2 line"
        )

        assertApproximatelyEqual(data.eta, 3723.0, "hour ETA conversion")
    }

    private static func testParsesCarriageReturnDelimitedRecords() {
        let line = "1,024  10%  1.00MB/s    0:00:09\r2,048  20%  2.00MB/s    0:00:08"
        let data = assertNotNil(ProgressParser().parse(line: line), "carriage-return progress records")

        assertApproximatelyEqual(data.progress, 20.0, "latest carriage-return progress")
        assertApproximatelyEqual(data.speedMBps, 2.0, "latest carriage-return speed")
        assertApproximatelyEqual(data.eta, 8.0, "latest carriage-return ETA")
    }

    private static func testRejectsArbitraryFilenameTextContainingPercent() {
        let parser = ProgressParser()

        assertNil(parser.parse(line: "A001_100%_clip.mov"), "filename percent without progress fields")
        assertNil(parser.parse(line: "clip 100% done.mov 0:00:01"), "filename text with percent token")
        assertNil(parser.parse(line: "1,024 100% done.mov 0:00:01"), "progress-shaped filename text without speed")
    }

    private static func testActiveCopyProgressClampsPrematureHundredPercent() {
        assertApproximatelyEqual(ProgressParser.activeCopyProgress(98.8), 98.8, "active progress below clamp")
        assertApproximatelyEqual(ProgressParser.activeCopyProgress(100.0), 99.0, "active progress clamps 100 below rounded final display")
        assertApproximatelyEqual(ProgressParser.activeCopyProgress(150.0), 99.0, "active progress clamps over 100 below rounded final display")
        assertApproximatelyEqual(ProgressParser.activeCopyProgress(-1.0), 0.0, "active progress clamps negative")
    }

    private static func testCompletedCopyProgressIsOnlyFinalHundredConstant() {
        assertEqual(ProgressParser.completedCopyProgress, 100.0, "completed copy progress")
        assertEqual(ProgressParser.activeCopyProgress(100.0) == ProgressParser.completedCopyProgress, false, "active copy must not emit final progress")
    }
}
