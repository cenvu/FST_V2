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
                statusAndSetupSection
                    .fixedSize(horizontal: false, vertical: true)

                eventsAndHeartbeatSection
                    .fixedSize(horizontal: false, vertical: true)

                messagePreviewSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .onChange(of: viewModel.notificationSettings) { _ in
            viewModel.persistNotificationSettings()
        }
        .onChange(of: viewModel.telegramBotToken) { _ in
            viewModel.persistTelegramBotToken()
        }
    }

    private var statusAndSetupSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Notification Status (Left 1/3 approx)
            VStack(alignment: .leading, spacing: 10) {
                Text("Notification Status")
                    .font(.headline)
                    .foregroundColor(.primary)

                LazyVGrid(columns: statusColumns, alignment: .leading, spacing: 10) {
                    statusRow("Telegram status", viewModel.notificationStatus.telegramStatus)
                    statusRow("Connection status", viewModel.notificationStatus.connectionStatus.displayText)
                    statusRow("Last message", viewModel.notificationStatus.lastMessageStatus)
                    statusRow("Last error", viewModel.notificationStatus.lastErrorSummary ?? "-")
                }
            }
            .frame(minWidth: 220, maxWidth: 300, alignment: .top)

            Divider()

            // Telegram Setup (Right 2/3 approx)
            VStack(alignment: .leading, spacing: 10) {
                Text("Telegram Setup")
                    .font(.headline)
                    .foregroundColor(.primary)

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
                    .disabled(viewModel.isSendingTelegramTestMessage)

                    Text("Telegram notification is optional and best-effort. It never changes transfer, verify, report, or SAFE TO EJECT results.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }

    private var eventsAndHeartbeatSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Notify Events (Left 1/2)
            VStack(alignment: .leading, spacing: 10) {
                Text("Notify Events")
                    .font(.headline)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Job starts", isOn: $viewModel.notificationSettings.notifyJobStarts)
                    Toggle("Heartbeat while running", isOn: $viewModel.notificationSettings.notifyHeartbeat)
                    Toggle("Transfer fails", isOn: $viewModel.notificationSettings.notifyTransferFails)
                    Toggle("Copy completed", isOn: $viewModel.notificationSettings.notifyCopyCompleted)
                    Toggle("Verify completed / Safe to eject", isOn: $viewModel.notificationSettings.notifyVerifyCompleted)
                }
                .toggleStyle(.checkbox)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Divider()

            // Notification Options (Right 1/2)
            VStack(alignment: .leading, spacing: 12) {
                Text("Notification Options")
                    .font(.headline)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Heartbeat Interval").font(.caption).foregroundColor(.secondary)
                    Picker("Heartbeat Interval", selection: $viewModel.notificationSettings.heartbeatInterval) {
                        ForEach(TelegramHeartbeatInterval.allCases) { interval in
                            Text(interval.displayLabel).tag(interval)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Message Detail").font(.caption).foregroundColor(.secondary)
                    Picker("Message Detail", selection: $viewModel.notificationSettings.messageDetail) {
                        ForEach(TelegramMessageDetail.allCases) { detail in
                            Text(detail.displayLabel).tag(detail)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 280, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }

    private var messagePreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message Preview")
                .font(.headline)
                .foregroundColor(.primary)

            Text(NotificationMessageFactory.preview(
                settings: viewModel.notificationSettings,
                sourceName: viewModel.sourceURL?.lastPathComponent ?? "Source Volume",
                destinationName: viewModel.destinationURL?.lastPathComponent ?? "Destination Volume"
            ))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.secondary)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.textBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
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
