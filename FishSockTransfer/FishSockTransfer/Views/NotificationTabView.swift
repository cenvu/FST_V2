// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct NotificationTabView: View {
    @ObservedObject var viewModel: TransferViewModel

    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                notificationStatusSection
                telegramSetupSection
                notifyEventsSection
                heartbeatSection
                messagePreviewSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .onChange(of: viewModel.notificationSettings) { _ in
            viewModel.persistNotificationSettings()
        }
        .onChange(of: viewModel.telegramBotToken) { _ in
            viewModel.persistTelegramBotToken()
        }
    }

    private var notificationStatusSection: some View {
        NotificationSection(title: "Notification Status") {
            LazyVGrid(columns: statusColumns, alignment: .leading, spacing: 10) {
                statusRow("Telegram status", viewModel.notificationStatus.telegramStatus)
                statusRow("Connection status", viewModel.notificationStatus.connectionStatus.displayText)
                statusRow("Last message", viewModel.notificationStatus.lastMessageStatus)
                statusRow("Last error", viewModel.notificationStatus.lastErrorSummary ?? "-")
            }
        }
    }

    private var telegramSetupSection: some View {
        NotificationSection(title: "Telegram Setup") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Enable Telegram Notification", isOn: $viewModel.notificationSettings.isTelegramEnabled)
                    .toggleStyle(.checkbox)

                SecureField("Bot Token", text: $viewModel.telegramBotToken)
                    .textFieldStyle(.roundedBorder)
                    .help("Stored in Keychain. The token is not shown in plain text.")

                TextField("Chat ID", text: $viewModel.notificationSettings.chatID)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Test Message") {
                        viewModel.testTelegramNotification()
                    }
                    .keyboardShortcut(.defaultAction)

                    Text("Telegram notification is optional and best-effort. It never changes transfer, verify, report, or SAFE TO EJECT results.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var notifyEventsSection: some View {
        NotificationSection(title: "Notify Events") {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Job starts", isOn: $viewModel.notificationSettings.notifyJobStarts)
                Toggle("Heartbeat while running", isOn: $viewModel.notificationSettings.notifyHeartbeat)
                Toggle("Transfer fails", isOn: $viewModel.notificationSettings.notifyTransferFails)
                Toggle("Copy completed", isOn: $viewModel.notificationSettings.notifyCopyCompleted)
                Toggle("Verify completed / Safe to eject", isOn: $viewModel.notificationSettings.notifyVerifyCompleted)
            }
            .toggleStyle(.checkbox)
        }
    }

    private var heartbeatSection: some View {
        NotificationSection(title: "Heartbeat Interval") {
            Picker("Heartbeat Interval", selection: $viewModel.notificationSettings.heartbeatInterval) {
                ForEach(TelegramHeartbeatInterval.allCases) { interval in
                    Text(interval.displayLabel).tag(interval)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280, alignment: .leading)
        }
    }

    private var messagePreviewSection: some View {
        NotificationSection(title: "Message Preview") {
            Text(NotificationMessageFactory.preview(
                settings: viewModel.notificationSettings,
                sourceName: viewModel.sourceURL?.lastPathComponent ?? "Source Volume",
                destinationName: viewModel.destinationURL?.lastPathComponent ?? "Destination Volume"
            ))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.secondary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(NSColor.textBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var statusColumns: [GridItem] {
        [
            GridItem(.fixed(150), alignment: .leading),
            GridItem(.flexible(), alignment: .leading)
        ]
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        Group {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded))
                .foregroundColor(value == "Error" ? .orange : .primary)
                .lineLimit(2)
                .truncationMode(.middle)
        }
    }
}

private struct NotificationSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }
}
