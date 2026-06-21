import Foundation

nonisolated public struct SourceStorageMetadata: Equatable, Sendable {
    public let folderName: String
    public let fullPath: String
    public let totalSizeBytes: Int64
    public let fileCount: Int
    public let folderCount: Int

    public init(folderName: String, fullPath: String, totalSizeBytes: Int64, fileCount: Int, folderCount: Int) {
        self.folderName = folderName
        self.fullPath = fullPath
        self.totalSizeBytes = totalSizeBytes
        self.fileCount = fileCount
        self.folderCount = folderCount
    }
}

nonisolated public struct DestinationStorageMetadata: Equatable, Sendable {
    public let freeSpaceBytes: Int64
    public let filesystem: String
    public let isWritable: Bool

    public init(freeSpaceBytes: Int64, filesystem: String, isWritable: Bool) {
        self.freeSpaceBytes = freeSpaceBytes
        self.filesystem = filesystem
        self.isWritable = isWritable
    }
}
