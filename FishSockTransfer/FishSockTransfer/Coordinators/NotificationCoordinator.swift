// FST / CenVu | (+84) 842 841 222

import Foundation

public actor NotificationCoordinator {
    private let service: NotificationService
    private var sentTerminalEvents: Set<NotificationEventKind> = []
    private var lastHeartbeatAt: Date?

    public init(service: NotificationService = TelegramNotificationService()) {
        self.service = service
    }

    public func resetForNewJob() {
        sentTerminalEvents.removeAll()
        lastHeartbeatAt = nil
    }

    public func markRunningStarted(now: Date = Date()) {
        if lastHeartbeatAt == nil {
            lastHeartbeatAt = now
        }
    }

    public func sendTestMessage(
        settings: NotificationSettings,
        token: String,
        context: NotificationTransferContext,
        now: Date = Date()
    ) async -> NotificationRuntimeStatus {
        await send(
            event: .testMessage,
            settings: settings,
            token: token,
            context: context,
            now: now,
            deduplicate: false
        )
    }

    public func notifyJobStarted(
        settings: NotificationSettings,
        token: String,
        context: NotificationTransferContext,
        now: Date = Date()
    ) async -> NotificationRuntimeStatus? {
        resetForNewJob()
        guard settings.notifyJobStarts else { return nil }

        return await send(
            event: .jobStarted,
            settings: settings,
            token: token,
            context: context,
            now: now,
            deduplicate: true
        )
    }

    public func notifyCopyCompleted(
        settings: NotificationSettings,
        token: String,
        context: NotificationTransferContext,
        now: Date = Date()
    ) async -> NotificationRuntimeStatus? {
        guard settings.notifyCopyCompleted else { return nil }

        return await send(
            event: .copyCompleted,
            settings: settings,
            token: token,
            context: context,
            now: now,
            deduplicate: true
        )
    }

    public func notifyFailure(
        settings: NotificationSettings,
        token: String,
        context: NotificationTransferContext,
        now: Date = Date()
    ) async -> NotificationRuntimeStatus? {
        guard settings.notifyTransferFails else { return nil }

        return await send(
            event: .transferFailed,
            settings: settings,
            token: token,
            context: context,
            now: now,
            deduplicate: true
        )
    }

    public func notifyVerifiedSuccess(
        settings: NotificationSettings,
        token: String,
        context: NotificationTransferContext,
        now: Date = Date()
    ) async -> NotificationRuntimeStatus? {
        guard settings.notifyVerifyCompleted else { return nil }

        return await send(
            event: .verifiedSuccess,
            settings: settings,
            token: token,
            context: context,
            now: now,
            deduplicate: true
        )
    }

    public func sendHeartbeatIfDue(
        settings: NotificationSettings,
        token: String,
        context: NotificationTransferContext,
        now: Date = Date()
    ) async -> NotificationRuntimeStatus? {
        guard settings.notifyHeartbeat else { return nil }
        guard context.phase == "Copying" || context.phase == "Verifying" else { return nil }

        if let lastHeartbeatAt, now.timeIntervalSince(lastHeartbeatAt) < settings.heartbeatInterval.seconds {
            return nil
        }

        let status = await send(
            event: .heartbeat,
            settings: settings,
            token: token,
            context: context,
            now: now,
            deduplicate: false
        )

        if status.connectionStatus == .ready {
            lastHeartbeatAt = now
        }

        return status
    }

    private func send(
        event: NotificationEventKind,
        settings: NotificationSettings,
        token: String,
        context: NotificationTransferContext,
        now: Date,
        deduplicate: Bool
    ) async -> NotificationRuntimeStatus {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedChatID = settings.chatID.trimmingCharacters(in: .whitespacesAndNewlines)

        guard settings.isTelegramEnabled else {
            return NotificationRuntimeStatus(
                telegramStatus: "Disabled",
                connectionStatus: .notTested,
                lastMessageStatus: "Skipped: Telegram notification disabled",
                lastErrorSummary: nil
            )
        }

        guard !trimmedToken.isEmpty, !trimmedChatID.isEmpty else {
            return NotificationRuntimeStatus(
                telegramStatus: "Not Configured",
                connectionStatus: .error,
                lastMessageStatus: "Telegram not configured",
                lastErrorSummary: TelegramNotificationError.missingConfiguration.errorDescription
            )
        }

        if deduplicate, sentTerminalEvents.contains(event) {
            return NotificationRuntimeStatus(
                telegramStatus: "Enabled",
                connectionStatus: .ready,
                lastMessageStatus: "Skipped duplicate \(event.rawValue)",
                lastErrorSummary: nil
            )
        }

        let message = NotificationMessageFactory.message(for: event, context: context)
        do {
            try await service.sendMessage(
                message,
                configuration: TelegramNotificationConfiguration(botToken: trimmedToken, chatID: trimmedChatID)
            )
            if deduplicate {
                sentTerminalEvents.insert(event)
            }

            return NotificationRuntimeStatus(
                telegramStatus: "Enabled",
                connectionStatus: .ready,
                lastMessageStatus: "Sent \(label(for: event)) at \(timeFormatter.string(from: now))",
                lastErrorSummary: nil
            )
        } catch {
            return NotificationRuntimeStatus(
                telegramStatus: "Enabled",
                connectionStatus: .error,
                lastMessageStatus: "Telegram send failed",
                lastErrorSummary: error.localizedDescription
            )
        }
    }

    private func label(for event: NotificationEventKind) -> String {
        switch event {
        case .jobStarted:
            return "job start"
        case .heartbeat:
            return "heartbeat"
        case .transferFailed:
            return "failure"
        case .copyCompleted:
            return "copy completed"
        case .verifiedSuccess:
            return "verified success"
        case .testMessage:
            return "test message"
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}
