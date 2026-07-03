import Foundation

nonisolated public enum VerificationError: Error, Equatable, LocalizedError, Sendable {
    case sourceMissing
    case destinationMissing
    case fileCountMismatch
    case fileSizeMismatch
    case hashMismatch
    case noTransferableFiles
    case inventoryReadFailed(label: String, path: String, reason: String)
    case fileReadFailed(label: String, relativePath: String, reason: String)
    case cancelled
    case unknown

    public var errorDescription: String? {
        switch self {
        case .sourceMissing:
            return "Source folder is missing or cannot be read."
        case .destinationMissing:
            return "Destination folder is missing or incomplete."
        case .fileCountMismatch:
            return "Verification failed. Source and destination file counts do not match."
        case .fileSizeMismatch:
            return "Verification failed. Source and destination file sizes do not match."
        case .hashMismatch:
            return "Verification failed. Source and destination file hashes do not match."
        case .noTransferableFiles:
            return "No transferable files found after exclusions."
        case .inventoryReadFailed(let label, let path, let reason):
            return "Verification failed because FST could not scan the \(label.lowercased()) inventory at \(path). \(reason)"
        case .fileReadFailed(let label, let relativePath, let reason):
            return "Verification failed because FST could not read the \(label.lowercased()) file: \(relativePath). \(reason)"
        case .cancelled:
            return "Verification was cancelled."
        case .unknown:
            return "Verification failed for an unknown reason."
        }
    }
}

nonisolated public enum VerificationEvent: Equatable, Sendable {
    case started
    case preparing(String)
    case progress(Double)
    case currentFile(String)
    case log(String)
    case hashGenerated(String)
    case completed(VerificationResult)
    case cancelled
    case failed(VerificationError)
}
