// FST / CenVu | (+84) 842 841 222

import XCTest
import CryptoKit

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

    func testDriveServiceCountsSparseLogicalBytesWithoutMutatingSource() async throws {
        let source = try folder(named: "logical-sparse-source", in: temporaryRoot)
        let logical: Int64 = 1_073_741_824
        let file = try writeSparseFile("clip.bin", logicalBytes: logical, in: source)
        let before = try file.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey, .isSparseKey, .contentModificationDateKey])
        XCTAssertEqual(before.fileSize, Int(logical))
        XCTAssertEqual(before.isSparse, true)
        XCTAssertLessThan(try XCTUnwrap(before.totalFileAllocatedSize), Int(logical))

        let drive = DriveService()
        let metadata = try await drive.sourceMetadata(for: source)
        let calculated = try await drive.calculateFolderSize(at: source)
        XCTAssertEqual(metadata.totalSizeBytes, logical)
        XCTAssertEqual(calculated, logical)
        let assessment = try await drive.assessCapacity(source: source, destination: temporaryRoot)
        XCTAssertEqual(assessment.assessment.logicalPayloadBytes, logical)
        XCTAssertEqual(assessment.assessment.admissionFloorBytes, logical)
        XCTAssertEqual(metadata.fileCount, 1)
        let after = try URL(fileURLWithPath: file.path).resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey, .contentModificationDateKey])
        XCTAssertEqual(after.fileSize, before.fileSize)
        XCTAssertEqual(after.totalFileAllocatedSize, before.totalFileAllocatedSize)
        XCTAssertEqual(after.contentModificationDate, before.contentModificationDate)
        let reader = try FileHandle(forReadingFrom: file)
        defer { try? reader.close() }
        XCTAssertEqual(try reader.read(upToCount: 1), Data([0x5a]))
        try reader.seek(toOffset: UInt64(logical - 1))
        XCTAssertEqual(try reader.read(upToCount: 1), Data([0x5b]))
    }

    func testDriveServiceCountsOrdinaryFileLogicalBytes() async throws {
        let source = try folder(named: "logical-ordinary-source", in: temporaryRoot)
        let file = source.appendingPathComponent("ordinary.mov")
        let contents = Data(repeating: 0x7f, count: 65_536)
        try contents.write(to: file)

        let metadata = try await DriveService().sourceMetadata(for: source)
        XCTAssertEqual(metadata.totalSizeBytes, Int64(contents.count))
        XCTAssertEqual(metadata.fileCount, 1)
        XCTAssertEqual(try Data(contentsOf: file), contents)
    }

    func testDriveServiceSumsLogicalBytesAndIgnoresExcludedFiles() async throws {
        let source = try folder(named: "logical-multi-source", in: temporaryRoot)
        let nested = try folder(named: "clips", in: source)
        let excluded = try folder(named: ".Spotlight-V100", in: source)
        let logical: Int64 = 1_073_741_824
        _ = try writeSparseFile("sparse.bin", logicalBytes: logical, in: source)
        try Data(repeating: 0x41, count: 333).write(to: nested.appendingPathComponent("small.mov"))
        try Data(repeating: 0x42, count: 8192).write(to: source.appendingPathComponent("ordinary.mov"))
        try Data().write(to: source.appendingPathComponent("empty.mov"))
        _ = try writeSparseFile(".DS_Store", logicalBytes: logical, in: source)
        _ = try writeSparseFile("._clip", logicalBytes: logical, in: source)
        _ = try writeSparseFile("ignored.bin", logicalBytes: logical, in: excluded)

        let metadata = try await DriveService().sourceMetadata(for: source)
        XCTAssertEqual(metadata.totalSizeBytes, logical + 333 + 8192)
        XCTAssertEqual(metadata.fileCount, 4)
        XCTAssertEqual(metadata.folderCount, 1)
        let assessment = try await DriveService().assessCapacity(source: source, destination: temporaryRoot)
        XCTAssertEqual(assessment.assessment.logicalPayloadBytes, logical + 333 + 8192)
        XCTAssertEqual(assessment.assessment.admissionFloorBytes, logical + 4096 + 8192)
    }

    func testSparseLogicalPreflightBlocksInsufficientSpaceAndAllowsEnough() async throws {
        let source = try folder(named: "logical-preflight-source", in: temporaryRoot)
        let destination = try folder(named: "logical-preflight-destination", in: temporaryRoot)
        let logical: Int64 = 1_073_741_824
        _ = try writeSparseFile("clip.bin", logicalBytes: logical, in: source)
        let metadata = try await DriveService().sourceMetadata(for: source)

        XCTAssertThrowsError(try TransferPreflightValidator.validate(
            source: source, destination: destination, sourceMetadata: metadata,
            destinationMetadata: .init(freeSpaceBytes: logical - 1, filesystem: "Unknown", isWritable: true)
        )) { error in
            XCTAssertEqual(error as? TransferPreflightError,
                           .insufficientDestinationSpace(required: logical, available: logical - 1))
        }
        let plan = try TransferPreflightValidator.validate(
            source: source, destination: destination, sourceMetadata: metadata,
            destinationMetadata: .init(freeSpaceBytes: logical, filesystem: "Unknown", isWritable: true)
        )
        XCTAssertEqual(plan.transferableBytes, logical)
        XCTAssertEqual(plan.transferableFileCount, 1)
    }

    func testDestinationObserverBoundsUseScannedLogicalTotal() async throws {
        let source = try folder(named: "logical-observer-source", in: temporaryRoot)
        let destination = try folder(named: "logical-observer-destination", in: temporaryRoot)
        let logical: Int64 = 1_073_741_824
        _ = try writeSparseFile("clip.bin", logicalBytes: logical, in: source)
        let partial = try writeSparseFile("clip.bin", logicalBytes: logical / 2, in: destination)
        let metadata = try await DriveService().sourceMetadata(for: source)
        let now = Date()
        let first = try DestinationActivitySnapshotter.snapshot(
            destinationRootURL: destination, totalBytes: metadata.totalSizeBytes,
            totalFiles: metadata.fileCount, copyStartedAt: now.addingTimeInterval(-10),
            previousSamples: [], now: now
        )
        XCTAssertEqual(first.snapshot.totalBytes, logical)
        XCTAssertEqual(first.snapshot.copiedBytes, logical / 2)
        XCTAssertEqual(try XCTUnwrap(first.snapshot.progressFraction), 0.5, accuracy: 0.0001)
        let writer = try FileHandle(forWritingTo: partial)
        try writer.truncate(atOffset: UInt64(logical))
        try writer.close()
        let final = try DestinationActivitySnapshotter.snapshot(
            destinationRootURL: destination, totalBytes: metadata.totalSizeBytes,
            totalFiles: metadata.fileCount, copyStartedAt: now.addingTimeInterval(-10),
            previousSamples: first.samples, now: now.addingTimeInterval(1)
        ).snapshot
        XCTAssertEqual(final.copiedBytes, logical)
        XCTAssertEqual(final.totalBytes, logical)
        XCTAssertEqual(try XCTUnwrap(final.progressFraction), 1, accuracy: 0.0001)
    }

    func testDriveServiceCountsCompressedFileLogicalBytes() async throws {
        let source = try folder(named: "logical-compressed-source", in: temporaryRoot)
        let input = temporaryRoot.appendingPathComponent("uncompressed.bin")
        let compressed = source.appendingPathComponent("clip.bin")
        let contents = Data(repeating: 0x5a, count: 8 * 1024 * 1024)
        try contents.write(to: input)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["--hfsCompression", input.path, compressed.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        let values = try compressed.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey])
        let allocated = try XCTUnwrap(values.totalFileAllocatedSize)
        guard allocated < contents.count else {
            throw XCTSkip("Fixture filesystem did not create a compressed allocation.")
        }
        XCTAssertEqual(values.fileSize, contents.count)

        let metadata = try await DriveService().sourceMetadata(for: source)
        XCTAssertEqual(metadata.totalSizeBytes, Int64(contents.count))
        let assessment = try await DriveService().assessCapacity(source: source, destination: temporaryRoot)
        XCTAssertEqual(assessment.assessment.logicalPayloadBytes, Int64(contents.count))
        XCTAssertEqual(assessment.assessment.admissionFloorBytes, Int64(contents.count))
        XCTAssertEqual(try Data(contentsOf: compressed), contents)
    }

    func testDriveServiceScanHonorsCancellation() async throws {
        let source = try folder(named: "logical-cancelled-source", in: temporaryRoot)
        try writeFile("clip.bin", contents: "contents", in: source)
        let drive = DriveService()
        let scan = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await drive.sourceMetadata(for: source)
        }
        do {
            _ = try await scan.value
            XCTFail("A cancelled scan must not return metadata.")
        } catch is CancellationError {
            XCTAssertEqual(try String(contentsOf: source.appendingPathComponent("clip.bin"), encoding: .utf8), "contents")
        }
    }

    private func writeSparseFile(_ name: String, logicalBytes: Int64, in folder: URL) throws -> URL {
        let file = folder.appendingPathComponent(name)
        guard FileManager.default.createFile(atPath: file.path, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        try handle.write(contentsOf: Data([0x5a]))
        try handle.seek(toOffset: UInt64(logicalBytes - 1))
        try handle.write(contentsOf: Data([0x5b]))
        return file
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
                destinationMetadata: .init(freeSpaceBytes: 2048, filesystem: "Unknown", isWritable: true)
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
                destinationMetadata: .init(freeSpaceBytes: 2048, filesystem: "Unknown", isWritable: true)
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
                destinationMetadata: .init(freeSpaceBytes: 2048, filesystem: "Unknown", isWritable: true)
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .sourceInsideDestination)
            XCTAssertEqual(
                (error as? TransferPreflightError)?.errorDescription,
                "Source cannot be inside the destination folder. Choose a separate destination outside the source/media tree."
            )
        }
    }

    func testPreflightAllowsAbsentDestinationJobPath() throws {
        let sourceURL = try folder(named: "absent-job-path-source", in: temporaryRoot)
        let destinationURL = try folder(named: "absent-job-path-destination", in: temporaryRoot)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        let plan = try TransferPreflightValidator.validate(
            source: sourceURL,
            destination: destinationURL,
            sourceMetadata: metadata,
            destinationMetadata: .init(freeSpaceBytes: 2048, filesystem: "Unknown", isWritable: true)
        )

        XCTAssertEqual(plan.destinationJobFolderURL.path, destinationURL.appendingPathComponent(sourceURL.lastPathComponent).path)
    }

    func testPreflightBlocksExistingEmptyDestinationJobDirectory() throws {
        let sourceURL = try folder(named: "A001", in: temporaryRoot)
        let destinationURL = try folder(named: "existing-empty-job-destination", in: temporaryRoot)
        let existingJobURL = try folder(named: "A001", in: destinationURL)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        assertPreflightBlocksExistingJobPath(sourceURL: sourceURL, destinationURL: destinationURL, expectedPath: existingJobURL.path, metadata: metadata)
    }

    func testPreflightBlocksExistingDestinationJobDirectoryWithFiles() throws {
        let sourceURL = try folder(named: "A002", in: temporaryRoot)
        let destinationURL = try folder(named: "existing-nonempty-job-destination", in: temporaryRoot)
        let existingJobURL = try folder(named: "A002", in: destinationURL)
        try writeFile("existing.mov", contents: "already copied", in: existingJobURL)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        assertPreflightBlocksExistingJobPath(sourceURL: sourceURL, destinationURL: destinationURL, expectedPath: existingJobURL.path, metadata: metadata)
    }

    func testPreflightBlocksExistingRegularFileAtDestinationJobPath() throws {
        let sourceURL = try folder(named: "A003", in: temporaryRoot)
        let destinationURL = try folder(named: "existing-file-job-destination", in: temporaryRoot)
        try writeFile("A003", contents: "not a directory", in: destinationURL)
        let existingJobURL = destinationURL.appendingPathComponent("A003")
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        assertPreflightBlocksExistingJobPath(sourceURL: sourceURL, destinationURL: destinationURL, expectedPath: existingJobURL.path, metadata: metadata)
    }

    func testPreflightBlocksExistingSymlinkAtDestinationJobPath() throws {
        let sourceURL = try folder(named: "A004", in: temporaryRoot)
        let destinationURL = try folder(named: "existing-symlink-job-destination", in: temporaryRoot)
        let symlinkTargetURL = try folder(named: "symlink-target", in: temporaryRoot)
        let existingJobURL = destinationURL.appendingPathComponent("A004")
        try FileManager.default.createSymbolicLink(at: existingJobURL, withDestinationURL: symlinkTargetURL)
        let metadata = sourceMetadata(for: sourceURL, bytes: 1024, fileCount: 1)

        assertPreflightBlocksExistingJobPath(sourceURL: sourceURL, destinationURL: destinationURL, expectedPath: existingJobURL.path, metadata: metadata)
    }

    private func assertPreflightBlocksExistingJobPath(
        sourceURL: URL,
        destinationURL: URL,
        expectedPath: String,
        metadata: SourceStorageMetadata
    ) {
        XCTAssertThrowsError(
            try TransferPreflightValidator.validate(
                source: sourceURL,
                destination: destinationURL,
                sourceMetadata: metadata,
                destinationMetadata: .init(freeSpaceBytes: 2048, filesystem: "Unknown", isWritable: true)
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .destinationJobPathAlreadyExists(expectedPath))
            XCTAssertEqual(
                (error as? TransferPreflightError)?.errorDescription,
                "Destination job path already exists: \(expectedPath). Choose a new destination or create a new unique folder. FST will not merge or overwrite existing job data."
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
                destinationMetadata: .init(freeSpaceBytes: 1024, filesystem: "Unknown", isWritable: true)
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .insufficientDestinationSpace(required: 2048, available: 1024))
            let message = (error as? TransferPreflightError)?.errorDescription ?? ""
            XCTAssertTrue(message.contains("Floor: 2 KB"))
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
                destinationMetadata: .init(freeSpaceBytes: -1, filesystem: "Unknown", isWritable: true)
            )
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .unableToDetermineDestinationFreeSpace)
            XCTAssertEqual(
                (error as? TransferPreflightError)?.errorDescription,
                "Unable to determine destination free space. FST cannot safely start without confirming available space."
            )
        }
    }

    func testCapacitySelectionFallsBackWhenImportantUsageIsMisleadingZero() throws {
        let ordinaryCapacity = 733_642_752

        XCTAssertEqual(
            try DriveService.selectAvailableCapacity(importantUsage: 0, ordinary: ordinaryCapacity),
            Int64(ordinaryCapacity)
        )
    }

    func testCapacitySelectionFallsBackWhenImportantUsageIsUnavailable() throws {
        let ordinaryCapacity = 730_906_624

        XCTAssertEqual(
            try DriveService.selectAvailableCapacity(importantUsage: nil, ordinary: ordinaryCapacity),
            Int64(ordinaryCapacity)
        )
    }

    func testCapacitySelectionPrefersPositiveImportantUsage() throws {
        XCTAssertEqual(
            try DriveService.selectAvailableCapacity(importantUsage: 8_192, ordinary: 4_096),
            8_192
        )
    }

    func testCapacitySelectionPreservesGenuinelyFullOrdinaryVolume() throws {
        XCTAssertEqual(
            try DriveService.selectAvailableCapacity(importantUsage: 0, ordinary: 0),
            0
        )
    }

    func testCapacitySelectionThrowsWhenNoUsableSignalExists() {
        XCTAssertThrowsError(
            try DriveService.selectAvailableCapacity(importantUsage: nil, ordinary: nil)
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .unableToDetermineDestinationFreeSpace)
        }

        XCTAssertThrowsError(
            try DriveService.selectAvailableCapacity(importantUsage: nil, ordinary: -1)
        ) { error in
            XCTAssertEqual(error as? TransferPreflightError, .unableToDetermineDestinationFreeSpace)
        }
    }

    func testCapacitySelectionFallsBackWhenImportantUsageIsNegative() throws {
        XCTAssertEqual(
            try DriveService.selectAvailableCapacity(importantUsage: -1, ordinary: 4_096),
            4_096
        )
    }

    @MainActor
    func testOrdinaryFallbackCapacityKeepsStartEligibleWhenSourceFits() throws {
        let sourceURL = try folder(named: "ordinary-fallback-source", in: temporaryRoot)
        let destinationURL = try folder(named: "ordinary-fallback-destination", in: temporaryRoot)
        let requiredBytes: Int64 = 1_024
        let selectedCapacity = try DriveService.selectAvailableCapacity(
            importantUsage: 0,
            ordinary: 4_096
        )
        let viewModel = TransferViewModel()

        viewModel.sourceURL = sourceURL
        viewModel.destinationURL = destinationURL
        viewModel.sourceMetadata = sourceMetadata(for: sourceURL, bytes: requiredBytes, fileCount: 1)
        viewModel.destinationMetadata = DestinationStorageMetadata(
            freeSpaceBytes: selectedCapacity,
            filesystem: "Test",
            isWritable: true
        )
        viewModel.bundledRsyncInfo = BundledRsyncInfo(
            executableURL: destinationURL,
            version: BundledRsyncService.bundledVersion,
            diagnostics: []
        )

        XCTAssertLessThan(requiredBytes, selectedCapacity)
        XCTAssertFalse(viewModel.hasInsufficientDestinationSpace)
        XCTAssertTrue(viewModel.canStartTransfer)
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
            destinationMetadata: .init(freeSpaceBytes: metadata.totalSizeBytes, filesystem: "Unknown", isWritable: true)
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
            destinationMetadata: .init(freeSpaceBytes: 4096, filesystem: "Unknown", isWritable: true)
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
            onTransferTime: { _ in },
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

    func testRepeatedStartAdmitsExactlyOneWorkflow() async {
        let sourceURL = temporaryRoot.appendingPathComponent("missing-source", isDirectory: true)
        let destinationURL = temporaryRoot.appendingPathComponent("missing-source", isDirectory: true)
        let coordinator = TransferCoordinator()

        let statesAfterRequests = await issueRepeatedStartsWithoutSuspension(
            on: coordinator,
            source: sourceURL,
            destination: destinationURL
        )

        XCTAssertEqual(
            statesAfterRequests,
            [.validating, .validating],
            "The first request must reserve validation synchronously, and the second must leave that single reservation unchanged."
        )
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
            onTransferTime: { _ in },
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

    func testExistingDestinationJobPathPreflightFailureDoesNotStartRsyncOrWriteReportInExistingJobDirectory() async throws {
        let sourceURL = try folder(named: "coordinator-existing-job-source", in: temporaryRoot)
        try writeFile("A001_C001.mov", contents: "media", in: sourceURL)
        let destinationURL = try folder(named: "coordinator-existing-job-destination", in: temporaryRoot)
        let existingJobURL = try folder(named: sourceURL.lastPathComponent, in: destinationURL)
        try writeFile("existing.mov", contents: "already here", in: existingJobURL)

        XCTAssertEqual(TransferPreflightValidator.safeReportFolder(source: sourceURL, destination: destinationURL), destinationURL)

        let coordinator = TransferCoordinator()
        let recorder = TransferCoordinatorRecorder()
        await coordinator.configureCallbacks(
            onStateChanged: { state in recorder.appendState(state) },
            onProgress: { _ in },
            onSpeed: { _ in },
            onTransferTime: { _ in },
            onCurrentFile: { _ in },
            onError: { error in recorder.appendError(error) },
            onLog: { log in recorder.appendLog(log) }
        )

        await coordinator.startTransfer(
            source: sourceURL,
            destination: destinationURL,
            bandwidthLimit: nil,
            mode: .none
        )

        try await waitForCoordinatorTerminalReport(recorder)
        let states = recorder.snapshotStates()
        let errors = recorder.snapshotErrors()
        let logMessages = recorder.snapshotLogs().map(\.message)

        XCTAssertTrue(states.contains(.error))
        XCTAssertFalse(states.contains(.copying))
        XCTAssertTrue(errors.contains("TRANSFER ERROR: Destination job path already exists: \(existingJobURL.path). Choose a new destination or create a new unique folder. FST will not merge or overwrite existing job data."))
        XCTAssertFalse(logMessages.contains("Transfer Started"))
        XCTAssertFalse(logMessages.contains("TRANSFER COMPLETE. Verification disabled."))
        XCTAssertFalse(logMessages.contains("Verification Passed. SAFE TO EJECT."))
        XCTAssertFalse(try containsReportFile(in: existingJobURL))
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

    private func issueRepeatedStartsWithoutSuspension(
        on coordinator: isolated TransferCoordinator,
        source: URL,
        destination: URL
    ) -> [TransferState] {
        coordinator.startTransfer(source: source, destination: destination, bandwidthLimit: nil, mode: .none)
        let stateAfterFirstRequest = coordinator.state
        coordinator.startTransfer(source: source, destination: destination, bandwidthLimit: nil, mode: .none)
        let stateAfterSecondRequest = coordinator.state
        return [stateAfterFirstRequest, stateAfterSecondRequest]
    }

    private func waitForCoordinatorTerminalReport(_ recorder: TransferCoordinatorRecorder) async throws {
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            if recorder.snapshotStates().contains(.error),
               recorder.snapshotLogs().contains(where: { $0.message.hasPrefix("Report saved: ") || $0.message == "Report skipped: no report was written because the destination was unsafe for report output." }) {
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTFail("Coordinator did not reach preflight error/report completion before timeout.")
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

final class DestinationCapacityPolicyXCTests: XCTestCase {
    private let source = URL(fileURLWithPath: "/tmp/fst-capacity-policy/source")
    private let destination = URL(fileURLWithPath: "/tmp/fst-capacity-policy/destination")

    func testFreshReadOnlyEvidenceRejectsOldWritableAdmission() throws {
        let before = DestinationStorageMetadata(freeSpaceBytes: 4096, filesystem: "APFS", isWritable: true,
            filesystemIdentity: "apfs", allocationUnit: 4096)
        let fresh = DestinationStorageMetadata(freeSpaceBytes: 4096, filesystem: "APFS", isWritable: false,
            filesystemIdentity: "apfs", allocationUnit: 4096)
        XCTAssertTrue(before.isWritable)
        XCTAssertFalse(fresh.isWritable)
        let a = try DestinationCapacityAssessment.make(source: source, destination: destination,
            logicalPayloadBytes: 1, roundedPayloadBytes: 4096, snapshot: fresh)
        let metadata = SourceStorageMetadata(folderName: "source", fullPath: source.path,
            totalSizeBytes: 1, fileCount: 1, folderCount: 0)
        XCTAssertThrowsError(try TransferPreflightValidator.validate(source: source, destination: destination,
            sourceMetadata: metadata, destinationMetadata: fresh, capacityAssessment: a)) {
            XCTAssertEqual($0 as? TransferError, .destinationUnavailable)
        }
    }

    func testFinalWritableEvidenceWinsAndPolicyBoundariesRemainUnchanged() throws {
        let old = DestinationStorageMetadata(freeSpaceBytes: 4096, filesystem: "Unknown", isWritable: false)
        XCTAssertFalse(old.isWritable)
        let metadata = SourceStorageMetadata(folderName: "source", fullPath: source.path,
            totalSizeBytes: 1, fileCount: 1, folderCount: 0)
        for (identity, unit): (String?, Int64?) in [("apfs",4096),("apfs",8192),("exfat",512),("futurefs",nil),(nil,nil)] {
            let floor: Int64 = identity == "apfs" && unit == 4096 ? 4096 : 1
            for available in [floor, floor - 1] {
                let fresh = DestinationStorageMetadata(freeSpaceBytes: available, filesystem: "Display only",
                    isWritable: true, filesystemIdentity: identity, allocationUnit: unit)
                let a = try DestinationCapacityAssessment.make(source: source, destination: destination,
                    logicalPayloadBytes: 1, roundedPayloadBytes: 4096, snapshot: fresh)
                if available == floor {
                    let plan = try TransferPreflightValidator.validate(source: source, destination: destination,
                        sourceMetadata: metadata, destinationMetadata: fresh, capacityAssessment: a)
                    XCTAssertEqual(plan.transferableBytes, 1)
                    XCTAssertEqual(plan.admissionFloorBytes, floor)
                    XCTAssertEqual(plan.capacityAssessment.hasUnvalidatedAllocation, floor == 1)
                } else {
                    XCTAssertThrowsError(try TransferPreflightValidator.validate(source: source, destination: destination,
                        sourceMetadata: metadata, destinationMetadata: fresh, capacityAssessment: a)) {
                        XCTAssertEqual($0 as? TransferPreflightError,
                            .insufficientDestinationSpace(required: floor, available: available))
                    }
                }
            }
        }
    }

    func testOldAssessmentCannotOverrideFinalReadOnlyMetadata() throws {
        let oldAssessment = try assessment()
        let fresh = DestinationStorageMetadata(freeSpaceBytes: 4096, filesystem: "APFS", isWritable: false,
            filesystemIdentity: "apfs", allocationUnit: 4096)
        let metadata = SourceStorageMetadata(folderName: "source", fullPath: source.path,
            totalSizeBytes: 1, fileCount: 1, folderCount: 0)
        XCTAssertThrowsError(try TransferPreflightValidator.validate(source: source, destination: destination,
            sourceMetadata: metadata, destinationMetadata: fresh, capacityAssessment: oldAssessment)) {
            XCTAssertEqual($0 as? TransferError, .destinationUnavailable)
            XCTAssertEqual($0.localizedDescription, "The destination location is unavailable or cannot be written.")
        }
    }

    func testFinalProfileAndCapacityMustMatchAssessment() throws {
        let oldAssessment = try assessment()
        let metadata = SourceStorageMetadata(folderName: "source", fullPath: source.path,
            totalSizeBytes: 1, fileCount: 1, folderCount: 0)
        for fresh in [
            DestinationStorageMetadata(freeSpaceBytes: 4096, filesystem: "APFS", isWritable: true,
                filesystemIdentity: "exfat", allocationUnit: 4096),
            DestinationStorageMetadata(freeSpaceBytes: 4096, filesystem: "APFS", isWritable: true,
                filesystemIdentity: "apfs", allocationUnit: 8192),
            DestinationStorageMetadata(freeSpaceBytes: 8192, filesystem: "APFS", isWritable: true,
                filesystemIdentity: "apfs", allocationUnit: 4096)
        ] {
            XCTAssertThrowsError(try TransferPreflightValidator.validate(source: source, destination: destination,
                sourceMetadata: metadata, destinationMetadata: fresh, capacityAssessment: oldAssessment)) {
                XCTAssertEqual($0 as? TransferPreflightError, .invalidCapacityEvidence)
            }
        }
    }

    private func assessment(identity: String? = "apfs", unit: Int64? = 4096,
                            logical: Int64 = 1, rounded: Int64? = 4096, available: Int64 = 4096,
                            display: String = "Localized display") throws -> DestinationCapacityAssessment {
        try .make(source: source, destination: destination, logicalPayloadBytes: logical,
                  roundedPayloadBytes: rounded,
                  snapshot: .init(freeSpaceBytes: available, filesystem: display, isWritable: true,
                                  filesystemIdentity: identity, allocationUnit: unit))
    }

    func testRoundingBoundaries() throws {
        for (size, expected): (Int64, Int64) in [(0,0),(1,4096),(4095,4096),(4096,4096),(4097,8192),
                                                (16_777_339,16_781_312)] {
            XCTAssertEqual(try CapacityArithmetic.roundUp(size, unit: 4096), expected)
        }
    }
    func testManySmallRoundedSum() throws {
        var logical: Int64 = 0, rounded: Int64 = 0
        for _ in 0..<1024 {
            logical = try CapacityArithmetic.add(logical, 1)
            rounded = try CapacityArithmetic.add(rounded, CapacityArithmetic.roundUp(1, unit: 4096))
        }
        XCTAssertEqual(logical, 1024)
        XCTAssertEqual(rounded, 4_194_304)
    }
    func testNearInt64OverflowFailsSafely() throws {
        XCTAssertEqual(try CapacityArithmetic.roundUp(Int64.max - 4095, unit: 4096), Int64.max - 4095)
        XCTAssertThrowsError(try CapacityArithmetic.roundUp(Int64.max, unit: 4096)) {
            XCTAssertEqual($0 as? TransferPreflightError, .capacityArithmeticOverflow)
        }
    }
    func testSumOverflowFailsSafely() {
        XCTAssertThrowsError(try CapacityArithmetic.add(Int64.max, 1)) {
            XCTAssertEqual($0 as? TransferPreflightError, .capacityArithmeticOverflow)
        }
    }
    func testInvalidUnitAndNegativeSizeFail() {
        for unit: Int64 in [0, -1] { XCTAssertThrowsError(try CapacityArithmetic.roundUp(1, unit: unit)) }
        XCTAssertThrowsError(try CapacityArithmetic.roundUp(-1, unit: 4096))
        XCTAssertThrowsError(try CapacityArithmetic.add(-1, 1))
    }
    func testAPFSValidatedUsesRoundedFloor() throws {
        let a = try assessment()
        XCTAssertEqual(a.admissionFloorBytes, 4096)
        XCTAssertEqual(a.logicalPayloadBytes, 1)
        XCTAssertEqual(a.policyKind, .validatedAPFSRounded)
        XCTAssertFalse(a.hasUnvalidatedAllocation)
    }
    func testLocalizedDisplayNeverControlsPolicy() throws {
        XCTAssertEqual(try assessment(display: "日本語").policyKind, .validatedAPFSRounded)
        XCTAssertEqual(try assessment(identity: "exfat", unit: 512, display: "APFS").admissionFloorBytes, 1)
        XCTAssertEqual(try assessment(identity: nil, unit: nil, display: "APFS").policyKind, .logicalOnlyUnvalidated)
    }
    func testUnexpectedOrMissingAPFSUnitWarnsWithLogicalFloor() throws {
        for unit: Int64? in [nil, 0, -1, 512, 8192] {
            let a = try assessment(unit: unit)
            XCTAssertEqual(a.admissionFloorBytes, 1)
            XCTAssertTrue(a.hasUnvalidatedAllocation)
        }
    }
    func testExfat512AndUnknownWarnWithLogicalFloor() throws {
        for identity: String? in ["exfat", "futurefs", nil] {
            let a = try assessment(identity: identity, unit: 512, rounded: nil, available: 1)
            XCTAssertEqual(a.admissionFloorBytes, 1)
            XCTAssertTrue(a.passesCapacityPrecheck)
            XCTAssertEqual(a.uncertaintyKind, .allocationOverheadUnvalidated)
        }
    }
    func testProbeFailureIsUnvalidated() throws {
        XCTAssertNil(DriveService.filesystemProfile(at: URL(fileURLWithPath: "/nonexistent/fst-\(UUID())")))
        XCTAssertEqual(try assessment(identity: nil, unit: nil, rounded: nil).policyKind, .logicalOnlyUnvalidated)
    }
    func testEqualityPassesAndFloorMinusOneFailsForBothPolicies() throws {
        for identity in ["apfs", "exfat", "unknown"] {
            let floor: Int64 = identity == "apfs" ? 4096 : 1
            XCTAssertTrue(try assessment(identity: identity, available: floor).passesCapacityPrecheck)
            XCTAssertFalse(try assessment(identity: identity, available: floor - 1).passesCapacityPrecheck)
        }
    }
    func testTinyFileAPFSBlocksOldLogicalAdmission() throws {
        let a = try assessment(logical: 1024, rounded: 4_194_304, available: 1024)
        XCTAssertFalse(a.passesCapacityPrecheck)
        let metadata = SourceStorageMetadata(folderName: "source", fullPath: source.path, totalSizeBytes: 1024,
                                             fileCount: 1024, folderCount: 0)
        XCTAssertThrowsError(try TransferPreflightValidator.validate(source: source, destination: destination,
            sourceMetadata: metadata, destinationMetadata: .init(freeSpaceBytes: 1024, filesystem: "APFS", isWritable: true, filesystemIdentity: "apfs", allocationUnit: 4096), capacityAssessment: a)) {
            XCTAssertEqual($0 as? TransferPreflightError, .insufficientDestinationSpace(required: 4_194_304, available: 1024))
        }
    }
    func testAlignedAPFSAndPlanKeepLogicalProgress() throws {
        for (logical, rounded): (Int64, Int64) in [(4096,4096),(1,4096)] {
            let a = try assessment(logical: logical, rounded: rounded)
            let metadata = SourceStorageMetadata(folderName: "source", fullPath: source.path,
                totalSizeBytes: logical, fileCount: 1, folderCount: 0)
            let plan = try TransferPreflightValidator.validate(source: source, destination: destination,
                sourceMetadata: metadata, destinationMetadata: .init(freeSpaceBytes: 4096, filesystem: "APFS", isWritable: true, filesystemIdentity: "apfs", allocationUnit: 4096), capacityAssessment: a)
            XCTAssertEqual(plan.transferableBytes, logical)
            XCTAssertEqual(plan.admissionFloorBytes, rounded)
        }
    }
    func testChangedDestinationRejectsOldAssessment() throws {
        let a = try assessment()
        let newDestination = destination.appendingPathComponent("new")
        XCTAssertFalse(a.matches(source: source, destination: newDestination))
        let metadata = SourceStorageMetadata(folderName: "source", fullPath: source.path,
            totalSizeBytes: 1, fileCount: 1, folderCount: 0)
        XCTAssertThrowsError(try TransferPreflightValidator.validate(source: source, destination: newDestination,
            sourceMetadata: metadata, destinationMetadata: .init(freeSpaceBytes: 4096, filesystem: "APFS", isWritable: true, filesystemIdentity: "apfs", allocationUnit: 4096), capacityAssessment: a)) {
            XCTAssertEqual($0 as? TransferPreflightError, .invalidCapacityEvidence)
        }
    }
    func testMissingRoundedEvidenceAndInvalidCapacityFailSafely() {
        XCTAssertThrowsError(try assessment(rounded: nil))
        XCTAssertThrowsError(try assessment(logical: 4097))
        XCTAssertThrowsError(try assessment(available: -1))
    }
    func testSafetyPresentationAndPrivacyRedaction() throws {
        XCTAssertEqual(DestinationCapacityAssessment.passedStatus, "CAPACITY PRECHECK PASSED")
        let apfs = try assessment(), exfat = try assessment(identity: "exfat", unit: 512)
        XCTAssertTrue(apfs.supportingText.contains("may still require additional space"))
        XCTAssertTrue(exfat.supportingText.contains("does not guarantee"))
        XCTAssertTrue(exfat.hasUnvalidatedAllocation)
        XCTAssertEqual(apfs.marginAboveFloorBytes, 0)
        let error = TransferPreflightError.insufficientDestinationSpace(required: 4096, available: 1).localizedDescription
        XCTAssertTrue(error.contains("Floor:"))
        XCTAssertFalse(error.contains("Required:"))
        XCTAssertEqual(DestinationCapacityAssessment.notificationFailureSummary("TRANSFER ERROR: " + error),
                       "Transfer failed. Keep the source media.")
        XCTAssertEqual(DestinationCapacityAssessment.notificationFailureSummary("I/O failure"), "I/O failure")
        XCTAssertNil(DestinationCapacityAssessment.notificationFailureSummary(nil))
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let view = try String(contentsOf: repo.appendingPathComponent("FishSockTransfer/Views/StorageAnalysisView.swift"), encoding: .utf8)
        XCTAssertFalse(view.contains("STORAGE READY"))
        XCTAssertFalse(view.contains("Remaining After Copy"))
        XCTAssertFalse(view.contains("SAFE TO EJECT"))
        XCTAssertFalse(view.contains("== \"apfs\""))
        XCTAssertTrue(view.contains("exclamationmark.triangle.fill"))
    }
    func testCancelledDestinationAssessmentDoesNotReturnEvidence() async throws {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await DriveService().assessCapacity(source: source, destination: destination)
        }
        do { _ = try await task.value; XCTFail("Cancelled assessment must fail") }
        catch is CancellationError {}
    }

    @MainActor func testRoundedFloorDrivesViewModelWhileObserverAndProgressKeepLogicalPayload() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("FSTCapacityObserver-\(UUID())", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        try Data(repeating: 0x41, count: 8192).write(to: root.appendingPathComponent("clip"))
        let vm = TransferViewModel(bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil))
        vm.sourceURL = source; vm.destinationURL = destination
        vm.capacityAssessment = try assessment(available: 1)
        XCTAssertTrue(vm.hasInsufficientDestinationSpace)
        XCTAssertTrue(vm.startBlockedReason?.contains("Bundled") == true)
        vm.bundledRsyncInfo = .init(executableURL: root.appendingPathComponent("unused-rsync"), version: "3.4.4", diagnostics: [])
        XCTAssertFalse(vm.canStartTransfer)
        XCTAssertTrue(vm.startBlockedReason?.contains("4,096 bytes") == true)
        vm.capacityAssessment = try assessment()
        XCTAssertFalse(vm.hasInsufficientDestinationSpace)
        let observed = try DestinationActivitySnapshotter.snapshot(destinationRootURL: root,
            totalBytes: vm.capacityAssessment!.logicalPayloadBytes, totalFiles: 1,
            copyStartedAt: Date().addingTimeInterval(-10), previousSamples: []).snapshot
        XCTAssertEqual(observed.copiedBytes, 1)
        XCTAssertEqual(observed.totalBytes, 1)
        vm.applyTransferState(.copying)
        vm.applyCopyRuntimeSnapshot(observed)
        XCTAssertEqual(vm.progress, 99, "Existing active-copy cap remains; only Coordinator terminal completion reaches 100%.")
        XCTAssertEqual(vm.capacityAssessment?.admissionFloorBytes, 4096)
    }

    func testPrivacyManifestExactSchemaAndReasons() throws {
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: repo.appendingPathComponent("FishSockTransfer/PrivacyInfo.xcprivacy"))
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        XCTAssertEqual(Set(plist.keys), ["NSPrivacyAccessedAPITypes"])
        let types = try XCTUnwrap(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        XCTAssertEqual(types.count, 1)
        XCTAssertEqual(types[0]["NSPrivacyAccessedAPIType"] as? String, "NSPrivacyAccessedAPICategoryDiskSpace")
        XCTAssertEqual(types[0]["NSPrivacyAccessedAPITypeReasons"] as? [String], ["E174.1", "85F4.1"])
        XCTAssertEqual(Set(types[0].keys), ["NSPrivacyAccessedAPIType", "NSPrivacyAccessedAPITypeReasons"])
    }
}

/// Only destination access signals are injected; metadata enumeration/capacity remain real.
private final class TransitionDestinationFileManager: FileManager, @unchecked Sendable {
    enum Transition { case readOnly, disappears }
    private let destinationPath: String
    private let transition: Transition
    private let lock = NSLock()
    private var probes: [Bool] = []

    init(destination: URL, transition: Transition) {
        destinationPath = destination.path
        self.transition = transition
        super.init()
    }

    override func isWritableFile(atPath path: String) -> Bool {
        guard path == destinationPath else { return super.isWritableFile(atPath: path) }
        lock.lock()
        defer { lock.unlock() }
        let result = transition == .readOnly && probes.count >= 2 ? false : super.isWritableFile(atPath: path)
        probes.append(result)
        // The second probe belongs to the pre-scan metadata snapshot. Remove
        // only this empty UUID destination after its initial evidence was read.
        if transition == .disappears && probes.count == 2 {
            try? super.removeItem(atPath: path)
        }
        return result
    }

    func recordedProbes() -> [Bool] {
        lock.lock()
        defer { lock.unlock() }
        return probes
    }
}

final class DestinationWritabilityFreshnessXCTests: XCTestCase {
    private var root: URL!
    private var source: URL!
    private var destination: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("FSTWritabilityRepair-\(UUID())", isDirectory: true)
        source = root.appendingPathComponent("source", isDirectory: true)
        destination = root.appendingPathComponent("destination", isDirectory: true)
        for url in [source!, destination!] { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) }
        try Data([0x41]).write(to: source.appendingPathComponent("clip.bin"))
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: root)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
    }

    func testAuthoritativePreflightRejectsPostScanReadOnlyEvidence() async throws {
        let fm = TransitionDestinationFileManager(destination: destination, transition: .readOnly)
        let drive = DriveService(fileManager: fm)
        do {
            _ = try await drive.preflight(source: source, destination: destination)
            XCTFail("Post-scan read-only metadata must block authoritative admission")
        } catch {
            XCTAssertEqual(error as? TransferError, .destinationUnavailable)
        }
        XCTAssertEqual(fm.recordedProbes(), [true, true, false])
        XCTAssertEqual(try Data(contentsOf: source.appendingPathComponent("clip.bin")), Data([0x41]))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.appendingPathComponent("source").path))
    }

    func testProgrammaticCoordinatorRejectsPostScanReadOnlyBeforeRsync() async throws {
        let fm = TransitionDestinationFileManager(destination: destination, transition: .readOnly)
        let coordinator = TransferCoordinator(driveService: DriveService(fileManager: fm))
        let recorder = TransferCoordinatorRecorder()
        await coordinator.configureCallbacks(onStateChanged: { recorder.appendState($0) },
            onProgress: { _ in }, onSpeed: { _ in }, onTransferTime: { _ in }, onCurrentFile: { _ in },
            onError: { recorder.appendError($0) }, onLog: { recorder.appendLog($0) })
        let started = await coordinator.startTransfer(source: source, destination: destination, bandwidthLimit: nil, mode: .full)
        XCTAssertTrue(started)
        let deadline = Date().addingTimeInterval(5)
        while !(recorder.snapshotStates().contains(.error)) && Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        let finalState = await coordinator.state
        XCTAssertEqual(finalState, .error)
        XCTAssertEqual(recorder.snapshotStates(), [.validating, .error])
        XCTAssertEqual(recorder.snapshotErrors(), ["TRANSFER ERROR: The destination location is unavailable or cannot be written."])
        XCTAssertEqual(fm.recordedProbes(), [true, true, false])
        XCTAssertFalse(recorder.snapshotLogs().contains { $0.message == "Transfer Started" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.appendingPathComponent("source").path))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: source.path), ["clip.bin"])
        XCTAssertEqual(try Data(contentsOf: source.appendingPathComponent("clip.bin")), Data([0x41]))
    }

    func testDisappearedDestinationCannotUseInitialWritableSnapshot() async throws {
        let fm = TransitionDestinationFileManager(destination: destination, transition: .disappears)
        do {
            _ = try await DriveService(fileManager: fm).preflight(source: source, destination: destination)
            XCTFail("Missing destination must not be admitted using initial evidence")
        } catch {
            // Preserve the existing missing-capacity/profile failure semantics.
            XCTAssertTrue(error as? TransferPreflightError == .unableToDetermineDestinationFreeSpace
                || error as? TransferPreflightError == .destinationCapacityChanged)
        }
        XCTAssertEqual(fm.recordedProbes(), [true, true])
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testExistingDestinationUnavailableSemanticsForMissingAndFilePaths() async throws {
        for url in [root.appendingPathComponent("missing"), source.appendingPathComponent("clip.bin")] {
            do {
                try await DriveService().validateDestination(at: url)
                XCTFail("Missing/file destination must be unavailable")
            } catch {
                XCTAssertEqual(error as? TransferError, .destinationUnavailable)
                XCTAssertEqual(error.localizedDescription, "The destination location is unavailable or cannot be written.")
            }
        }
    }
}

/// All writes are restricted to UUID fixtures and disposable hdiutil-created images.
final class DestinationCapacityImageRuntimeXCTests: XCTestCase {
    private func command(_ executable: String, _ arguments: [String]) throws -> Data {
        let process = Process(), output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "FSTImageQA", code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: String(decoding: data.suffix(4096), as: UTF8.self)])
        }
        return data
    }

    func testDisposableAPFSAdmissionAndVerifiedCopy() async throws { try await runImageQA(filesystem: "APFS") }
    func testDisposableExfatLogicalWarningAndVerifiedCopy() async throws { try await runImageQA(filesystem: "ExFAT") }

    private func runImageQA(filesystem: String) async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("FSTCapacityImageQA-\(UUID())", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        var attached = false
        defer {
            if attached { XCTFail("Mounted image preserved after detach failure") }
            else {
            do { try fm.removeItem(at: root) }
            catch { XCTFail("Fixture cleanup failed: \(error)") }
            XCTAssertFalse(fm.fileExists(atPath: root.path))
            print("FST_CAPACITY_QA CLEANUP=PASS ROOT=\(root.path) OWNER_MEDIA_TOUCHED=NONE")
            }
        }
        let image = root.appendingPathComponent("destination.dmg")
        let mount = root.appendingPathComponent("mount", isDirectory: true)
        if filesystem == "APFS" {
            _ = try command("/usr/bin/hdiutil", ["create", "-size", "128m", "-fs", "APFS",
                "-volname", "FSTCapacityQA", "-type", "UDIF", "-nospotlight", image.path])
        } else {
            _ = try command("/usr/bin/hdiutil", ["create", "-size", "512m", "-layout", "NONE", "-type", "UDIF", image.path])
            let receipt = try command("/usr/bin/hdiutil", ["attach", "-nomount", "-plist", image.path])
            let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: receipt, format: nil) as? [String: Any])
            let entities = try XCTUnwrap(plist["system-entities"] as? [[String: Any]])
            let device = try XCTUnwrap(entities.first?["dev-entry"] as? String)
            // Prove this exact device came from our new image before filesystem creation.
            let allImages = try command("/usr/bin/hdiutil", ["info", "-plist"])
            let imageInfo = try XCTUnwrap(PropertyListSerialization.propertyList(from: allImages, format: nil) as? [String: Any])
            let images = try XCTUnwrap(imageInfo["images"] as? [[String: Any]])
            guard images.contains(where: { item in
                (item["image-path"] as? String) == image.path &&
                (item["system-entities"] as? [[String: Any]])?.contains(where: { ($0["dev-entry"] as? String) == device }) == true
            }) else { throw NSError(domain: "FSTImageQA", code: 2) }
            do {
                _ = try command("/sbin/newfs_exfat", ["-v", "FSTQA", device])
                _ = try command("/usr/bin/hdiutil", ["detach", device])
            } catch {
                _ = try? command("/usr/bin/hdiutil", ["detach", device])
                throw error
            }
        }
        _ = try command("/usr/bin/hdiutil", ["attach", "-nobrowse", "-mountpoint", mount.path, image.path])
        attached = true
        defer {
            if attached {
                do { _ = try command("/usr/bin/hdiutil", ["detach", mount.path]); attached = false }
                catch { XCTFail("Image detach failed: \(error)") }
            }
        }
        let source = root.appendingPathComponent("source", isDirectory: true)
        try fm.createDirectory(at: source, withIntermediateDirectories: true)
        let count = filesystem == "APFS" ? 8192 : 512
        for i in 0..<count { try Data([UInt8(i % 251)]).write(to: source.appendingPathComponent("clip-\(i).bin")) }
        try Data(repeating: 0xaa, count: 8192).write(to: source.appendingPathComponent(".DS_Store"))
        let drive = DriveService()
        let ample = try await drive.assessCapacity(source: source, destination: mount)
        XCTAssertEqual(ample.source.totalSizeBytes, Int64(count))
        XCTAssertEqual(ample.source.fileCount, count)
        XCTAssertEqual(ample.assessment.filesystemIdentity, filesystem == "APFS" ? "apfs" : "exfat")
        print("FST_CAPACITY_QA FS=\(ample.assessment.filesystemIdentity ?? "nil") UNIT=\(ample.assessment.allocationUnit ?? -1) L=\(ample.assessment.logicalPayloadBytes) FLOOR=\(ample.assessment.admissionFloorBytes) F=\(ample.assessment.availableSnapshotBytes) POLICY=\(ample.assessment.policyKind)")
        if filesystem == "APFS" {
            XCTAssertEqual(ample.assessment.policyKind, .validatedAPFSRounded)
            XCTAssertEqual(ample.assessment.admissionFloorBytes, 33_554_432)
            let filler = mount.appendingPathComponent("qa-filler")
            XCTAssertTrue(fm.createFile(atPath: filler.path, contents: nil))
            let handle = try FileHandle(forWritingTo: filler)
            let chunk = Data(repeating: 0x51, count: 1_048_576)
            // Bounded image-only fill; never write source media or a raw device.
            for _ in 0..<128 {
                let free = try await drive.calculateReliableFreeSpace(at: mount)
                if free < 25_165_824 { break }
                try handle.write(contentsOf: chunk)
            }
            try handle.close()
            let tight = try await drive.assessCapacity(source: source, destination: mount)
            XCTAssertGreaterThanOrEqual(tight.assessment.availableSnapshotBytes, tight.assessment.logicalPayloadBytes)
            XCTAssertLessThan(tight.assessment.availableSnapshotBytes, tight.assessment.admissionFloorBytes)
            do {
                _ = try await drive.preflight(source: source, destination: mount)
                XCTFail("Authoritative preflight must block F>=L but F<R")
            } catch TransferPreflightError.insufficientDestinationSpace(let floor, let available) {
                XCTAssertEqual(floor, 33_554_432)
                print("FST_CAPACITY_QA APFS_BLOCK_BEFORE_RSYNC=PASS FLOOR=\(floor) F=\(available)")
            }
            let recorder = TransferCoordinatorRecorder()
            let coordinator = TransferCoordinator(driveService: drive)
            await coordinator.configureCallbacks(onStateChanged: { recorder.appendState($0) },
                onProgress: { _ in }, onSpeed: { _ in }, onTransferTime: { _ in }, onCurrentFile: { _ in },
                onError: { recorder.appendError($0) }, onLog: { recorder.appendLog($0) })
            await coordinator.startTransfer(source: source, destination: mount, bandwidthLimit: nil, mode: .none)
            for _ in 0..<300 {
                if recorder.snapshotStates().contains(.error) { break }
                try await Task.sleep(for: .milliseconds(10))
            }
            XCTAssertTrue(recorder.snapshotStates().contains(.error))
            XCTAssertFalse(recorder.snapshotStates().contains(.copying))
            XCTAssertFalse(recorder.snapshotStates().contains(.safeToFormat))
            XCTAssertFalse(fm.fileExists(atPath: mount.appendingPathComponent("source").path))
            try fm.removeItem(at: filler)
        } else {
            XCTAssertEqual(ample.assessment.policyKind, .logicalOnlyUnvalidated)
            XCTAssertEqual(ample.assessment.admissionFloorBytes, Int64(count))
            XCTAssertEqual(ample.assessment.allocationUnit, 512)
            XCTAssertTrue(ample.assessment.supportingText.contains("does not guarantee"))
        }
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let service = BundledRsyncService(bundledExecutableURL: repo.appendingPathComponent("FishSockTransfer/rsync"))
        if filesystem == "ExFAT" {
            let filler = mount.appendingPathComponent("qa-filler")
            XCTAssertTrue(fm.createFile(atPath: filler.path, contents: nil))
            let handle = try FileHandle(forWritingTo: filler)
            for _ in 0..<512 {
                if try await drive.calculateReliableFreeSpace(at: mount) < 8_388_608 { break }
                try handle.write(contentsOf: Data(repeating: 0x51, count: 1_048_576))
            }
            try handle.close()
            let admitted = try await drive.preflight(source: source, destination: mount)
            XCTAssertEqual(admitted.plan.admissionFloorBytes, Int64(count))
            let recorder = TransferCoordinatorRecorder()
            let coordinator = TransferCoordinator(driveService: drive, bundledRsyncService: service)
            await coordinator.configureCallbacks(onStateChanged: { recorder.appendState($0) },
                onProgress: { _ in }, onSpeed: { _ in }, onTransferTime: { _ in }, onCurrentFile: { _ in },
                onError: { recorder.appendError($0) }, onLog: { recorder.appendLog($0) })
            await coordinator.startTransfer(source: source, destination: mount, bandwidthLimit: nil, mode: .none)
            for _ in 0..<6000 {
                if recorder.snapshotStates().contains(.error) { break }
                try await Task.sleep(for: .milliseconds(10))
            }
            XCTAssertTrue(recorder.snapshotStates().contains(.copying))
            XCTAssertTrue(recorder.snapshotStates().contains(.error))
            XCTAssertFalse(recorder.snapshotStates().contains(.safeToFormat))
            XCTAssertFalse(recorder.snapshotStates().contains(.copyComplete))
            XCTAssertTrue(recorder.snapshotErrors().contains(where: { $0.contains("TRANSFER ERROR:") }))
            print("FST_CAPACITY_QA EXFAT_F_GE_L=\(admitted.plan.destinationFreeSpaceBytes) RUNTIME_ENOSPC=TRANSFER_ERROR SAFE_TO_EJECT=NEVER SOURCE_RETAINED=YES")
            try fm.removeItem(at: mount.appendingPathComponent("source"))
            try fm.removeItem(at: filler)
        }
        let preflight = try await drive.preflight(source: source, destination: mount)
        XCTAssertEqual(preflight.plan.transferableBytes, Int64(count))
        XCTAssertTrue(preflight.plan.capacityAssessment.passesCapacityPrecheck)
        let info = await service.bundledInfo()
        XCTAssertTrue(info.isAvailable)
        let commandSpec = try RsyncCommand(bundledInfo: info,
            request: TransferRequest(sourceURL: source, destinationURL: mount, bandwidthLimit: nil))
        XCTAssertFalse(commandSpec.arguments.contains("--sparse"))
        _ = try command(try XCTUnwrap(info.executableURL).path, commandSpec.arguments)
        let copied = mount.appendingPathComponent("source")
        for i in 0..<count {
            let name = "clip-\(i).bin"
            let original = try Data(contentsOf: source.appendingPathComponent(name))
            XCTAssertEqual(SHA256.hash(data: original), SHA256.hash(data: try Data(contentsOf: copied.appendingPathComponent(name))))
        }
        XCTAssertFalse(fm.fileExists(atPath: copied.appendingPathComponent(".DS_Store").path))
        let observer = try DestinationActivitySnapshotter.snapshot(destinationRootURL: copied,
            totalBytes: preflight.plan.transferableBytes, totalFiles: count,
            copyStartedAt: Date().addingTimeInterval(-10), previousSamples: []).snapshot
        XCTAssertEqual(observer.totalBytes, Int64(count))
        XCTAssertEqual(observer.copiedBytes, Int64(count))
        print("FST_CAPACITY_QA FS=\(filesystem) F_GE_FLOOR_PASS=YES RSYNC=3.4.4 HASH_FILES=\(count) HASH=PASS OBSERVER_L=\(count) GUARANTEED_FIT_CLAIM=NONE")
        _ = try command("/usr/bin/hdiutil", ["detach", mount.path])
        attached = false
        let devices = try command("/usr/bin/hdiutil", ["info", "-plist"])
        XCTAssertFalse(String(decoding: devices, as: UTF8.self).contains(image.path))
    }
}
