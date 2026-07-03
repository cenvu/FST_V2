import XCTest

final class ProgressParserXCTests: XCTestCase {
    func testRsyncOutputFramerHandlesCarriageReturnRecords() {
        var framer = RsyncOutputFramer()
        let records = framer.append(Data("32.77K  3%  1.00MB/s    0:00:10\r524.29K  7%  2.00MB/s    0:00:09\r".utf8))

        XCTAssertEqual(records, [
            "32.77K  3%  1.00MB/s    0:00:10",
            "524.29K  7%  2.00MB/s    0:00:09"
        ])
        XCTAssertNil(framer.flush())
    }

    func testRsyncOutputFramerHandlesNewlineRecords() {
        var framer = RsyncOutputFramer()
        let records = framer.append(Data("first\nsecond\n".utf8))

        XCTAssertEqual(records, ["first", "second"])
        XCTAssertNil(framer.flush())
    }

    func testRsyncOutputFramerHandlesCRLFRecords() {
        var framer = RsyncOutputFramer()
        let records = framer.append(Data("first\r\nsecond\r\n".utf8))

        XCTAssertEqual(records, ["first", "second"])
        XCTAssertNil(framer.flush())
    }

    func testRsyncOutputFramerHandlesPartialChunks() {
        var framer = RsyncOutputFramer()

        XCTAssertEqual(framer.append(Data("32.77".utf8)), [])
        XCTAssertEqual(framer.append(Data("K  3%  1.00MB/s".utf8)), [])
        XCTAssertEqual(framer.append(Data("    0:00:10\rnext".utf8)), ["32.77K  3%  1.00MB/s    0:00:10"])
        XCTAssertEqual(framer.flush(), "next")
    }

    func testRsyncCommandIncludesOutputBufferArgumentAndNoFallbackPath() throws {
        let rsyncURL = URL(fileURLWithPath: "/Applications/FishSockTransfer.app/Contents/Resources/rsync")
        let command = try RsyncCommand(
            bundledInfo: BundledRsyncInfo(executableURL: rsyncURL, version: "3.4.4", diagnostics: []),
            request: TransferRequest(
                sourceURL: URL(fileURLWithPath: "/Volumes/CARD_A", isDirectory: true),
                destinationURL: URL(fileURLWithPath: "/Volumes/BACKUP", isDirectory: true),
                bandwidthLimit: RsyncBandwidthLimit.kibPerSecond(for: 50)
            )
        )

        XCTAssertEqual(command.executableURL, rsyncURL)
        XCTAssertTrue(command.arguments.contains("--outbuf=L"))
        XCTAssertTrue(command.arguments.contains("--info=progress2"))
        XCTAssertTrue(command.arguments.contains("-h"))
        XCTAssertTrue(command.arguments.contains("--bwlimit=51200"))
        XCTAssertFalse(command.executableURL.path.contains("/usr/bin/rsync"))
        XCTAssertFalse(command.executableURL.path.contains("/opt/homebrew/bin/rsync"))
        XCTAssertFalse(command.executableURL.path.contains("/usr/local/bin/rsync"))
    }

    func testParsesKilobytesPerSecond() throws {
        let data = try XCTUnwrap(ProgressParser().parse(line: "        1,024   1%  512.00kB/s    0:00:10"))
        XCTAssertEqual(data.progress, 1.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 0.5, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 10.0, accuracy: 0.0001)
        XCTAssertEqual(data.transferredBytes, 1_024)
    }

    func testParsesMegabytesPerSecond() throws {
        let data = try XCTUnwrap(ProgressParser().parse(line: "1,245,890,560  48%  120.34MB/s    0:01:30"))
        XCTAssertEqual(data.progress, 48.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 120.34, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 90.0, accuracy: 0.0001)
        XCTAssertEqual(data.transferredBytes, 1_245_890_560)
    }

    func testParsesGigabytesPerSecond() throws {
        let data = try XCTUnwrap(ProgressParser().parse(line: "9,876,543,210  75%  1.50GB/s    0:00:03"))
        XCTAssertEqual(data.progress, 75.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 1536.0, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 3.0, accuracy: 0.0001)
        XCTAssertEqual(data.transferredBytes, 9_876_543_210)
    }

    func testParsesHumanReadableByteCounts() throws {
        let parser = ProgressParser()
        let kilobytes = try XCTUnwrap(parser.parse(line: "32.77K  3%  512.00kB/s    0:00:10"))
        let megabytes = try XCTUnwrap(parser.parse(line: "107.01M  12%  4.00MB/s    0:00:08"))
        let gigabytes = try XCTUnwrap(parser.parse(line: "5.21G  88%  1.50GB/s    0:00:07"))

        XCTAssertEqual(kilobytes.progress, 3.0)
        XCTAssertEqual(kilobytes.transferredBytes, 33_556)
        XCTAssertEqual(megabytes.progress, 12.0)
        XCTAssertEqual(megabytes.transferredBytes, 112_208_118)
        XCTAssertEqual(gigabytes.progress, 88.0)
        XCTAssertEqual(gigabytes.transferredBytes, 5_594_194_903)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "524.29K  7%  1.00MB/s    0:00:09")).progress, 7.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "1.23M  12%  4.00MB/s    0:00:08")).progress, 12.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "9.87G  88%  1.50GB/s    0:00:07")).progress, 88.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "1.00T  91%  900.00MB/s    0:00:06")).progress, 91.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "512K  6%  2.00MB/s    0:00:05")).progress, 6.0)
        XCTAssertEqual(try XCTUnwrap(parser.parse(line: "1,024  1%  512.00kB/s    0:00:10")).progress, 1.0)
    }

    func testMalformedTransferredByteTokenReturnsNilWithoutBreakingProgressFields() throws {
        let overflowToken = String(repeating: "9", count: 400) + "K"
        let data = try XCTUnwrap(ProgressParser().parse(line: "\(overflowToken)  12%  1.00MB/s    0:00:01"))

        XCTAssertEqual(data.progress, 12.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 1.0, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 1.0, accuracy: 0.0001)
        XCTAssertNil(data.transferredBytes)
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

    func testProgressDeliveryGateThrottlesDuplicateProgressButAllowsForcedFirstProgress() {
        let start = Date()
        var gate = RsyncProgressDeliveryGate(minimumInterval: 60)

        XCTAssertTrue(gate.shouldDeliver(now: start))
        XCTAssertFalse(gate.shouldDeliver(now: start.addingTimeInterval(1)))
        XCTAssertTrue(gate.shouldDeliver(now: start.addingTimeInterval(2), force: true))
        XCTAssertFalse(gate.shouldDeliver(now: start.addingTimeInterval(3)))
        XCTAssertTrue(gate.shouldDeliver(now: start.addingTimeInterval(63)))
    }

    func testStdoutRecordProcessorThrottlesManyProgressRecordsWithoutSuppressingFirstProgress() {
        let diagnostics = RsyncCopyTimingDiagnostics()
        diagnostics.reset(startedAt: Date())
        let recorder = TransferEventRecorder()
        var processor = RsyncStdoutRecordProcessor(
            diagnostics: diagnostics,
            minimumProgressDeliveryInterval: 60
        ) { event in
            recorder.append(event)
        }
        let start = Date()

        processor.process("32.77K  0%  512.00kB/s    0:00:10", now: start)
        for index in 1...100 {
            processor.process("\(index).00M  \(min(index, 99))%  1.00MB/s    0:00:09", now: start.addingTimeInterval(Double(index) / 100.0))
        }

        let events = recorder.snapshot()
        let progressEvents = events.compactMap { event -> Double? in
            guard case .progress(let progress) = event else { return nil }
            return progress
        }
        let transferredByteEvents = events.compactMap { event -> Int64? in
            guard case .transferredBytes(let bytes) = event else { return nil }
            return bytes
        }
        let diagnosticMessages = events.compactMap { event -> String? in
            guard case .log(let message) = event, message.hasPrefix("DIAG [RSYNC TIMING]") else { return nil }
            return message
        }

        XCTAssertEqual(progressEvents, [0.0, 1.0])
        XCTAssertEqual(transferredByteEvents, [33_556, 1_048_576])
        XCTAssertTrue(diagnosticMessages.contains { $0.contains("First parsed progress2 record") })
        XCTAssertTrue(diagnosticMessages.contains { $0.contains("First structured progress >0") })
    }
}

private final class TransferEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [TransferEvent] = []

    func append(_ event: TransferEvent) {
        lock.withLock {
            events.append(event)
        }
    }

    func snapshot() -> [TransferEvent] {
        lock.withLock {
            events
        }
    }
}
