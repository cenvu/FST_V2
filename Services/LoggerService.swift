import Foundation

public actor LoggerService {
    private var logs: [LogEntry] = []
    
    public init() {}
    
    public func log(category: LogCategory, message: String) {
        let entry = LogEntry(category: category, message: message)
        logs.append(entry)
        print("[\(category.rawValue.uppercased())] \(message)")
    }
    
    public func exportLogs() -> String {
        return logs.map { "[\($0.timestamp.description)] [\($0.category.rawValue.uppercased())] \($0.message)" }
            .joined(separator: "\n")
    }
}
