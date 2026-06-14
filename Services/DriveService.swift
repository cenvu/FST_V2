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
        
        let contents = try? fileManager.contentsOfDirectory(atPath: url.path)
        guard let contents = contents, !contents.isEmpty else {
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
        let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        return Int64(values.volumeAvailableCapacity ?? 0)
    }
}
