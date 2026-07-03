import Foundation

nonisolated public enum TransferError: Error, Equatable, LocalizedError, Sendable {
    case processLaunchFailed
    case sourceUnavailable
    case sourceEmpty
    case destinationUnavailable
    case insufficientSpace
    case rsyncExit(Int32)
    case rsyncNotFound
    case invalidBandwidthLimit
    case interrupted
    case timeout
    case unknown

    public var errorDescription: String? {
        switch self {
        case .sourceEmpty:
            return "No transferable files found after exclusions. Metadata-only files are ignored."
        case .processLaunchFailed:
            return "Failed to launch the underlying transfer process."
        case .sourceUnavailable:
            return "The source location is unavailable or cannot be read."
        case .destinationUnavailable:
            return "The destination location is unavailable or cannot be written."
        case .insufficientSpace:
            return "Not enough free space on the destination drive."
        case .rsyncExit(let code):
            return "Transfer process exited with error code \(code)."
        case .rsyncNotFound:
            return "Bundled rsync is missing, not executable, or not version 3.4.4."
        case .invalidBandwidthLimit:
            return "Invalid bandwidth limit. Choose Unlimited or 20-300 MB/s."
        case .interrupted:
            return "The transfer was interrupted."
        case .timeout:
            return "The transfer timed out."
        case .unknown:
            return "An unknown error occurred during transfer."
        }
    }
}

nonisolated public enum TransferEvent: Equatable, Sendable {
    case started
    case progress(Double)
    case speed(Double)
    case eta(TimeInterval)
    case transferredBytes(Int64?)
    case currentFile(String)
    case log(String)
    case completed
    case cancelled
    case failed(TransferError)
}
