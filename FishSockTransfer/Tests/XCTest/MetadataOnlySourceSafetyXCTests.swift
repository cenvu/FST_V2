import XCTest

private final class VerificationEventRecorder: @unchecked Sendable {
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

final class MetadataOnlySourceSafetyXCTests: XCTestCase {
    private var temporaryRoot: URL!

    override func setUpWithError() throws {
        temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTMetadataOnlySourceSafetyXCTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryRoot)
        temporaryRoot = nil
    }

    func testDSStoreOnlySourceFailsValidation() async throws {
        let sourceURL = try folder(named: "ds-store-only-source", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)
        try await assertSourceValidationFails(sourceURL, expectedError: .sourceEmpty)
    }

    func testExcludedMetadataOnlySourceFailsValidation() async throws {
        let sourceURL = try folder(named: "metadata-only-source", in: temporaryRoot)
        let spotlightURL = try folder(named: ".Spotlight-V100", in: sourceURL)
        try writeFile("store.db", contents: "metadata", in: spotlightURL)
        try writeFile("._clip.mov", contents: "metadata", in: sourceURL)
        try await assertSourceValidationFails(sourceURL, expectedError: .sourceEmpty)
    }

    func testMetadataPlusMediaSourcePassesValidation() async throws {
        let sourceURL = try folder(named: "metadata-plus-media-source", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)
        try writeFile("A001_C001.mov", contents: "media", in: sourceURL)

        let driveService = DriveService()
        try await driveService.validateSource(at: sourceURL)
        let fileCount = try await driveService.countFiles(at: sourceURL)
        XCTAssertEqual(fileCount, 1)
    }

    func testRandom33ZeroEligibleSourceFailsVerification() async throws {
        let sourceURL = try folder(named: "random-zero-source", in: temporaryRoot)
        let destinationURL = try folder(named: "random-zero-destination", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)

        let events = await verificationEvents(sourceURL: sourceURL, destinationURL: destinationURL, mode: .random33)
        XCTAssertTrue(events.compactMap(failedErrorDescription).contains("No transferable files found after exclusions."))
        XCTAssertFalse(events.contains(where: isCompletedPassed))
    }

    func testFullZeroEligibleSourceFailsVerification() async throws {
        let sourceURL = try folder(named: "full-zero-source", in: temporaryRoot)
        let destinationURL = try folder(named: "full-zero-destination", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)

        let events = await verificationEvents(sourceURL: sourceURL, destinationURL: destinationURL, mode: .full)
        XCTAssertTrue(events.compactMap(failedErrorDescription).contains("No transferable files found after exclusions."))
        XCTAssertFalse(events.contains(where: isCompletedPassed))
    }

    func testNormalEligibleSourceStillVerifies() async throws {
        let sourceURL = try folder(named: "normal-source", in: temporaryRoot)
        let destinationURL = try folder(named: "normal-destination", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)
        try writeFile("A001_C001.mov", contents: "media", in: sourceURL)
        try writeFile("A001_C001.mov", contents: "media", in: destinationURL)

        let events = await verificationEvents(sourceURL: sourceURL, destinationURL: destinationURL, mode: .full)
        XCTAssertTrue(events.contains(where: isCompletedPassed))
    }

    func testValidationAndVerificationUseExclusionPolicyConsistently() async throws {
        let sourceURL = try folder(named: "consistent-source", in: temporaryRoot)
        let destinationURL = try folder(named: "consistent-destination", in: temporaryRoot)
        let temporaryItemsURL = try folder(named: ".TemporaryItems", in: sourceURL)
        try writeFile("transient", contents: "metadata", in: temporaryItemsURL)

        try await assertSourceValidationFails(sourceURL, expectedError: .sourceEmpty)

        let events = await verificationEvents(sourceURL: sourceURL, destinationURL: destinationURL, mode: .full)
        XCTAssertTrue(events.compactMap(failedErrorDescription).contains("No transferable files found after exclusions."))
    }

    private func assertSourceValidationFails(_ sourceURL: URL, expectedError: TransferError) async throws {
        let driveService = DriveService()
        do {
            try await driveService.validateSource(at: sourceURL)
            XCTFail("Source validation should fail for \(sourceURL.path)")
        } catch let error as TransferError {
            XCTAssertEqual(error, expectedError)
        }
    }

    private func verificationEvents(sourceURL: URL, destinationURL: URL, mode: VerificationMode) async -> [VerificationEvent] {
        let engine = VerifyEngine()
        let request = VerificationRequest(sourceURL: sourceURL, destinationURL: destinationURL, mode: mode)
        let recorder = VerificationEventRecorder()
        await engine.startVerification(request: request) { event in
            recorder.append(event)
        }
        return recorder.snapshot()
    }

    private func failedErrorDescription(_ event: VerificationEvent) -> String? {
        guard case .failed(let error) = event else { return nil }
        return error.localizedDescription
    }

    private func isCompletedPassed(_ event: VerificationEvent) -> Bool {
        guard case .completed(let result) = event else { return false }
        return result.status == .passed
    }

    private func folder(named name: String, in parentURL: URL) throws -> URL {
        let folderURL = parentURL.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL
    }

    private func writeFile(_ name: String, contents: String, in folderURL: URL) throws {
        let fileURL = folderURL.appendingPathComponent(name)
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
