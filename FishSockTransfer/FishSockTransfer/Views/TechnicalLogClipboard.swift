// FST / CenVu | (+84) 842 841 222

import AppKit
import Foundation

enum TechnicalLogCopyFeedback: Equatable {
    case success
    case failure
}

struct TechnicalLogCopyFeedbackState: Equatable {
    private(set) var feedback: TechnicalLogCopyFeedback?
    private(set) var generation = 0

    @discardableResult
    mutating func record(copySucceeded: Bool) -> TechnicalLogCopyFeedback {
        let result: TechnicalLogCopyFeedback = copySucceeded ? .success : .failure
        feedback = result
        generation &+= 1
        return result
    }

    @MainActor
    @discardableResult
    mutating func copyAll(logs: [LogEntry], to pasteboard: NSPasteboard = .general) -> TechnicalLogCopyFeedback {
        record(copySucceeded: TechnicalLogClipboard.copyAll(logs: logs, to: pasteboard))
    }

    mutating func dismiss(ifGeneration expectedGeneration: Int) {
        guard generation == expectedGeneration else { return }
        feedback = nil
    }
}

@MainActor
public enum TechnicalLogClipboard {
    /// Formats the same timestamp, level, and unmodified message values used by the
    /// selectable Technical Log feed. Diagnostic entries are intentionally retained.
    public static func formattedHistory(_ logs: [LogEntry]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        return logs.map { log in
            "[\(formatter.string(from: log.timestamp))] \(log.level) \(log.message)"
        }
        .joined(separator: "\n")
    }

    /// Writes the complete retained log array, independent of the visible-log filter.
    @discardableResult
    public static func copyAll(logs: [LogEntry], to pasteboard: NSPasteboard = .general) -> Bool {
        guard !logs.isEmpty else { return false }

        pasteboard.clearContents()
        return pasteboard.setString(formattedHistory(logs), forType: .string)
    }
}
