// FST / CenVu | (+84) 842 841 222

import Foundation

private func assertTrue(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError(message)
    }
}

private func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

private func assertContains(_ values: [String], _ expectedSubstring: String, _ message: String) {
    guard values.contains(where: { $0.contains(expectedSubstring) }) else {
        fatalError("\(message): missing '\(expectedSubstring)' in \(values)")
    }
}

private final class EventRecorder: @unchecked Sendable {
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

@main
struct MetadataOnlySourceSafetyTests {
    static func main() async throws {
        let temporaryRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FSTMetadataOnlySourceSafetyTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: temporaryRoot)
            } catch {
                fputs("Warning: failed to remove test directory \(temporaryRoot.path): \(error)\n", stderr)
            }
        }

        try await testDSStoreOnlySourceFailsValidation(temporaryRoot: temporaryRoot)
        try await testExcludedMetadataOnlySourceFailsValidation(temporaryRoot: temporaryRoot)
        try await testMetadataPlusMediaSourcePassesValidation(temporaryRoot: temporaryRoot)
        try await testRandom33ZeroEligibleSourceFailsVerification(temporaryRoot: temporaryRoot)
        try await testFullZeroEligibleSourceFailsVerification(temporaryRoot: temporaryRoot)
        try await testNormalEligibleSourceStillVerifies(temporaryRoot: temporaryRoot)
        try await testValidationAndVerificationUseExclusionPolicyConsistently(temporaryRoot: temporaryRoot)

        print("MetadataOnlySourceSafetyTests passed")
    }

    private static func testDSStoreOnlySourceFailsValidation(temporaryRoot: URL) async throws {
        let sourceURL = try folder(named: "ds-store-only-source", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)

        try await assertSourceValidationFails(sourceURL, expectedError: .sourceEmpty)
    }

    private static func testExcludedMetadataOnlySourceFailsValidation(temporaryRoot: URL) async throws {
        let sourceURL = try folder(named: "metadata-only-source", in: temporaryRoot)
        let spotlightURL = try folder(named: ".Spotlight-V100", in: sourceURL)
        try writeFile("store.db", contents: "metadata", in: spotlightURL)
        try writeFile("._clip.mov", contents: "metadata", in: sourceURL)

        try await assertSourceValidationFails(sourceURL, expectedError: .sourceEmpty)
    }

    private static func testMetadataPlusMediaSourcePassesValidation(temporaryRoot: URL) async throws {
        let sourceURL = try folder(named: "metadata-plus-media-source", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)
        try writeFile("A001_C001.mov", contents: "media", in: sourceURL)

        let driveService = DriveService()
        try await driveService.validateSource(at: sourceURL)
        let fileCount = try await driveService.countFiles(at: sourceURL)
        assertEqual(fileCount, 1, "Validation scan should count only transferable media file.")
    }

    private static func testRandom33ZeroEligibleSourceFailsVerification(temporaryRoot: URL) async throws {
        let sourceURL = try folder(named: "random-zero-source", in: temporaryRoot)
        let destinationURL = try folder(named: "random-zero-destination", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)

        let events = await verificationEvents(sourceURL: sourceURL, destinationURL: destinationURL, mode: .random33)

        assertContains(events.compactMap(failedErrorDescription), "No transferable files found after exclusions.", "random33 zero source failure")
        assertTrue(!events.contains(where: isCompletedPassed), "random33 zero source must not pass verification.")
    }

    private static func testFullZeroEligibleSourceFailsVerification(temporaryRoot: URL) async throws {
        let sourceURL = try folder(named: "full-zero-source", in: temporaryRoot)
        let destinationURL = try folder(named: "full-zero-destination", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)

        let events = await verificationEvents(sourceURL: sourceURL, destinationURL: destinationURL, mode: .full)

        assertContains(events.compactMap(failedErrorDescription), "No transferable files found after exclusions.", "full zero source failure")
        assertTrue(!events.contains(where: isCompletedPassed), "full zero source must not pass verification.")
    }

    private static func testNormalEligibleSourceStillVerifies(temporaryRoot: URL) async throws {
        let sourceURL = try folder(named: "normal-source", in: temporaryRoot)
        let destinationURL = try folder(named: "normal-destination", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)
        try writeFile("A001_C001.mov", contents: "media", in: sourceURL)
        try writeFile("A001_C001.mov", contents: "media", in: destinationURL)

        let events = await verificationEvents(sourceURL: sourceURL, destinationURL: destinationURL, mode: .full)

        assertTrue(events.contains(where: isCompletedPassed), "normal source with media plus metadata should verify.")
    }

    private static func testValidationAndVerificationUseExclusionPolicyConsistently(temporaryRoot: URL) async throws {
        let sourceURL = try folder(named: "consistent-source", in: temporaryRoot)
        let destinationURL = try folder(named: "consistent-destination", in: temporaryRoot)
        let temporaryItemsURL = try folder(named: ".TemporaryItems", in: sourceURL)
        try writeFile("transient", contents: "metadata", in: temporaryItemsURL)

        try await assertSourceValidationFails(sourceURL, expectedError: .sourceEmpty)

        let events = await verificationEvents(sourceURL: sourceURL, destinationURL: destinationURL, mode: .full)
        assertContains(events.compactMap(failedErrorDescription), "No transferable files found after exclusions.", "policy consistency failure")
    }

    private static func assertSourceValidationFails(_ sourceURL: URL, expectedError: TransferError) async throws {
        let driveService = DriveService()
        do {
            try await driveService.validateSource(at: sourceURL)
            fatalError("Source validation should fail for \(sourceURL.path)")
        } catch let error as TransferError {
            assertEqual(error, expectedError, "Source validation failure")
        }
    }

    private static func verificationEvents(
        sourceURL: URL,
        destinationURL: URL,
        mode: VerificationMode
    ) async -> [VerificationEvent] {
        let engine = VerifyEngine()
        let request = VerificationRequest(sourceURL: sourceURL, destinationURL: destinationURL, mode: mode)
        let recorder = EventRecorder()
        await engine.startVerification(request: request) { event in
            recorder.append(event)
        }
        return recorder.snapshot()
    }

    private static func failedErrorDescription(_ event: VerificationEvent) -> String? {
        guard case .failed(let error) = event else {
            return nil
        }

        return error.localizedDescription
    }

    private static func isCompletedPassed(_ event: VerificationEvent) -> Bool {
        guard case .completed(let result) = event else {
            return false
        }

        return result.status == .passed
    }

    private static func folder(named name: String, in parentURL: URL) throws -> URL {
        let folderURL = parentURL.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL
    }

    private static func writeFile(_ name: String, contents: String, in folderURL: URL) throws {
        let fileURL = folderURL.appendingPathComponent(name)
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
