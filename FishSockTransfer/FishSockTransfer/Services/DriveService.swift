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
