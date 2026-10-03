
import SwiftUI

public struct NotificationTabView: View {
    @Environment(\.locale) private var locale
    @ObservedObject var viewModel: TransferViewModel

    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text("Notifications")
                        .font(.system(size: 20, weight: .semibold))
                    Spacer(minLength: 0)
                    Text("Optional · best-effort · separate from job safety")
                        .font(.system(size: 14))
                        .foregroundStyle(FSTPalette.muted)
                }

                NotificationColumnsLayout {
                    VStack(alignment: .leading, spacing: 16) {
                        telegramSetupSection
                        notifyEventsSection
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        notificationStatusSection
                        messagePreviewSection
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .foregroundStyle(FSTPalette.text)
        .onChange(of: viewModel.notificationSettings) { _ in
            viewModel.persistNotificationSettings()
        }
        .onChange(of: viewModel.telegramBotToken) { _ in
            viewModel.persistTelegramBotToken()
        }
    }

    private var telegramSetupSection: some View {
        notificationSection("Telegram Setup") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Notification delivery never changes transfer or verification results.")
                    .font(.system(size: 14))
                    .foregroundStyle(FSTPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle("Enable Telegram Notification", isOn: $viewModel.notificationSettings.isTelegramEnabled)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 16))
                    .tint(FSTPalette.active)

                notificationField("Bot Token") {
                    SecureField("Bot Token", text: $viewModel.telegramBotToken)
                        .help(L2PresentationLocalization.text(
                            "Stored in Keychain. The token is not shown in plain text.",
                            locale: locale
                        ))
                        .modifier(NotificationInputStyle())
                }

                notificationField("Chat ID") {
                    TextField("Chat ID", text: $viewModel.notificationSettings.chatID)
                        .modifier(NotificationInputStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Button("Test Message") {
                        viewModel.testTelegramNotification()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(minHeight: 36)
                    .disabled(viewModel.isSendingTelegramTestMessage)

                    Text("Telegram notification is optional and best-effort. It never changes transfer, verify, report, or SAFE TO EJECT results.")
                        .font(.footnote)
                        .foregroundStyle(FSTPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var notifyEventsSection: some View {
        notificationSection("Notify Events") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Job starts", isOn: $viewModel.notificationSettings.notifyJobStarts)
                    Toggle("Heartbeat while running", isOn: $viewModel.notificationSettings.notifyHeartbeat)
                    Toggle("Transfer fails", isOn: $viewModel.notificationSettings.notifyTransferFails)
                    Toggle("Copy completed", isOn: $viewModel.notificationSettings.notifyCopyCompleted)
                    Toggle("Verify completed / Safe to eject", isOn: $viewModel.notificationSettings.notifyVerifyCompleted)
                }
                .toggleStyle(.checkbox)
                .font(.system(size: 16))
                .tint(FSTPalette.active)

                NotificationColumnsLayout(leftRatio: 1, rightRatio: 1.4) {
                    notificationField("Heartbeat Interval") {
                        Picker("Heartbeat Interval", selection: $viewModel.notificationSettings.heartbeatInterval) {
                            ForEach(TelegramHeartbeatInterval.allCases) { interval in
                                Text(L2PresentationLocalization.text(interval.displayLabel, locale: locale)).tag(interval)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    notificationField("Message Detail") {
                        Picker("Message Detail", selection: $viewModel.notificationSettings.messageDetail) {
                            ForEach(TelegramMessageDetail.allCases) { detail in
                                Text(L2PresentationLocalization.text(detail.displayLabel, locale: locale)).tag(detail)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, minHeight: 36)
                    }
                }
            }
        }
    }

    private var notificationStatusSection: some View {
        notificationSection("Notification Status") {
            VStack(alignment: .leading, spacing: 16) {
                statusRow("Telegram status", viewModel.notificationStatus.telegramStatus, localizeKnownValue: true)
                statusRow(
                    "Connection status",
                    viewModel.notificationStatus.connectionStatus.displayText,
                    isError: viewModel.notificationStatus.connectionStatus == .error,
                    localizeKnownValue: true
                )
                statusRow("Last message", viewModel.notificationStatus.lastMessageStatus, localizeKnownValue: true)
                statusRow("Last error", viewModel.notificationStatus.lastErrorSummary ?? "-",
                          isError: viewModel.notificationStatus.lastErrorSummary != nil)
            }
        }
    }

    private var messagePreviewSection: some View {
        notificationSection("Message Preview") {
            Text(NotificationMessageFactory.preview(
                settings: viewModel.notificationSettings,
                sourceName: viewModel.sourceURL?.lastPathComponent ?? "Source Volume",
                destinationName: viewModel.destinationURL?.lastPathComponent ?? "Destination Volume"
            ))
            .font(.system(size: 16, design: .monospaced))
            .lineSpacing(6)
            .foregroundStyle(FSTPalette.text)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FSTPalette.inset)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(FSTPalette.line, lineWidth: 1))
        }
    }

    private func statusRow(
        _ label: String,
        _ value: String,
        isError: Bool = false,
        localizeKnownValue: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L2PresentationLocalization.text(label, locale: locale))
                .font(.system(size: 14))
                .foregroundStyle(FSTPalette.muted)
            Text(localizeKnownValue ? L2PresentationLocalization.text(value, locale: locale) : value)
                .font(.system(size: 16))
                .foregroundStyle(isError || value == "Error" ? FSTPalette.warning : FSTPalette.text)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .help(localizeKnownValue ? L2PresentationLocalization.text(value, locale: locale) : value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func notificationField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L2PresentationLocalization.text(title, locale: locale))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(FSTPalette.muted)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func notificationSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L2PresentationLocalization.text(title, locale: locale))
                .font(.system(size: 16, weight: .semibold))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(FSTPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(FSTPalette.line, lineWidth: 1))
    }
}

private struct NotificationInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(FSTPalette.inset)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(FSTPalette.line, lineWidth: 1))
    }
}

/// Two top-aligned tracks, measured at their assigned width so ScrollView
/// retains the full height of wrapped text and controls at the minimum window.
private struct NotificationColumnsLayout: Layout {
    var leftRatio: CGFloat = 1.5
    var rightRatio: CGFloat = 1
    var spacing: CGFloat = 16

    private func widths(for width: CGFloat) -> (CGFloat, CGFloat) {
        let available = max(0, width - spacing)
        let left = available * leftRatio / (leftRatio + rightRatio)
        return (left, available - left)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let width = proposal.width ?? 900
        let (left, right) = widths(for: width)
        let leftSize = subviews[0].sizeThatFits(ProposedViewSize(width: left, height: nil))
        let rightSize = subviews[1].sizeThatFits(ProposedViewSize(width: right, height: nil))
        return CGSize(width: width, height: max(leftSize.height, rightSize.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let (left, right) = widths(for: bounds.width)
        subviews[0].place(at: bounds.origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: left, height: nil))
        subviews[1].place(at: CGPoint(x: bounds.minX + left + spacing, y: bounds.minY), anchor: .topLeading,
                          proposal: ProposedViewSize(width: right, height: nil))
    }
}
