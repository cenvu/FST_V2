// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public enum TelegramHeartbeatInterval: Int, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case fifteenMinutes = 15
    case thirtyMinutes = 30

    public var id: Int { rawValue }

    public var seconds: TimeInterval {
        TimeInterval(rawValue * 60)
    }

    public var displayLabel: String {
        "\(rawValue) minutes"
    }

    public static func from(minutes: Int) -> TelegramHeartbeatInterval {
        Self(rawValue: minutes) ?? .fifteenMinutes
    }
}

nonisolated public struct NotificationSettings: Codable, Equatable, Sendable {
    public var isTelegramEnabled: Bool
    public var chatID: String
    public var notifyJobStarts: Bool
    public var notifyHeartbeat: Bool
    public var notifyTransferFails: Bool
    public var notifyCopyCompleted: Bool
    public var notifyVerifyCompleted: Bool
    public var heartbeatInterval: TelegramHeartbeatInterval

    public init(
        isTelegramEnabled: Bool = false,
        chatID: String = "",
        notifyJobStarts: Bool = true,
        notifyHeartbeat: Bool = true,
        notifyTransferFails: Bool = true,
        notifyCopyCompleted: Bool = true,
        notifyVerifyCompleted: Bool = true,
        heartbeatInterval: TelegramHeartbeatInterval = .fifteenMinutes
    ) {
        self.isTelegramEnabled = isTelegramEnabled
        self.chatID = chatID
        self.notifyJobStarts = notifyJobStarts
        self.notifyHeartbeat = notifyHeartbeat
        self.notifyTransferFails = notifyTransferFails
        self.notifyCopyCompleted = notifyCopyCompleted
        self.notifyVerifyCompleted = notifyVerifyCompleted
        self.heartbeatInterval = heartbeatInterval
    }

    public static let `default` = NotificationSettings()
}

nonisolated public enum NotificationConnectionState: Equatable, Sendable {
    case notTested
    case ready
    case error

    public var displayText: String {
        switch self {
        case .notTested:
            return "Not Tested"
        case .ready:
            return "Ready"
        case .error:
            return "Error"
        }
    }
}

nonisolated public struct NotificationRuntimeStatus: Equatable, Sendable {
    public var telegramStatus: String
    public var connectionStatus: NotificationConnectionState
    public var lastMessageStatus: String
    public var lastErrorSummary: String?

    public init(
        telegramStatus: String,
        connectionStatus: NotificationConnectionState,
        lastMessageStatus: String,
        lastErrorSummary: String? = nil
    ) {
        self.telegramStatus = telegramStatus
        self.connectionStatus = connectionStatus
        self.lastMessageStatus = lastMessageStatus
        self.lastErrorSummary = lastErrorSummary
    }

    public static func from(settings: NotificationSettings, token: String) -> NotificationRuntimeStatus {
        let telegramStatus: String
        if !settings.isTelegramEnabled {
            telegramStatus = "Disabled"
        } else if token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || settings.chatID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            telegramStatus = "Not Configured"
        } else {
            telegramStatus = "Enabled"
        }

        return NotificationRuntimeStatus(
            telegramStatus: telegramStatus,
            connectionStatus: .notTested,
            lastMessageStatus: "No messages sent",
            lastErrorSummary: nil
        )
    }
}

nonisolated public struct NotificationTransferContext: Equatable, Sendable {
    public var sourceName: String
    public var destinationName: String
    public var phase: String
    public var progressPercent: Double
    public var elapsedSeconds: Int
    public var etaSeconds: TimeInterval?
    public var failureSummary: String?

    public init(
        sourceName: String,
        destinationName: String,
        phase: String,
        progressPercent: Double,
        elapsedSeconds: Int,
        etaSeconds: TimeInterval? = nil,
        failureSummary: String? = nil
    ) {
        self.sourceName = sourceName
        self.destinationName = destinationName
        self.phase = phase
        self.progressPercent = progressPercent
        self.elapsedSeconds = elapsedSeconds
        self.etaSeconds = etaSeconds
        self.failureSummary = failureSummary
    }
}

nonisolated public enum NotificationEventKind: String, Equatable, Hashable, Sendable {
    case jobStarted
    case heartbeat
    case transferFailed
    case copyCompleted
    case verifiedSuccess
    case testMessage
}

nonisolated public enum NotificationMessageFactory {
    public static func message(for event: NotificationEventKind, context: NotificationTransferContext) -> String {
        let header: String
        switch event {
        case .jobStarted:
            header = "FST job started"
        case .heartbeat:
            header = "FST heartbeat"
        case .transferFailed:
            header = "FST transfer failed"
        case .copyCompleted:
            header = "FST copy completed"
        case .verifiedSuccess:
            header = "SAFE TO EJECT / VERIFIED OK"
        case .testMessage:
            header = "FST Telegram test"
        }

        var lines = [
            header,
            "Source: \(safeDisplayName(context.sourceName))",
            "Destination: \(safeDisplayName(context.destinationName))",
            "Phase: \(context.phase)",
            String(format: "Progress: %.0f%%", max(0, min(context.progressPercent, 100))),
            "Elapsed: \(formatDuration(context.elapsedSeconds))"
        ]

        if let etaSeconds = context.etaSeconds, etaSeconds > 0 {
            lines.append("ETA: \(formatDuration(Int(etaSeconds.rounded())))")
        }

        if event == .transferFailed {
            if let failureSummary = context.failureSummary, !failureSummary.isEmpty {
                lines.append("Reason: \(safeSummary(failureSummary))")
            }
            lines.append("Do NOT format source media. Open FST report and technical log before deciding.")
        }

        if event == .testMessage {
            lines.append("Telegram notification is optional and best-effort.")
        }

        return lines.joined(separator: "\n")
    }

    public static func preview(settings: NotificationSettings, sourceName: String, destinationName: String) -> String {
        let context = NotificationTransferContext(
            sourceName: sourceName.isEmpty ? "Source Volume" : sourceName,
            destinationName: destinationName.isEmpty ? "Destination Volume" : destinationName,
            phase: "Copying",
            progressPercent: 42,
            elapsedSeconds: 12 * 60,
            etaSeconds: 18 * 60
        )

        var preview = message(for: .heartbeat, context: context)
        if settings.notifyVerifyCompleted {
            preview += "\n\nSuccess example:\nSAFE TO EJECT / VERIFIED OK"
        }
        return preview
    }

    public static func containsUnsafePath(_ message: String, sourceURL: URL?, destinationURL: URL?) -> Bool {
        if let sourceURL, message.contains(sourceURL.path) {
            return true
        }

        if let destinationURL, message.contains(destinationURL.path) {
            return true
        }

        return false
    }

    private static func safeDisplayName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Unknown" }
        return URL(fileURLWithPath: trimmed).lastPathComponent
    }

    private static func safeSummary(_ value: String) -> String {
        let collapsed = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if collapsed.contains("/") {
            return "See FST report and technical log for details."
        }

        guard collapsed.count > 180 else { return collapsed }
        return String(collapsed.prefix(177)) + "..."
    }

    private static func formatDuration(_ totalSeconds: Int) -> String {
        let seconds = max(0, totalSeconds)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
