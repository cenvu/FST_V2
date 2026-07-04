// FST / CenVu | (+84) 842 841 222

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

    func testRsyncOutputFramerHandlesMixedNameAndProgressRecords() {
        var framer = RsyncOutputFramer()
        let records = framer.append(Data("MACOS-APP/A Better File.dmg\n32.77K  3%  1.00MB/s    0:00:10\r".utf8))

        XCTAssertEqual(records, [
            "MACOS-APP/A Better File.dmg",
            "32.77K  3%  1.00MB/s    0:00:10"
        ])
    }

    func testRsyncOutputFramerHandlesBurstOfFilenamesAndProgress() {
        var framer = RsyncOutputFramer()
        let records = framer.append(Data("""
        MACOS-APP/
        MACOS-APP/file one.mov
        32.77K  0%  0.00kB/s    0:00:00\r250.26M  1%  117.04MB/s    0:02:30\rMACOS-APP/file two.mov

        """.utf8))

        XCTAssertEqual(records, [
            "MACOS-APP/",
            "MACOS-APP/file one.mov",
            "32.77K  0%  0.00kB/s    0:00:00",
            "250.26M  1%  117.04MB/s    0:02:30",
            "MACOS-APP/file two.mov"
        ])
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
        XCTAssertTrue(command.arguments.contains("--outbuf=N"))
        XCTAssertFalse(command.arguments.contains("--outbuf=L"))
        XCTAssertTrue(command.arguments.contains("--info=name1,progress2"))
        XCTAssertFalse(command.arguments.contains("--info=progress2"))
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
    }

    func testParsesCROnlyProgressRecord() throws {
        let records = "32.77K  0%  0.00kB/s    0:00:00\r"
        let data = try XCTUnwrap(ProgressParser().parse(line: records))

        XCTAssertEqual(data.progress, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.speedMBps, 0.0, accuracy: 0.0001)
        XCTAssertEqual(data.eta, 0.0, accuracy: 0.0001)
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
        let diagnosticMessages = events.compactMap { event -> String? in
            guard case .log(let message) = event, message.hasPrefix("DIAG [RSYNC TIMING]") else { return nil }
            return message
        }

        XCTAssertEqual(progressEvents, [0.0, 1.0])
        XCTAssertTrue(diagnosticMessages.contains { $0.contains("First rsync progress after") })
        XCTAssertTrue(diagnosticMessages.contains { $0.contains("First structured progress >0") })
    }

    func testStdoutRecordProcessorEmitsCurrentFileForNameRecords() {
        let diagnostics = RsyncCopyTimingDiagnostics()
        diagnostics.reset(startedAt: Date())
        let recorder = TransferEventRecorder()
        var processor = RsyncStdoutRecordProcessor(diagnostics: diagnostics) { event in
            recorder.append(event)
        }

        processor.process("MACOS-APP/A Better File.dmg\n")

        let events = recorder.snapshot()
        XCTAssertTrue(events.contains(.currentFile("MACOS-APP/A Better File.dmg")))
        XCTAssertTrue(events.contains(.log("[STDOUT] MACOS-APP/A Better File.dmg")))
        XCTAssertTrue(events.contains { event in
            guard case .log(let message) = event else { return false }
            return message.contains("First rsync filename after")
        })
    }

    func testStdoutRecordProcessorIgnoresEmptyFilenameRecords() {
        let diagnostics = RsyncCopyTimingDiagnostics()
        diagnostics.reset(startedAt: Date())
        let recorder = TransferEventRecorder()
        var processor = RsyncStdoutRecordProcessor(diagnostics: diagnostics) { event in
            recorder.append(event)
        }

        processor.process("MACOS-APP/A Better File.dmg\n")
        processor.process("   \n")

        let currentFiles = recorder.snapshot().compactMap { event -> String? in
            guard case .currentFile(let file) = event else { return nil }
            return file
        }
        XCTAssertEqual(currentFiles, ["MACOS-APP/A Better File.dmg"])
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

final class DestinationActivityObserverXCTests: XCTestCase {
    func testDestinationSnapshotComputesCopiedBytesAndFilesExcludingMetadata() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try writeFile(root.appendingPathComponent("clip.mov"), bytes: 1_024)
        try writeFile(root.appendingPathComponent(".DS_Store"), bytes: 1_024)
        let trashes = root.appendingPathComponent(".Trashes", isDirectory: true)
        try FileManager.default.createDirectory(at: trashes, withIntermediateDirectories: true)
        try writeFile(trashes.appendingPathComponent("ignored.mov"), bytes: 1_024)

        let result = try DestinationActivitySnapshotter.snapshot(
            destinationRootURL: root,
            totalBytes: 2_048,
            totalFiles: 2,
            copyStartedAt: Date().addingTimeInterval(-5),
            previousSamples: []
        )

        XCTAssertEqual(result.snapshot.copiedBytes, 1_024)
        XCTAssertEqual(result.snapshot.copiedFiles, 1)
        XCTAssertEqual(result.snapshot.currentItem, "clip.mov")
        XCTAssertEqual(result.snapshot.signalSource, .destinationObserver)
    }

    func testDestinationSnapshotComputesAverageRollingSpeedAndETA() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let start = Date()
        try writeFile(root.appendingPathComponent("clip.mov"), bytes: 1_000)
        let first = try DestinationActivitySnapshotter.snapshot(
            destinationRootURL: root,
            totalBytes: 4_000,
            totalFiles: 1,
            copyStartedAt: start,
            previousSamples: [],
            now: start.addingTimeInterval(5)
        )

        try writeFile(root.appendingPathComponent("clip.mov"), bytes: 2_000)
        let second = try DestinationActivitySnapshotter.snapshot(
            destinationRootURL: root,
            totalBytes: 4_000,
            totalFiles: 1,
            copyStartedAt: start,
            previousSamples: first.samples,
            now: start.addingTimeInterval(10)
        )

        XCTAssertEqual(second.snapshot.copiedBytes, 2_000)
        XCTAssertEqual(second.snapshot.currentSpeedBytesPerSecond ?? 0, 200, accuracy: 0.0001)
        XCTAssertEqual(second.snapshot.averageSpeedBytesPerSecond ?? 0, 200, accuracy: 0.0001)
        XCTAssertEqual(second.snapshot.etaSeconds ?? 0, 10, accuracy: 0.0001)
        XCTAssertEqual(second.snapshot.progressFraction ?? 0, 0.5, accuracy: 0.0001)
    }

    func testDestinationSnapshotClampsCopiedBytesToKnownTotal() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try writeFile(root.appendingPathComponent("clip.mov"), bytes: 4_000)

        let result = try DestinationActivitySnapshotter.snapshot(
            destinationRootURL: root,
            totalBytes: 1_000,
            totalFiles: 1,
            copyStartedAt: Date().addingTimeInterval(-5),
            previousSamples: []
        )

        XCTAssertEqual(result.snapshot.copiedBytes, 1_000)
        XCTAssertEqual(result.snapshot.progressFraction, 1.0)
    }

    func testDestinationSnapshotDoesNotComputeETAWhenSpeedUnavailable() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try writeFile(root.appendingPathComponent("clip.mov"), bytes: 1_000)

        let result = try DestinationActivitySnapshotter.snapshot(
            destinationRootURL: root,
            totalBytes: 4_000,
            totalFiles: 1,
            copyStartedAt: Date().addingTimeInterval(-5),
            previousSamples: []
        )

        XCTAssertNil(result.snapshot.currentSpeedBytesPerSecond)
        XCTAssertNil(result.snapshot.etaSeconds)
    }

    func testDestinationObserverStopsOnCancelAndCompletionReasons() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let observer = DestinationActivityObserver()
        let recorder = ObserverLogRecorder()

        await observer.start(
            destinationRootURL: root,
            totalBytes: 1_000,
            totalFiles: 1,
            copyStartedAt: Date(),
            cadenceSeconds: 60,
            onSnapshot: { _ in },
            onLog: { recorder.append($0) }
        )
        let runningAfterStart = await observer.isRunning()
        XCTAssertTrue(runningAfterStart)

        await observer.stop(reason: "cancel requested") { recorder.append($0) }
        let runningAfterStop = await observer.isRunning()
        XCTAssertFalse(runningAfterStop)

        await observer.start(
            destinationRootURL: root,
            totalBytes: 1_000,
            totalFiles: 1,
            copyStartedAt: Date(),
            cadenceSeconds: 60,
            onSnapshot: { _ in },
            onLog: { recorder.append($0) }
        )
        await observer.stop(reason: "rsync completed") { recorder.append($0) }

        let logs = recorder.snapshot()
        XCTAssertTrue(logs.contains { $0.contains("OBSERVER stopped: cancel requested") })
        XCTAssertTrue(logs.contains { $0.contains("OBSERVER stopped: rsync completed") })
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeFile(_ url: URL, bytes: Int) throws {
        let data = Data(repeating: 7, count: bytes)
        try data.write(to: url)
        try FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: url.path
        )
    }
}

private final class ObserverLogRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var logs: [String] = []

    func append(_ message: String) {
        lock.withLock {
            logs.append(message)
        }
    }

    func snapshot() -> [String] {
        lock.withLock {
            logs
        }
    }
}
