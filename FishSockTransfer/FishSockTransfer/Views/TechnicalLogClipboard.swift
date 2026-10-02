// FST / CenVu | (+84) 842 841 222

import AppKit
import Foundation

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
