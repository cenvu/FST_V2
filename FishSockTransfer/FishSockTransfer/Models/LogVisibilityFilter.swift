import Foundation

/// Classifies log entries as diagnostic (verbose internal) vs. operator-facing.
///
/// - Diagnostic entries are hidden from the in-app Technical Logs UI by default.
/// - Full logs (including diagnostic) are always written to the TXT report for evidence.
/// - The underlying log array is never mutated; filtering is view-only.
nonisolated public enum LogVisibilityFilter {

    /// Prefixes and substrings that indicate a diagnostic-only log entry.
    private static let diagnosticPrefixes: [String] = [
        "DIAG [",
        "[VERIFY DIAG]",
        "Hash source path:",
        "Hash destination path:",
        "Hash generated: Source",
        "Hash generated: Destination",
    ]

    /// Returns `true` if the log entry is a verbose diagnostic that should be
    /// hidden from the operator view by default.
    ///
    /// Does NOT classify errors, warnings, or any operator-facing evidence
    /// lines as diagnostic.
    public static func isDiagnostic(_ entry: LogEntry) -> Bool {
        isDiagnostic(entry.message)
    }

    /// Returns `true` if the raw message string is a verbose diagnostic.
    public static func isDiagnostic(_ message: String) -> Bool {
        for prefix in diagnosticPrefixes {
            if message.contains(prefix) {
                return true
            }
        }
        return false
    }

    /// Returns only operator-facing entries (hides diagnostics).
    public static func operatorVisible(from logs: [LogEntry]) -> [LogEntry] {
        logs.filter { !isDiagnostic($0) }
    }
}
