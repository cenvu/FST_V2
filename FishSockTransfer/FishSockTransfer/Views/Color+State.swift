import SwiftUI

public extension TransferState {
    var statusColor: Color {
        switch self {
        case .ready, .validating: 
            return .gray
        case .copying: 
            return .blue
        case .verifying: 
            return .orange
        case .safeToFormat, .copyComplete: 
            return .green
        case .error: 
            return .red
        case .cancelled: 
            return .yellow
        }
    }
}
