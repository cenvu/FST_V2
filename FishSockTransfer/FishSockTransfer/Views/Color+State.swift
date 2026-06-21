import SwiftUI

nonisolated public enum TransferStatusVisualRole: Equatable, Sendable {
    case idle
    case copying
    case verifying
    case copyOnlyComplete
    case safeToFormat
    case error
    case cancelled
}

public extension TransferState {
    var statusVisualRole: TransferStatusVisualRole {
        switch self {
        case .ready, .validating:
            return .idle
        case .copying:
            return .copying
        case .verifying:
            return .verifying
        case .copyComplete:
            return .copyOnlyComplete
        case .safeToFormat:
            return .safeToFormat
        case .error:
            return .error
        case .cancelled:
            return .cancelled
        }
    }

    var statusColor: Color {
        switch statusVisualRole {
        case .idle:
            return .gray
        case .copying:
            return .blue
        case .verifying:
            return .orange
        case .copyOnlyComplete:
            return .blue
        case .safeToFormat:
            return .green
        case .error:
            return .red
        case .cancelled:
            return .yellow
        }
    }
}
