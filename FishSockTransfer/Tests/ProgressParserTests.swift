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
        testParsesHumanReadableKilobyteByteCounts()
        testParsesHumanReadableMegabyteByteCount()
        testParsesHumanReadableGigabyteByteCount()
        testParsesHumanReadableTerabyteByteCount()
        testParsesIntegerHumanReadableByteCount()
        testParsesCommaNumericByteCount()
        testParsesETAFields()
        testParsesCarriageReturnDelimitedRecordsWithHumanReadableByteCounts()
        testRejectsArbitraryFilenameTextContainingPercent()
        testRejectsMalformedHumanReadableByteCounts()
        testHumanReadablePrematureHundredPercentClamps()
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

    private static func testParsesHumanReadableKilobyteByteCounts() {
        let parser = ProgressParser()
        let first = assertNotNil(
            parser.parse(line: "32.77K  3%  512.00kB/s    0:00:10"),
            "human-readable 32.77K byte count"
        )
        let second = assertNotNil(
            parser.parse(line: "524.29K  7%  1.00MB/s    0:00:09"),
            "human-readable 524.29K byte count"
        )

        assertApproximatelyEqual(first.progress, 3.0, "32.77K progress")
        assertApproximatelyEqual(first.speedMBps, 0.5, "32.77K speed")
        assertApproximatelyEqual(second.progress, 7.0, "524.29K progress")
        assertApproximatelyEqual(second.speedMBps, 1.0, "524.29K speed")
    }

    private static func testParsesHumanReadableMegabyteByteCount() {
        let data = assertNotNil(
            ProgressParser().parse(line: "1.23M  12%  4.00MB/s    0:00:08"),
            "human-readable 1.23M byte count"
        )

        assertApproximatelyEqual(data.progress, 12.0, "1.23M progress")
        assertApproximatelyEqual(data.speedMBps, 4.0, "1.23M speed")
    }

    private static func testParsesHumanReadableGigabyteByteCount() {
        let data = assertNotNil(
            ProgressParser().parse(line: "9.87G  88%  1.50GB/s    0:00:07"),
            "human-readable 9.87G byte count"
        )

        assertApproximatelyEqual(data.progress, 88.0, "9.87G progress")
        assertApproximatelyEqual(data.speedMBps, 1536.0, "9.87G speed")
    }

    private static func testParsesHumanReadableTerabyteByteCount() {
        let data = assertNotNil(
            ProgressParser().parse(line: "1.00T  91%  900.00MB/s    0:00:06"),
            "human-readable 1.00T byte count"
        )

        assertApproximatelyEqual(data.progress, 91.0, "1.00T progress")
        assertApproximatelyEqual(data.speedMBps, 900.0, "1.00T speed")
    }

    private static func testParsesIntegerHumanReadableByteCount() {
        let data = assertNotNil(
            ProgressParser().parse(line: "512K  6%  2.00MB/s    0:00:05"),
            "integer human-readable 512K byte count"
        )

        assertApproximatelyEqual(data.progress, 6.0, "512K progress")
        assertApproximatelyEqual(data.speedMBps, 2.0, "512K speed")
    }

    private static func testParsesCommaNumericByteCount() {
        let data = assertNotNil(
            ProgressParser().parse(line: "1,024  1%  512.00kB/s    0:00:10"),
            "comma numeric byte count"
        )

        assertApproximatelyEqual(data.progress, 1.0, "comma numeric progress")
        assertApproximatelyEqual(data.speedMBps, 0.5, "comma numeric speed")
    }

    private static func testParsesETAFields() {
        let data = assertNotNil(
            ProgressParser().parse(line: "10,000,000  25%  10.00MB/s    1:02:03"),
            "hour ETA progress2 line"
        )

        assertApproximatelyEqual(data.eta, 3723.0, "hour ETA conversion")
    }

    private static func testParsesCarriageReturnDelimitedRecordsWithHumanReadableByteCounts() {
        let line = "32.77K  10%  1.00MB/s    0:00:09\r1.23M  20%  2.00MB/s    0:00:08"
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
        assertNil(parser.parse(line: "clip.mov 100% 1.00MB/s 0:00:01"), "filename token must not be accepted as byte count")
    }

    private static func testRejectsMalformedHumanReadableByteCounts() {
        let parser = ProgressParser()

        assertNil(parser.parse(line: "32.K  12%  1.00MB/s    0:00:01"), "missing fractional digits")
        assertNil(parser.parse(line: ".32K  12%  1.00MB/s    0:00:01"), "missing integer digits")
        assertNil(parser.parse(line: "1.2.3M  12%  1.00MB/s    0:00:01"), "multiple decimals")
        assertNil(parser.parse(line: "32.77KB  12%  1.00MB/s    0:00:01"), "unsupported byte unit suffix")
        assertNil(parser.parse(line: "K32  12%  1.00MB/s    0:00:01"), "unit prefix")
        assertNil(parser.parse(line: "32,77K  12%  1.00MB/s    0:00:01"), "comma inside human-readable number")
        assertNil(parser.parse(line: "1,,024  12%  1.00MB/s    0:00:01"), "malformed comma numeric byte count")
    }

    private static func testHumanReadablePrematureHundredPercentClamps() {
        let data = assertNotNil(
            ProgressParser().parse(line: "9.87G  100%  1.50GB/s    0:00:00"),
            "human-readable premature 100 progress"
        )

        assertApproximatelyEqual(data.progress, 100.0, "parser reports raw 100 progress")
        assertApproximatelyEqual(
            ProgressParser.activeCopyProgress(data.progress),
            99.0,
            "active copy clamps human-readable 100 below final display"
        )
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
