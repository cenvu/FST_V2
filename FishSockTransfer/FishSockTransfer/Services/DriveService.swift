import Foundation

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
        let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
        if let importantCapacity = values.volumeAvailableCapacityForImportantUsage {
            return importantCapacity
        }

        return Int64(values.volumeAvailableCapacity ?? 0)
    }

    public func calculateReliableFreeSpace(at url: URL) throws -> Int64 {
        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
        } catch {
            throw TransferPreflightError.unableToDetermineDestinationFreeSpace
        }

        if let importantCapacity = values.volumeAvailableCapacityForImportantUsage, importantCapacity >= 0 {
            return importantCapacity
        }

        if let availableCapacity = values.volumeAvailableCapacity, availableCapacity >= 0 {
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

    public func destinationMetadata(for url: URL) throws -> DestinationStorageMetadata {
        DestinationStorageMetadata(
            freeSpaceBytes: try calculateFreeSpace(at: url),
            filesystem: try getFilesystemType(at: url),
            isWritable: isWritable(at: url)
        )
    }

    private func scanFolder(at url: URL) throws -> (totalSizeBytes: Int64, fileCount: Int, folderCount: Int) {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .fileSizeKey, .totalFileAllocatedSizeKey]
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [],
            errorHandler: nil
        ) else {
            throw TransferError.sourceUnavailable
        }

        var totalSizeBytes: Int64 = 0
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
                folderCount += 1
                continue
            }

            guard values.isRegularFile == true else { continue }

            fileCount += 1
            if let allocatedSize = values.totalFileAllocatedSize {
                totalSizeBytes += Int64(allocatedSize)
            } else {
                totalSizeBytes += Int64(values.fileSize ?? 0)
            }
        }

        return (totalSizeBytes, fileCount, folderCount)
    }
}

nonisolated public struct TransferPreflightPlan: Equatable, Sendable {
    public let sourceURL: URL
    public let destinationURL: URL
    public let destinationJobFolderURL: URL
    public let transferableBytes: Int64
    public let transferableFileCount: Int
    public let destinationFreeSpaceBytes: Int64
}

nonisolated public enum TransferPreflightError: Error, Equatable, LocalizedError, Sendable {
    case sameSourceAndDestination
    case destinationInsideSource
    case sourceInsideDestination
    case destinationJobFolderAlreadyExists(String)
    case noTransferableFiles
    case unableToDetermineDestinationFreeSpace
    case insufficientDestinationSpace(required: Int64, available: Int64)

    public var errorDescription: String? {
        switch self {
        case .sameSourceAndDestination:
            return "Source and destination cannot be the same folder."
        case .destinationInsideSource:
            return "Destination cannot be inside the source folder."
        case .sourceInsideDestination:
            return "Source cannot be inside the destination folder."
        case .destinationJobFolderAlreadyExists(let path):
            return "Destination job folder already exists: \(path)"
        case .noTransferableFiles:
            return "No transferable files found after exclusions."
        case .unableToDetermineDestinationFreeSpace:
            return "Unable to determine destination free space."
        case .insufficientDestinationSpace(let required, let available):
            return "Insufficient destination space. Required: \(Self.formatBytes(required)), Available: \(Self.formatBytes(available))."
        }
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        "\(bytes) bytes"
    }
}

nonisolated public enum TransferPreflightValidator {
    public static func validate(
        source: URL,
        destination: URL,
        sourceMetadata: SourceStorageMetadata,
        destinationFreeSpaceBytes: Int64?,
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
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: jobFolderURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            throw TransferPreflightError.destinationJobFolderAlreadyExists(jobFolderURL.path)
        }

        guard sourceMetadata.fileCount > 0, sourceMetadata.totalSizeBytes > 0 else {
            throw TransferPreflightError.noTransferableFiles
        }

        guard let availableBytes = destinationFreeSpaceBytes, availableBytes >= 0 else {
            throw TransferPreflightError.unableToDetermineDestinationFreeSpace
        }

        guard availableBytes >= sourceMetadata.totalSizeBytes else {
            throw TransferPreflightError.insufficientDestinationSpace(
                required: sourceMetadata.totalSizeBytes,
                available: availableBytes
            )
        }

        return TransferPreflightPlan(
            sourceURL: sourceURL,
            destinationURL: destinationURL,
            destinationJobFolderURL: jobFolderURL,
            transferableBytes: sourceMetadata.totalSizeBytes,
            transferableFileCount: sourceMetadata.fileCount,
            destinationFreeSpaceBytes: availableBytes
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
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: jobFolderURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            let canonicalJobFolderURL = canonicalDirectoryURL(jobFolderURL)
            if sameDirectory(canonicalJobFolderURL, sourceURL) || directory(canonicalJobFolderURL, isInside: sourceURL) {
                return destinationURL
            }
            return canonicalJobFolderURL
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
