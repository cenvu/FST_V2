import Foundation

public enum TransferState: String, Equatable {
    case ready
    case validating
    case copying
    case verifying
    case copyComplete
    case safeToFormat
    case error
    case cancelled
}
