import Foundation

public enum TransferError: Error, Equatable, LocalizedError {
    case processLaunchFailed
    case sourceUnavailable
    case sourceEmpty
    case destinationUnavailable
    case insufficientSpace
    case rsyncExit(Int32)
    case interrupted
    case timeout
    case unknown

    public var errorDescription: String? {
        switch self {
        case .sourceEmpty:
            return "The selected source folder is empty."
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
        case .interrupted:
            return "The transfer was interrupted."
        case .timeout:
            return "The transfer timed out."
        case .unknown:
            return "An unknown error occurred during transfer."
        }
    }
}

public enum TransferEvent: Equatable {
    case started
    case progress(Double)
    case speed(Double)
    case eta(TimeInterval)
    case currentFile(String)
    case log(String)
    case completed
    case cancelled
    case failed(TransferError)
}
