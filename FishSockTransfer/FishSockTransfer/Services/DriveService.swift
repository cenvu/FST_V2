// FST / CenVu | (+84) 842 841 222

import Foundation
import Darwin

public actor DriveService {
    private let fileManager = FileManager.default
    
    public init() {}
    
    public func validateSource(at url: URL) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw TransferError.sourceUnavailable
        }
        guard isDirectory.boolValue else {
            throw TransferError.sourceUnavailable
        }
        guard fileManager.isReadableFile(atPath: url.path) else {
            throw TransferError.sourceUnavailable
        }
        
        let scan = try scanFolder(at: url)
        guard scan.fileCount > 0 else {
            throw TransferError.sourceEmpty
        }
    }
    
    public func validateDestination(at url: URL) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw TransferError.destinationUnavailable
        }
        guard isDirectory.boolValue else {
            throw TransferError.destinationUnavailable
        }
        guard fileManager.isWritableFile(atPath: url.path) else {
            throw TransferError.destinationUnavailable
        }
    }
    
    public func calculateFreeSpace(at url: URL) throws -> Int64 {
        try calculateReliableFreeSpace(at: url)
    }

    public func calculateReliableFreeSpace(at url: URL) throws -> Int64 {
        let values: URLResourceValues
        do {
            let snapshotURL = URL(fileURLWithPath: url.path, isDirectory: true)
            values = try snapshotURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
        } catch {
            throw TransferPreflightError.unableToDetermineDestinationFreeSpace
        }

        return try Self.selectAvailableCapacity(
            importantUsage: values.volumeAvailableCapacityForImportantUsage,
            ordinary: values.volumeAvailableCapacity
        )
    }

    nonisolated static func selectAvailableCapacity(
        importantUsage: Int64?,
        ordinary: Int?
    ) throws -> Int64 {
        if let importantCapacity = importantUsage, importantCapacity > 0 {
            return importantCapacity
        }

        if let availableCapacity = ordinary, availableCapacity >= 0 {
            return Int64(availableCapacity)
        }

        throw TransferPreflightError.unableToDetermineDestinationFreeSpace
    }

    public func calculateFolderSize(at url: URL) throws -> Int64 {
        try scanFolder(at: url).totalSizeBytes
    }

    public func countFiles(at url: URL) throws -> Int {
        try scanFolder(at: url).fileCount
    }

    public func countFolders(at url: URL) throws -> Int {
        try scanFolder(at: url).folderCount
    }

    public func getFilesystemType(at url: URL) throws -> String {
        let values = try url.resourceValues(forKeys: [.volumeLocalizedFormatDescriptionKey])
        return values.volumeLocalizedFormatDescription ?? "Unknown"
    }

    public func isWritable(at url: URL) -> Bool {
        fileManager.isWritableFile(atPath: url.path)
    }

    public func sourceMetadata(for url: URL) throws -> SourceStorageMetadata {
        let scan = try scanFolder(at: url)
        return SourceStorageMetadata(
            folderName: url.lastPathComponent,
            fullPath: url.path,
            totalSizeBytes: scan.totalSizeBytes,
            fileCount: scan.fileCount,
            folderCount: scan.folderCount
        )
    }

    /// Machine identity and allocation evidence are obtained from the same public statfs result.
    /// f_bsize is the fundamental block size (Darwin statvfs.f_frsize), not preferred I/O size.
    nonisolated static func filesystemProfile(at url: URL) -> (identity: String, unit: Int64, volume: String)? {
        var info = statfs()
        guard url.withUnsafeFileSystemRepresentation({ path in
            guard let path else { return false }
            return statfs(path, &info) == 0
        }) else { return nil }
        let identity = withUnsafeBytes(of: info.f_fstypename) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
        guard !identity.isEmpty else { return nil }
        return (identity, Int64(info.f_bsize), "\(info.f_fsid.val.0):\(info.f_fsid.val.1)")
    }

    public func destinationMetadata(for url: URL) throws -> DestinationStorageMetadata {
        // Fresh URL avoids reusing cached Foundation resource values from a UI preview.
        let freshURL = URL(fileURLWithPath: url.path, isDirectory: true)
        let before = Self.filesystemProfile(at: freshURL)
        let available = try calculateFreeSpace(at: freshURL)
        let after = Self.filesystemProfile(at: freshURL)
        guard before?.volume == after?.volume, before?.identity == after?.identity,
              before?.unit == after?.unit else { throw TransferPreflightError.destinationCapacityChanged }
        return DestinationStorageMetadata(
            freeSpaceBytes: available,
            filesystem: (try? getFilesystemType(at: freshURL)) ?? "Unknown",
            isWritable: isWritable(at: freshURL),
            filesystemIdentity: after?.identity, allocationUnit: after?.unit, volumeIdentity: after?.volume
        )
    }

    /// Source metadata stays intrinsic to the source; rounded bytes exist only in this assessment.
    public func assessCapacity(source: URL, destination: URL) throws
        -> (source: SourceStorageMetadata, destination: DestinationStorageMetadata, assessment: DestinationCapacityAssessment) {
        try Task.checkCancellation()
        let before = try destinationMetadata(for: destination)
        let unit = DestinationCapacityAssessment.validatedAllocationUnit(
            filesystemIdentity: before.filesystemIdentity, allocationUnit: before.allocationUnit)
        let scan = try scanFolder(at: source, allocationUnit: unit)
        try Task.checkCancellation()
        // Refresh immediately before admission and reject a mount/profile change during enumeration.
        let snapshot = try destinationMetadata(for: destination)
        guard before.volumeIdentity == snapshot.volumeIdentity,
              before.filesystemIdentity == snapshot.filesystemIdentity,
              before.allocationUnit == snapshot.allocationUnit else {
            throw TransferPreflightError.destinationCapacityChanged
        }
        let metadata = SourceStorageMetadata(folderName: source.lastPathComponent, fullPath: source.path,
            totalSizeBytes: scan.totalSizeBytes, fileCount: scan.fileCount, folderCount: scan.folderCount)
        let assessment = try DestinationCapacityAssessment.make(source: source, destination: destination,
            logicalPayloadBytes: scan.totalSizeBytes, roundedPayloadBytes: scan.roundedBytes, snapshot: snapshot)
        return (metadata, snapshot, assessment)
    }

    public func preparePreflight(source: URL, destination: URL) throws
        -> (source: SourceStorageMetadata, destination: DestinationStorageMetadata, assessment: DestinationCapacityAssessment) {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory),
              isDirectory.boolValue, fileManager.isReadableFile(atPath: source.path) else {
            throw TransferError.sourceUnavailable
        }
        try validateDestination(at: destination)
        return try assessCapacity(source: source, destination: destination)
    }

    public func preflight(source: URL, destination: URL) throws -> (plan: TransferPreflightPlan, source: SourceStorageMetadata) {
        let evidence = try preparePreflight(source: source, destination: destination)
        let plan = try TransferPreflightValidator.validate(source: source, destination: destination,
            sourceMetadata: evidence.source, destinationFreeSpaceBytes: evidence.assessment.availableSnapshotBytes,
            capacityAssessment: evidence.assessment)
        return (plan, evidence.source)
    }

    private func scanFolder(at url: URL, allocationUnit: Int64? = nil) throws -> (totalSizeBytes: Int64, fileCount: Int, folderCount: Int, roundedBytes: Int64?) {
        try Task.checkCancellation()
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .fileSizeKey]
        var enumerationError: Error?
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [],
            errorHandler: { _, error in enumerationError = error; return false }
        ) else {
            throw TransferError.sourceUnavailable
        }

        var totalSizeBytes: Int64 = 0
        var roundedBytes: Int64 = 0
        var fileCount = 0
        var folderCount = 0

        for case let itemURL as URL in enumerator {
            try Task.checkCancellation()

            let values = try itemURL.resourceValues(forKeys: Set(keys))
            if TransferFileExclusionPolicy.shouldExclude(itemURL, rootURL: url) {
                if values.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            if values.isDirectory == true {
                let (count, overflow) = folderCount.addingReportingOverflow(1)
                guard !overflow else { throw TransferPreflightError.capacityArithmeticOverflow }
                folderCount = count
                continue
            }

            guard values.isRegularFile == true else { continue }

            guard let logicalSize = values.fileSize, logicalSize >= 0 else {
                throw TransferError.sourceUnavailable
            }
            let (count, overflow) = fileCount.addingReportingOverflow(1)
            guard !overflow else { throw TransferPreflightError.capacityArithmeticOverflow }
            fileCount = count
            // Rsync without --sparse writes logical contents, regardless of source allocation.
            totalSizeBytes = try CapacityArithmetic.add(totalSizeBytes, Int64(logicalSize))
            if let allocationUnit {
                roundedBytes = try CapacityArithmetic.add(roundedBytes, CapacityArithmetic.roundUp(Int64(logicalSize), unit: allocationUnit))
            }
        }

        if let enumerationError { throw enumerationError }
        try Task.checkCancellation()
        return (totalSizeBytes, fileCount, folderCount, allocationUnit == nil ? nil : roundedBytes)
    }
}

nonisolated public struct TransferPreflightPlan: Equatable, Sendable {
    public let sourceURL: URL
    public let destinationURL: URL
    public let destinationJobFolderURL: URL
    public let transferableBytes: Int64
    public let transferableFileCount: Int
    public let destinationFreeSpaceBytes: Int64
    public let capacityAssessment: DestinationCapacityAssessment
    public var admissionFloorBytes: Int64 { capacityAssessment.admissionFloorBytes }
}

nonisolated public enum TransferPreflightError: Error, Equatable, LocalizedError, Sendable {
    case capacityArithmeticOverflow
    case invalidCapacityEvidence
    case destinationCapacityChanged
    case sameSourceAndDestination
    case destinationInsideSource
    case sourceInsideDestination
    case destinationJobPathAlreadyExists(String)
    case noTransferableFiles
    case unableToDetermineDestinationFreeSpace
    case insufficientDestinationSpace(required: Int64, available: Int64)

    public var errorDescription: String? {
        switch self {
        case .capacityArithmeticOverflow:
            return "Capacity preflight arithmetic overflow. Do not erase or reuse the source."
        case .invalidCapacityEvidence:
            return "Invalid capacity preflight evidence. Do not erase or reuse the source."
        case .destinationCapacityChanged:
            return "Destination capacity profile changed during preflight. Select the destination again; do not erase or reuse the source."
        case .sameSourceAndDestination:
            return "Source and destination cannot be the same folder. Choose a separate destination."
        case .destinationInsideSource:
            return "Destination cannot be inside the source folder. Choose a destination outside the source/media tree."
        case .sourceInsideDestination:
            return "Source cannot be inside the destination folder. Choose a separate destination outside the source/media tree."
        case .destinationJobPathAlreadyExists(let path):
            return "Destination job path already exists: \(path). Choose a new destination or create a new unique folder. FST will not merge or overwrite existing job data."
        case .noTransferableFiles:
            return "No transferable files found after exclusions."
        case .unableToDetermineDestinationFreeSpace:
            return "Unable to determine destination free space. FST cannot safely start without confirming available space."
        case .insufficientDestinationSpace(let required, let available):
            return "Destination capacity is below the required preflight floor. Floor: \(Self.formatBytes(required)), Available: \(Self.formatBytes(available))."
        }
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        let readableSize = formatReadableBytes(bytes)
        let exactBytes = formatExactBytes(bytes)
        return "\(readableSize) (\(exactBytes) bytes)"
    }

    private static func formatExactBytes(_ bytes: Int64) -> String {
        let stringValue = String(bytes)
        let sign = stringValue.hasPrefix("-") ? "-" : ""
        let digits = sign.isEmpty ? stringValue : String(stringValue.dropFirst())
        var grouped = ""

        for (index, character) in digits.reversed().enumerated() {
            if index > 0, index % 3 == 0 {
                grouped.insert(",", at: grouped.startIndex)
            }
            grouped.insert(character, at: grouped.startIndex)
        }

        return sign + grouped
    }

    private static func formatReadableBytes(_ bytes: Int64) -> String {
        let units = ["bytes", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(bytes) bytes"
        }

        if value.rounded(.towardZero) == value {
            return "\(Int(value)) \(units[unitIndex])"
        }

        return String(format: "%.1f %@", locale: Locale(identifier: "en_US_POSIX"), value, units[unitIndex])
    }
}

nonisolated public enum TransferPreflightValidator {
    public static func validate(
        source: URL,
        destination: URL,
        sourceMetadata: SourceStorageMetadata,
        destinationFreeSpaceBytes: Int64?,
        capacityAssessment: DestinationCapacityAssessment? = nil,
        fileManager: FileManager = .default
    ) throws -> TransferPreflightPlan {
        let sourceURL = canonicalDirectoryURL(source)
        let destinationURL = canonicalDirectoryURL(destination)

        if sameDirectory(sourceURL, destinationURL) {
            throw TransferPreflightError.sameSourceAndDestination
        }

        if directory(destinationURL, isInside: sourceURL) {
            throw TransferPreflightError.destinationInsideSource
        }

        if directory(sourceURL, isInside: destinationURL) {
            throw TransferPreflightError.sourceInsideDestination
        }

        let jobFolderURL = destinationURL.appendingPathComponent(source.lastPathComponent, isDirectory: true)
        if fileManager.fileExists(atPath: jobFolderURL.path) {
            throw TransferPreflightError.destinationJobPathAlreadyExists(jobFolderURL.path)
        }

        guard sourceMetadata.fileCount > 0, sourceMetadata.totalSizeBytes > 0 else {
            throw TransferPreflightError.noTransferableFiles
        }

        guard let availableBytes = destinationFreeSpaceBytes, availableBytes >= 0 else {
            throw TransferPreflightError.unableToDetermineDestinationFreeSpace
        }

        let assessment = try capacityAssessment ?? DestinationCapacityAssessment.make(
            source: source, destination: destination, logicalPayloadBytes: sourceMetadata.totalSizeBytes,
            roundedPayloadBytes: nil,
            snapshot: DestinationStorageMetadata(freeSpaceBytes: availableBytes, filesystem: "Unknown", isWritable: true))
        guard assessment.matches(source: source, destination: destination),
              assessment.logicalPayloadBytes == sourceMetadata.totalSizeBytes,
              assessment.availableSnapshotBytes == availableBytes else {
            throw TransferPreflightError.invalidCapacityEvidence
        }
        guard assessment.passesCapacityPrecheck else {
            throw TransferPreflightError.insufficientDestinationSpace(
                required: assessment.admissionFloorBytes,
                available: availableBytes
            )
        }

        return TransferPreflightPlan(
            sourceURL: sourceURL,
            destinationURL: destinationURL,
            destinationJobFolderURL: jobFolderURL,
            transferableBytes: sourceMetadata.totalSizeBytes,
            transferableFileCount: sourceMetadata.fileCount,
            destinationFreeSpaceBytes: availableBytes,
            capacityAssessment: assessment
        )
    }

    public static func safeReportFolder(source: URL, destination: URL, fileManager: FileManager = .default) -> URL? {
        let sourceURL = canonicalDirectoryURL(source)
        let destinationURL = canonicalDirectoryURL(destination)

        if sameDirectory(sourceURL, destinationURL)
            || directory(destinationURL, isInside: sourceURL)
            || directory(sourceURL, isInside: destinationURL) {
            return nil
        }

        let jobFolderURL = destinationURL.appendingPathComponent(source.lastPathComponent, isDirectory: true)
        if fileManager.fileExists(atPath: jobFolderURL.path) {
            return destinationURL
        }

        return destinationURL
    }

    public static func sameDirectory(_ lhs: URL, _ rhs: URL) -> Bool {
        canonicalDirectoryURL(lhs).pathComponents == canonicalDirectoryURL(rhs).pathComponents
    }

    public static func directory(_ child: URL, isInside parent: URL) -> Bool {
        let childComponents = canonicalDirectoryURL(child).pathComponents
        let parentComponents = canonicalDirectoryURL(parent).pathComponents
        guard childComponents.count > parentComponents.count else { return false }
        return Array(childComponents.prefix(parentComponents.count)) == parentComponents
    }

    public static func canonicalDirectoryURL(_ url: URL) -> URL {
        let standardized = URL(fileURLWithPath: url.path, isDirectory: true)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        return standardized.standardizedFileURL
    }
}
