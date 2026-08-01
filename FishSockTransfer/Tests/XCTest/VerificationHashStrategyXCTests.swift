// FST / CenVu | (+84) 842 841 222

import XCTest

final class VerificationHashStrategyXCTests: XCTestCase {
    func testXXHash64StandardVectorsSeedZero() {
        XCTAssertEqual(XXHash64.hexDigest(for: ""), "ef46db3751d8e999")
        XCTAssertEqual(XXHash64.hexDigest(for: "a"), "d24ec4f1a98c6e5b")
        XCTAssertEqual(XXHash64.hexDigest(for: "abc"), "44bc2cf5ad770999")
        XCTAssertEqual(XXHash64.hexDigest(for: "hello"), "26c7827d889f6da3")
        XCTAssertEqual(XXHash64.hexDigest(for: "The quick brown fox jumps over the lazy dog"), "0b242d361fda71bc")
    }

    func testXXHash64ChunkedUpdateMatchesSingleUpdateAndHexShape() {
        let data = Data("The quick brown fox jumps over the lazy dog".utf8)
        var single = XXHash64()
        single.update(data)

        var chunked = XXHash64()
        chunked.update(Data(data.prefix(10)))
        chunked.update(Data(data.dropFirst(10).prefix(7)))
        chunked.update(Data(data.dropFirst(17)))

        XCTAssertEqual(chunked.hexDigest(), single.hexDigest())
        XCTAssertEqual(chunked.hexDigest().count, 16)
        XCTAssertEqual(chunked.hexDigest(), chunked.hexDigest().lowercased())
    }

    func testVerificationModeHashMappingAndLabels() {
        XCTAssertNil(VerificationMode.none.hashAlgorithm)
        XCTAssertEqual(VerificationMode.random33.hashAlgorithm, .sha256)
        XCTAssertEqual(VerificationMode.full.hashAlgorithm, .xxHash64)
        XCTAssertEqual(VerificationMode.random33.operatorLabel, "SHA256 Sample 33%")
        XCTAssertEqual(VerificationMode.full.operatorLabel, "xxHash64 Full 100%")
        XCTAssertTrue(HashAlgorithm.sha256.verificationNote.contains("cryptographic"))
        XCTAssertTrue(HashAlgorithm.xxHash64.verificationNote.contains("non-cryptographic"))
    }

    func testSHA256HashGenerationRemainsUnchanged() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let fileURL = root.appendingPathComponent("abc.txt")
        try "abc".write(to: fileURL, atomically: true, encoding: .utf8)

        let hash = try await VerifyEngine().generateHash(
            url: fileURL,
            algorithm: .sha256,
            label: "Test",
            relativePath: "abc.txt",
            onEvent: { _ in }
        )

        XCTAssertEqual(hash, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testReportDisclosesSelectedHashAlgorithmAndStrength() async {
        let engine = ReportEngine()

        let randomReport = await engine.generateReportText(
            report: report(mode: .random33, status: .failed, finalStatus: .error),
            bandwidthLimit: nil
        )
        XCTAssertTrue(randomReport.contains("Verification Mode:   SHA256 Sample 33%"))
        XCTAssertTrue(randomReport.contains("Verification Scope:  RANDOM SAMPLE"))
        XCTAssertTrue(randomReport.contains("Hash Algorithm:      SHA256"))
        XCTAssertTrue(randomReport.contains("Strong cryptographic hash verification"))

        let fullReport = await engine.generateReportText(
            report: report(mode: .full, status: .passed, finalStatus: .safeToFormat),
            bandwidthLimit: nil
        )
        XCTAssertTrue(fullReport.contains("Verification Mode:   xxHash64 Full 100%"))
        XCTAssertTrue(fullReport.contains("Verification Scope:  FULL 100%"))
        XCTAssertTrue(fullReport.contains("Hash Algorithm:      xxHash64"))
        XCTAssertTrue(fullReport.contains("Fast non-cryptographic hash verification"))
        XCTAssertFalse(fullReport.contains(["SAFE", "TO", "FORMAT"].joined(separator: " ")))
    }

    func testFullVerificationUsesXXHash64AndFailsAlteredSameSizeDestinationFile() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let source = root.appendingPathComponent("source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try "camera-a".write(to: source.appendingPathComponent("clip.mov"), atomically: true, encoding: .utf8)
        try "camera-b".write(to: destination.appendingPathComponent("clip.mov"), atomically: true, encoding: .utf8)

        let recorder = HashStrategyVerificationEventRecorder()
        let request = VerificationRequest(sourceURL: source, destinationURL: destination, mode: .full)
        await VerifyEngine().startVerification(request: request) { event in
            recorder.append(event)
        }

        let events = recorder.snapshot()
        XCTAssertTrue(events.contains(.failed(.hashMismatch)))
        let logMessages = events.compactMap { event -> String? in
            if case .log(let message) = event { return message }
            return nil
        }
        XCTAssertTrue(logMessages.contains(where: { $0.contains("Hash Algorithm: xxHash64") }))
    }

    // Direct VerifyEngine contract for mode `.none`: production never sends `.none`
    // here (TransferCoordinator fast-exits to `.copyComplete`), so this pins the
    // engine-internal semantics — a copy-only pass with zero verified files.
    func testDirectNoneModeVerificationDoesNotHashAndEmitsZeroVerifiedPassed() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let source = root.appendingPathComponent("source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try "camera".write(to: source.appendingPathComponent("clip.mov"), atomically: true, encoding: .utf8)
        try "camera".write(to: destination.appendingPathComponent("clip.mov"), atomically: true, encoding: .utf8)

        let recorder = HashStrategyVerificationEventRecorder()
        let request = VerificationRequest(sourceURL: source, destinationURL: destination, mode: .none)
        await VerifyEngine().startVerification(request: request) { event in
            recorder.append(event)
        }

        let events = recorder.snapshot()

        // Deterministic completion: exactly one terminal `.completed` event, no failure/cancel.
        let completedEvents = events.filter { event in
            if case .completed = event { return true }
            return false
        }
        XCTAssertEqual(completedEvents.count, 1, "Expected exactly one terminal .completed event, got: \(events)")
        guard case .completed(let result) = events.last else {
            XCTFail("Expected the final event to be .completed, got: \(events)")
            return
        }

        // Copy-only pass: `.none` never hashes, so zero files are verified or passed.
        XCTAssertEqual(result.status, .passed)
        XCTAssertEqual(result.totalFiles, 1)
        XCTAssertEqual(result.verifiedFiles, 0)
        XCTAssertEqual(result.passedFiles, 0)
        XCTAssertEqual(result.failedFiles, 0)

        // No hashing occurred: hashing emits .currentFile, .hashGenerated, and .progress.
        let hashingEvents = events.filter { event in
            if case .currentFile = event { return true }
            if case .hashGenerated = event { return true }
            if case .progress = event { return true }
            return false
        }
        XCTAssertTrue(hashingEvents.isEmpty, "Mode .none must not emit hashing events, got: \(hashingEvents)")

        let terminalFailures = events.filter { event in
            if case .failed = event { return true }
            if case .cancelled = event { return true }
            return false
        }
        XCTAssertTrue(terminalFailures.isEmpty, "Mode .none must not emit failure or cancellation, got: \(terminalFailures)")

        // Zero verified files means this `.passed` result carries no verified-safety
        // evidence. The SAFE TO EJECT gate for `.none` is proven by the existing
        // Coordinator/report tests (copyComplete only, never SAFE TO EJECT).
    }

    // Deterministic VerifyEngine cancellation contract: when cancel() is
    // requested after one file has verified but before the next file begins,
    // the engine emits exactly one .hashGenerated event and exactly one
    // terminal .cancelled event — never .completed or .failed, so cancellation
    // can never become verification success or SAFE TO EJECT.
    // CONTRACT_TEST_FOR_PROVEN_BEHAVIOR: pins the existing per-file isCancelled
    // checkpoint at the top of the hash loop via the DEBUG-only seam.
    func testCancelBetweenFilesStopsBeforeNextFileAndEmitsExactlyOneCancelledEvent() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let source = root.appendingPathComponent("source", isDirectory: true)
        let destination = root.appendingPathComponent("destination", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        // Two small matching files; .full verification selects both, and the
        // between-file boundary is deterministic without timing assumptions.
        let fileNames = ["clip-a.mov", "clip-b.mov"]
        for name in fileNames {
            let data = Data(repeating: 0x5A, count: 4096)
            try data.write(to: source.appendingPathComponent(name))
            try data.write(to: destination.appendingPathComponent(name))
        }

        let gate = VerificationCancellationGate()
        let pauseExpectation = expectation(description: "VerifyEngine reached the file-verified hook")
        await gate.setPauseExpectation(pauseExpectation)

        let recorder = HashStrategyVerificationEventRecorder()
        let engine = VerifyEngine()
        await engine.setFileVerifiedHookForTesting {
            await gate.pause()
        }

        let verificationTask = Task {
            await engine.startVerification(
                request: VerificationRequest(sourceURL: source, destinationURL: destination, mode: .full)
            ) { event in
                recorder.append(event)
            }
        }

        // 1. Await the pause using native XCTest expectation as a failure guard.
        // `fulfillment` does not throw on timeout; it records a test failure and returns control.
        await fulfillment(of: [pauseExpectation], timeout: 15.0)

        // 2. Execute idempotent explicit cleanup.
        // Because XCTest fulfillment returns control, we unconditionally execute this cleanup
        // (success or failure). gate.resume() explicitly releases the checked continuation,
        // so no child task remains trapped.
        await engine.cancel()
        await gate.resume()

        // 3. Join the verification task.
        // The cleanup sequence above guarantees the verification task will unblock and exit normally.
        await verificationTask.value

        // 4. Clear the hook.
        await engine.setFileVerifiedHookForTesting(nil)

        let events = recorder.snapshot()

        let currentFilePaths = events.compactMap { event -> String? in
            if case .currentFile(let path) = event { return path }
            return nil
        }
        let hashGeneratedMessages = events.compactMap { event -> String? in
            if case .hashGenerated(let message) = event { return message }
            return nil
        }
        let cancelledCount = events.filter { $0 == .cancelled }.count
        let completedCount = events.filter { event in
            if case .completed = event { return true }
            return false
        }.count
        let failedCount = events.filter { event in
            if case .failed = event { return true }
            return false
        }.count

        // Exactly one file began hashing — file 2's iteration never began.
        XCTAssertEqual(currentFilePaths.count, 1, "Expected exactly one .currentFile event, got: \(events)")
        XCTAssertEqual(hashGeneratedMessages.count, 1, "Expected exactly one .hashGenerated event, got: \(events)")

        // The single hashGenerated event belongs to the first verified file,
        // and never to the second file.
        if let verifiedPath = currentFilePaths.first, let hashMessage = hashGeneratedMessages.first {
            XCTAssertTrue(hashMessage.contains(verifiedPath), "hashGenerated must reference the first verified file")
            for other in fileNames where other != verifiedPath {
                XCTAssertFalse(hashMessage.contains(other), "hashGenerated must not reference the second file")
            }
        }

        // Exactly one terminal event, which is .cancelled; completion or
        // failure can never follow cancellation.
        XCTAssertEqual(cancelledCount, 1, "Expected exactly one terminal .cancelled event, got: \(events)")
        XCTAssertEqual(completedCount, 0, "Cancellation must never emit .completed, got: \(events)")
        XCTAssertEqual(failedCount, 0, "Cancellation must never emit .failed, got: \(events)")
        XCTAssertEqual(events.last, .cancelled, "cancelled must be the final event, got: \(events)")

        // The gate continuation was resumed exactly once.
        let resumeCount = await gate.resumeCount
        XCTAssertEqual(resumeCount, 1, "Expected the gate continuation to resume exactly once")
    }



    private func report(mode: VerificationMode, status: VerificationStatus?, finalStatus: TransferState) -> TransferReport {
        TransferReport(
            date: "2026-06-22",
            time: "05:30:00",
            sourcePath: "/Volumes/CARD_A",
            destinationPath: "/Volumes/RAID/CARD_A",
            totalSize: 1_048_576,
            fileCount: 1,
            copyDuration: 10,
            verificationDuration: mode == .none ? nil : 50,
            totalDuration: 60,
            copyAverageSpeed: 0.1,
            verificationMode: mode,
            verificationResult: status,
            verifiedFiles: status == nil ? 0 : 1,
            passedFiles: status == .passed ? 1 : 0,
            failedFiles: status == .failed ? 1 : 0,
            errorCount: finalStatus == .error ? 1 : 0,
            finalStatus: finalStatus
        )
    }
}

private final class HashStrategyVerificationEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [VerificationEvent] = []

    func append(_ event: VerificationEvent) {
        lock.lock()
        events.append(event)
        lock.unlock()
    }

    func snapshot() -> [VerificationEvent] {
        lock.lock()
        let snapshot = events
        lock.unlock()
        return snapshot
    }
}

/// Deterministic checked-continuation gate that suspends the VerifyEngine at
/// its DEBUG file-verified hook and releases it on demand. Mirrors the
/// approved TerminalTailAsyncGate pattern; actor serialization prevents lost
/// wakeups, and resume() is idempotent so no continuation is resumed twice.
private actor VerificationCancellationGate {
    private var isPaused = false
    private var hasPaused = false
    private var pauseExpectation: XCTestExpectation?
    private var resumeWaiter: CheckedContinuation<Void, Never>?
    private(set) var resumeCount = 0

    func setPauseExpectation(_ expectation: XCTestExpectation) {
        self.pauseExpectation = expectation
    }

    func pause() async {
        guard !hasPaused else { return }
        hasPaused = true
        isPaused = true
        pauseExpectation?.fulfill()
        pauseExpectation = nil
        await withCheckedContinuation { resumeWaiter = $0 }
    }

    func resume() {
        guard resumeWaiter != nil else { return }
        resumeWaiter?.resume()
        resumeWaiter = nil
        resumeCount += 1
    }
}

private extension XXHash64 {
    static func hexDigest(for string: String) -> String {
        var hasher = XXHash64()
        hasher.update(Data(string.utf8))
        return hasher.hexDigest()
    }
}
