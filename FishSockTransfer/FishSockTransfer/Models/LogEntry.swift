// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public enum LogCategory: String, Equatable, Sendable {
    case info
    case warning
    case error
    case success
    case transfer
    case stdout
    case stderr
    case file
    case progress
    case verify
    case system
}

nonisolated public struct LogEntry: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let category: LogCategory
    public let message: String
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), category: LogCategory, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.message = message
    }

    public var level: String {
        switch category {
        case .info, .transfer, .system:
            return "INFO"
        case .warning:
            return "WARN"
        case .error, .stderr:
            return "ERROR"
        case .success:
            return "SUCCESS"
        case .stdout:
            return "OUT"
        case .file:
            return "FILE"
        case .progress:
            return "PROGRESS"
        case .verify:
            return "VERIFY"
        }
    }
}
