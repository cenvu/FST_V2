import Foundation

nonisolated public enum TransferState: String, Equatable, Sendable {
    case ready
    case validating
    case copying
    case verifying
    case copyComplete
    case safeToFormat
    case error
    case cancelled
}
