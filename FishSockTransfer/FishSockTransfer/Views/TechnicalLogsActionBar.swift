// FST / CenVu | (+84) 842 841 222

import AppKit
import SwiftUI

struct TechnicalLogsActionBar: View {
    @Environment(\.locale) private var locale
    @Binding var showDiagnostics: Bool
    @Binding var autoScroll: Bool
    @Binding var copyFeedbackState: TechnicalLogCopyFeedbackState

    let logs: [LogEntry]
    let isTransferRunning: Bool

    @State private var isShowingDetails = false
    @StateObject private var updateViewModel = TechnicalLogsUpdateViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Toggle(isOn: $showDiagnostics) {
                    Text(L2PresentationLocalization.text("Show Diagnostics", locale: locale))
                        .foregroundStyle(FSTPalette.text)
                }
                .toggleStyle(.checkbox)
                .help(L2PresentationLocalization.text("Show or hide diagnostic entries in the log view.", locale: locale))

                Toggle(isOn: $autoScroll) {
                    Text(L2PresentationLocalization.text("Auto-scroll", locale: locale))
                        .foregroundStyle(FSTPalette.text)
                }
                .toggleStyle(.checkbox)
                .help(L2PresentationLocalization.text("Automatically scroll to the newest log entries.", locale: locale))

                Spacer(minLength: 8)

                Button {
                    let feedback = withAnimation(.easeOut(duration: 0.18)) {
                        copyFeedbackState.copyAll(logs: logs)
                    }
                    let message = L2PresentationLocalization.text(feedback.localizationKey, locale: locale)
                    NSAccessibility.post(
                        element: NSApplication.shared,
                        notification: .announcementRequested,
                        userInfo: [
                            .announcement: message,
                            .priority: NSAccessibilityPriorityLevel.medium.rawValue
                        ]
                    )
                } label: {
                    Text(L2PresentationLocalization.text("Copy All Logs", locale: locale))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(logs.isEmpty)
                .accessibilityLabel(L2PresentationLocalization.text("Copy All Logs", locale: locale))
                .help(L2PresentationLocalization.text(
                    "Copies the complete retained log history, including diagnostic entries.",
                    locale: locale
                ))

                Button {
                    isShowingDetails = true
                } label: {
                    Text(L2PresentationLocalization.text("Log details", locale: locale))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(L2PresentationLocalization.text("Log details", locale: locale))
                .help(L2PresentationLocalization.text("Open a selectable view of the complete log history.", locale: locale))

                Button(action: updateViewModel.checkForUpdates) {
                    Text(L2PresentationLocalization.text("Check for Update", locale: locale))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isTransferRunning || isChecking)
                .accessibilityLabel(L2PresentationLocalization.text("Check for Update", locale: locale))
                .help(L2PresentationLocalization.text(
                    isTransferRunning
                        ? "Update checks are disabled while transfer or verification is running."
                        : "Check GitHub for the latest release",
                    locale: locale
                ))
            }
            .font(.system(size: 12.5))

            if !isUpdateIdle {
                updateStatus
                .font(.system(size: 12))
                .padding(.leading, 2)
            }
        }
        .sheet(isPresented: $isShowingDetails) {
            TechnicalLogDetailsSheet(logs: logs)
        }
    }

    @ViewBuilder
    private var updateStatus: some View {
        switch updateViewModel.state {
        case .idle:
            EmptyView()
        case .checking:
            HStack(spacing: 5) {
                ProgressView().controlSize(.small).scaleEffect(0.7)
                Text(L2PresentationLocalization.text("Checking...", locale: locale))
                    .foregroundStyle(FSTPalette.muted)
            }
        case .upToDate:
            Label(
                L2PresentationLocalization.text("Up to date", locale: locale),
                systemImage: "checkmark.circle"
            )
            .foregroundStyle(FSTPalette.muted)
        case .updateAvailable(_, let latestVersion, let releaseURL, let downloadURL):
            HStack(spacing: 8) {
                Text(L2PresentationLocalization.updateAvailable(version: latestVersion, locale: locale))
                    .foregroundStyle(FSTPalette.active)
                Button(L2PresentationLocalization.text("View Release", locale: locale)) {
                    NSWorkspace.shared.open(releaseURL)
                }
                .buttonStyle(.link)
                if let downloadURL {
                    Button(L2PresentationLocalization.text("Download", locale: locale)) {
                        NSWorkspace.shared.open(downloadURL)
                    }
                    .buttonStyle(.link)
                }
            }
        case .failed:
            Label(
                L2PresentationLocalization.text("Update check failed", locale: locale),
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)
        }
    }

    private var isChecking: Bool {
        if case .checking = updateViewModel.state { return true }
        return false
    }

    private var isUpdateIdle: Bool {
        if case .idle = updateViewModel.state { return true }
        return false
    }
}

struct TechnicalLogCopyToast: View {
    let feedback: TechnicalLogCopyFeedback
    let locale: Locale

    private var message: String {
        L2PresentationLocalization.text(feedback.localizationKey, locale: locale)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: feedback == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(feedback == .success ? FSTPalette.active : Color.orange)
                .accessibilityHidden(true)

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(FSTPalette.text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 400, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(FSTPalette.line, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 9, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

private extension TechnicalLogCopyFeedback {
    var localizationKey: String {
        switch self {
        case .success: "All log entries copied to the clipboard, including diagnostics."
        case .failure: "Could not copy logs to the clipboard. Please try again."
        }
    }
}

private struct TechnicalLogDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    let logs: [LogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L2PresentationLocalization.text("Full log history", locale: locale))
                        .font(.system(size: 18, weight: .semibold))
                    Text(L2PresentationLocalization.text(
                        "All currently retained runtime log entries are shown here, including diagnostics.",
                        locale: locale
                    ))
                    .font(.system(size: 12))
                    .foregroundStyle(FSTPalette.muted)
                }
                Spacer()
                Button(L2PresentationLocalization.text("Close", locale: locale)) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }

            Divider().overlay(FSTPalette.line)

            if logs.isEmpty {
                Text(L2PresentationLocalization.text("No log entries yet", locale: locale))
                    .foregroundStyle(FSTPalette.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    Text(TechnicalLogClipboard.formattedHistory(logs))
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .background(FSTPalette.inset)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(FSTPalette.line, lineWidth: 1)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 420)
        .background(FSTPalette.background)
    }
}
