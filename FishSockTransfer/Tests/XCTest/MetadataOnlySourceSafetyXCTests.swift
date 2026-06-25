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

private final class TransferCoordinatorRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var states: [TransferState] = []
    private var errors: [String] = []
    private var logs: [LogEntry] = []

    func appendState(_ state: TransferState) {
        lock.lock()
        states.append(state)
        lock.unlock()
    }

    func appendError(_ error: String) {
        lock.lock()
        errors.append(error)
        lock.unlock()
    }

    func appendLog(_ log: LogEntry) {
        lock.lock()
        logs.append(log)
        lock.unlock()
    }

    func snapshotStates() -> [TransferState] {
        lock.lock()
        let snapshot = states
        lock.unlock()
        return snapshot
    }

    func snapshotErrors() -> [String] {
        lock.lock()
        let snapshot = errors
        lock.unlock()
        return snapshot
    }

    func snapshotLogs() -> [LogEntry] {
        lock.lock()
        let snapshot = logs
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
        XCTAssertTrue(TransferError.sourceEmpty.localizedDescription.contains("No transferable files found after exclusions."))
        XCTAssertFalse(TransferError.sourceEmpty.localizedDescription == "The selected source folder is empty.")
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

    func testPreflightBlocksSameSourceAndDestination() throws {
        let sourceURL = try folder(named: "same-source-destination", in: temporaryRoot)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        XCTAssertThrowsError(
            try TransferPreflightValidator.validate(
                source: sourceURL,
                destination: sourceURL,
                sourceMetadata: metadata,
                destinationFreeSpaceBytes: 2048
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .sameSourceAndDestination)
            XCTAssertEqual(
                (error as? TransferPreflightError)?.errorDescription,
                "Source and destination cannot be the same folder. Choose a separate destination."
            )
        }
    }

    func testPreflightBlocksDestinationInsideSource() throws {
        let sourceURL = try folder(named: "destination-inside-source", in: temporaryRoot)
        let destinationURL = try folder(named: "nested-destination", in: sourceURL)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        XCTAssertThrowsError(
            try TransferPreflightValidator.validate(
                source: sourceURL,
                destination: destinationURL,
                sourceMetadata: metadata,
                destinationFreeSpaceBytes: 2048
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .destinationInsideSource)
            XCTAssertEqual(
                (error as? TransferPreflightError)?.errorDescription,
                "Destination cannot be inside the source folder. Choose a destination outside the source/media tree."
            )
        }
    }

    func testPreflightBlocksSourceInsideDestination() throws {
        let destinationURL = try folder(named: "source-inside-destination", in: temporaryRoot)
        let sourceURL = try folder(named: "nested-source", in: destinationURL)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        XCTAssertThrowsError(
            try TransferPreflightValidator.validate(
                source: sourceURL,
                destination: destinationURL,
                sourceMetadata: metadata,
                destinationFreeSpaceBytes: 2048
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .sourceInsideDestination)
            XCTAssertEqual(
                (error as? TransferPreflightError)?.errorDescription,
                "Source cannot be inside the destination folder. Choose a separate destination outside the source/media tree."
            )
        }
    }

    func testPreflightBlocksExistingDestinationJobFolder() throws {
        let sourceURL = try folder(named: "A001", in: temporaryRoot)
        let destinationURL = try folder(named: "existing-job-destination", in: temporaryRoot)
        let existingJobURL = try folder(named: "A001", in: destinationURL)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        XCTAssertThrowsError(
            try TransferPreflightValidator.validate(
                source: sourceURL,
                destination: destinationURL,
                sourceMetadata: metadata,
                destinationFreeSpaceBytes: 2048
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .destinationJobFolderAlreadyExists(existingJobURL.path))
            XCTAssertEqual(
                (error as? TransferPreflightError)?.errorDescription,
                "Destination job folder already exists: \(existingJobURL.path). FST will not overwrite or merge into an existing job folder."
            )
        }
    }

    func testPreflightBlocksInsufficientDestinationSpace() throws {
        let sourceURL = try folder(named: "insufficient-space-source", in: temporaryRoot)
        let destinationURL = try folder(named: "insufficient-space-destination", in: temporaryRoot)
        let metadata = sourceMetadata(for: sourceURL, bytes: 2048, fileCount: 1)

        XCTAssertThrowsError(
            try TransferPreflightValidator.validate(
                source: sourceURL,
                destination: destinationURL,
                sourceMetadata: metadata,
                destinationFreeSpaceBytes: 1024
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .insufficientDestinationSpace(required: 2048, available: 1024))
            let message = (error as? TransferPreflightError)?.errorDescription ?? ""
            XCTAssertTrue(message.contains("Required: 2 KB"))
            XCTAssertTrue(message.contains("Available: 1 KB"))
            XCTAssertTrue(message.contains("2,048 bytes"))
            XCTAssertTrue(message.contains("1,024 bytes"))
            XCTAssertFalse(message == "Insufficient destination space. Required: 2048 bytes, Available: 1024 bytes.")
        }
    }

    func testPreflightBlocksUnknownDestinationFreeSpace() throws {
        let sourceURL = try folder(named: "unknown-space-source", in: temporaryRoot)
        let destinationURL = try folder(named: "unknown-space-destination", in: temporaryRoot)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        XCTAssertThrowsError(
            try TransferPreflightValidator.validate(
                source: sourceURL,
                destination: destinationURL,
                sourceMetadata: metadata,
                destinationFreeSpaceBytes: nil
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .unableToDetermineDestinationFreeSpace)
            XCTAssertEqual(
                (error as? TransferPreflightError)?.errorDescription,
                "Unable to determine destination free space. FST cannot safely start without confirming available space."
            )
        }
    }

    func testPreflightUsesExclusionAwareSourceSize() async throws {
        let sourceURL = try folder(named: "exclusion-aware-source", in: temporaryRoot)
        let destinationURL = try folder(named: "exclusion-aware-destination", in: temporaryRoot)
        try writeFile(".DS_Store", contents: "metadata", in: sourceURL)
        try writeFile("A001_C001.mov", contents: "media", in: sourceURL)

        let metadata = try await DriveService().sourceMetadata(for: sourceURL)
        let plan = try TransferPreflightValidator.validate(
            source: sourceURL,
            destination: destinationURL,
            sourceMetadata: metadata,
            destinationFreeSpaceBytes: metadata.totalSizeBytes
        )

        XCTAssertEqual(plan.transferableFileCount, 1)
        XCTAssertEqual(plan.transferableBytes, metadata.totalSizeBytes)
    }

    func testValidPreflightPasses() throws {
        let sourceURL = try folder(named: "valid-preflight-source", in: temporaryRoot)
        let destinationURL = try folder(named: "valid-preflight-destination", in: temporaryRoot)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        let plan = try TransferPreflightValidator.validate(
            source: sourceURL,
            destination: destinationURL,
            sourceMetadata: metadata,
            destinationFreeSpaceBytes: 4096
        )

        XCTAssertEqual(plan.destinationJobFolderURL.lastPathComponent, sourceURL.lastPathComponent)
        XCTAssertEqual(plan.transferableBytes, 1024)
        XCTAssertEqual(plan.destinationFreeSpaceBytes, 4096)
    }

    func testCoordinatorPreflightFailureDoesNotStartRsyncOrWriteReportInSource() async throws {
        let sourceURL = try folder(named: "coordinator-same-source-destination", in: temporaryRoot)
        try writeFile("A001_C001.mov", contents: "media", in: sourceURL)

        let coordinator = TransferCoordinator()
        let recorder = TransferCoordinatorRecorder()
        await coordinator.configureCallbacks(
            onStateChanged: { state in recorder.appendState(state) },
            onProgress: { _ in },
            onSpeed: { _ in },
            onETA: { _ in },
            onCurrentFile: { _ in },
            onError: { error in recorder.appendError(error) },
            onLog: { log in recorder.appendLog(log) }
        )

        await coordinator.startTransfer(
            source: sourceURL,
            destination: sourceURL,
            bandwidthLimit: nil,
            mode: .none
        )

        try await waitForCoordinatorError(recorder)
        let states = recorder.snapshotStates()
        let errors = recorder.snapshotErrors()
        let logMessages = recorder.snapshotLogs().map(\.message)

        XCTAssertTrue(states.contains(.error))
        XCTAssertFalse(states.contains(.copying))
        XCTAssertTrue(errors.contains("TRANSFER ERROR: Source and destination cannot be the same folder. Choose a separate destination."))
        XCTAssertFalse(logMessages.contains("Transfer Started"))
        XCTAssertFalse(logMessages.contains("TRANSFER COMPLETE. Verification disabled."))
        XCTAssertFalse(logMessages.contains("Verification Passed. SAFE TO EJECT."))
        XCTAssertTrue(logMessages.contains("Report skipped: no report was written because the destination was unsafe for report output."))
        XCTAssertFalse(try containsReportFile(in: sourceURL))
    }

    func testSourceInsideDestinationPreflightFailureDoesNotWriteReportOnSourceMedia() async throws {
        let cardURL = try folder(named: "CARD", in: temporaryRoot)
        let sourceURL = try folder(named: "DCIM", in: cardURL)
        try writeFile("A001_C001.mov", contents: "media", in: sourceURL)

        XCTAssertNil(TransferPreflightValidator.safeReportFolder(source: sourceURL, destination: cardURL))

        let coordinator = TransferCoordinator()
        let recorder = TransferCoordinatorRecorder()
        await coordinator.configureCallbacks(
            onStateChanged: { state in recorder.appendState(state) },
            onProgress: { _ in },
            onSpeed: { _ in },
            onETA: { _ in },
            onCurrentFile: { _ in },
            onError: { error in recorder.appendError(error) },
            onLog: { log in recorder.appendLog(log) }
        )

        await coordinator.startTransfer(
            source: sourceURL,
            destination: cardURL,
            bandwidthLimit: nil,
            mode: .none
        )

        try await waitForCoordinatorError(recorder)
        let states = recorder.snapshotStates()
        let errors = recorder.snapshotErrors()
        let logMessages = recorder.snapshotLogs().map(\.message)

        XCTAssertTrue(states.contains(.error))
        XCTAssertFalse(states.contains(.copying))
        XCTAssertTrue(errors.contains("TRANSFER ERROR: Source cannot be inside the destination folder. Choose a separate destination outside the source/media tree."))
        XCTAssertFalse(logMessages.contains("Transfer Started"))
        XCTAssertFalse(logMessages.contains("TRANSFER COMPLETE. Verification disabled."))
        XCTAssertFalse(logMessages.contains("Verification Passed. SAFE TO EJECT."))
        XCTAssertTrue(logMessages.contains("Report skipped: no report was written because the destination was unsafe for report output."))
        XCTAssertFalse(try containsReportFile(in: cardURL))
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

    private func waitForCoordinatorError(_ recorder: TransferCoordinatorRecorder) async throws {
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            if recorder.snapshotStates().contains(.error),
               recorder.snapshotLogs().contains(where: { $0.message == "Report skipped: no report was written because the destination was unsafe for report output." }) {
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTFail("Coordinator did not reach preflight error before timeout.")
    }

    private func containsReportFile(in folderURL: URL) throws -> Bool {
        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: []
        ) else {
            return false
        }

        for case let itemURL as URL in enumerator {
            let values = try itemURL.resourceValues(forKeys: [.isRegularFileKey])
            if values.isRegularFile == true, itemURL.lastPathComponent.hasPrefix("FST_Report_") {
                return true
            }
        }
        return false
    }

    private func sourceMetadata(for sourceURL: URL, bytes: Int64, fileCount: Int) -> SourceStorageMetadata {
        SourceStorageMetadata(
            folderName: sourceURL.lastPathComponent,
            fullPath: sourceURL.path,
            totalSizeBytes: bytes,
            fileCount: fileCount,
            folderCount: 0
        )
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
