import Foundation

public enum LogCategory: String, Equatable {
    case info
    case warning
    case error
    case transfer
    case verify
    case system
}

public struct LogEntry: Equatable, Identifiable {
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
}
