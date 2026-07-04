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
        XCTAssertTrue(randomReport.contains("Verification Coverage: Random 33%"))
        XCTAssertTrue(randomReport.contains("Hash Algorithm:      SHA256"))
        XCTAssertTrue(randomReport.contains("Strong cryptographic hash verification"))

        let fullReport = await engine.generateReportText(
            report: report(mode: .full, status: .passed, finalStatus: .safeToFormat),
            bandwidthLimit: nil
        )
        XCTAssertTrue(fullReport.contains("Verification Mode:   xxHash64 Full 100%"))
        XCTAssertTrue(fullReport.contains("Verification Coverage: Full 100%"))
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

private extension XXHash64 {
    static func hexDigest(for string: String) -> String {
        var hasher = XXHash64()
        hasher.update(Data(string.utf8))
        return hasher.hexDigest()
    }
}
