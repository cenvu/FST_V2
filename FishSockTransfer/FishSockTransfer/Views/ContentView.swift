// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct ContentView: View {
    private enum MainTab {
        case transfer
        case notification
        case logs
    }

    // TransferViewModel cannot default this to a concrete BookmarkService()
    // itself: BookmarkService.swift is compiled only into the app target, not
    // the canonical XCTest target's explicit source list, so the default has
    // to live at this app-only construction site instead. One shared instance
    // satisfies both protocol roles.
    @StateObject private var viewModel: TransferViewModel = {
        let bookmarkService = BookmarkService()
        return TransferViewModel(bookmarkPersistence: bookmarkService, bookmarkAccessProvider: bookmarkService)
    }()
    @State private var selectedTab: MainTab = .transfer
    @State private var showDiagnostics: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            Divider().overlay(FSTPalette.line)

            Group {
                if selectedTab == .transfer {
                    transferTabContent
                } else if selectedTab == .notification {
                    notificationTabContent
                } else {
                    technicalLogsTabContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .top)

            operationalFooter
        }
        .frame(
            minWidth: 900,
            idealWidth: 1120,
            maxWidth: .infinity,
            minHeight: 660,
            idealHeight: 760,
            alignment: .top
        )
        .foregroundStyle(FSTPalette.text)
        .background(FSTPalette.background)
    }

    private var headerBar: some View {
        HStack(spacing: 16) {
            Text("FST")
                .font(.system(size: 20, weight: .heavy))
                .tracking(-0.8)
            Divider().frame(height: 24).overlay(FSTPalette.line)
            HeaderSocialLinksView()
            Spacer(minLength: 12)
            tabSelector
        }
        .frame(height: 40)
    }

    private var operationalFooter: some View {
        VStack(spacing: 0) {
            Divider().overlay(FSTPalette.line)
            HStack(spacing: 12) {
                Text(TransferControlsActionPresentation.stateTitle(
                    for: viewModel.transferState,
                    canStartTransfer: viewModel.canStartTransfer,
                    errorMessage: viewModel.errorMessage
                ))
                Text("Source protection · Read-only")
                Spacer(minLength: 8)
                Text("CenVu D.I.T Tools")
                    .foregroundStyle(FSTPalette.muted.opacity(0.6))
            }
            .font(.system(size: 14))
            .foregroundStyle(FSTPalette.muted)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .background(FSTPalette.surface)
    }

    private var tabSelector: some View {
        HStack(spacing: 4) {
            Button(action: { selectedTab = .transfer }) {
                Text("TRANSFER")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .frame(minHeight: 32)
                    .background(selectedTab == .transfer ? FSTPalette.raised : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(selectedTab == .transfer ? FSTPalette.line : Color.clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)

            Button(action: { selectedTab = .notification }) {
                Text("NOTIFICATION")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .frame(minHeight: 32)
                    .background(selectedTab == .notification ? FSTPalette.raised : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(selectedTab == .notification ? FSTPalette.line : Color.clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            Button(action: { selectedTab = .logs }) {
                HStack(spacing: 6) {
                    Text("TECHNICAL LOG")
                    Text("\(viewModel.logs.count)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(FSTPalette.muted)
                        .padding(.horizontal, 4)
                }
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .frame(minHeight: 32)
                .background(selectedTab == .logs ? FSTPalette.raised : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(selectedTab == .logs ? FSTPalette.line : Color.clear, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
        }
        .background(FSTPalette.inset)
        .padding(4)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(FSTPalette.line, lineWidth: 1)
        )
        .layoutPriority(1)
    }

    private var transferTabContent: some View {
        ScrollView {
            VStack(spacing: 8) {
                VStack(spacing: 0) {
                    SourceCardView(viewModel: viewModel)
                    Divider().overlay(FSTPalette.line)
                    DestinationCardView(viewModel: viewModel)
                    Divider().overlay(FSTPalette.line)
                    StorageAnalysisView(viewModel: viewModel)
                }
                .background(FSTPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                TransferControlsView(viewModel: viewModel, onOpenTechnicalLog: {
                    selectedTab = .logs
                })
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var notificationTabContent: some View {
        NotificationTabView(viewModel: viewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var technicalLogsTabContent: some View {
        let visibleLogs = showDiagnostics
            ? viewModel.logs
            : LogVisibilityFilter.operatorVisible(from: viewModel.logs)
        let isAutoScrollActive = viewModel.transferState == .copying || viewModel.transferState == .verifying

        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Technical Log")
                    .font(.system(size: 20, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(FSTPalette.text)
                Text("Operational runtime log · Diagnostics optional")
                    .font(.system(size: 14))
                    .foregroundStyle(FSTPalette.muted)
            }
            .padding(.bottom, 12)

            HStack(spacing: 16) {
                Toggle(isOn: $showDiagnostics) {
                    Text("Show Diagnostics")
                        .font(.system(size: 14))
                        .foregroundStyle(FSTPalette.text)
                }
                .toggleStyle(.checkbox)

                if isAutoScrollActive {
                    Text("Auto-scroll active")
                        .font(.system(size: 12))
                        .foregroundStyle(FSTPalette.active)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, 8)

            TerminalLogsView(logs: visibleLogs, autoScroll: isAutoScrollActive)
                .frame(maxWidth: .infinity, maxHeight: 520)

            HStack(spacing: 12) {
                Text("\(visibleLogs.count) visible / \(viewModel.logs.count) total entries")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(FSTPalette.muted)
                Spacer(minLength: 8)
                Text("Filtering does not change the complete log.")
                    .font(.system(size: 12))
                    .foregroundStyle(FSTPalette.muted)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.top, 8)

            TechnicalLogsMetadataFooter(
                rsyncVersionText: rsyncHeaderBadgeText,
                isRsyncAvailable: viewModel.bundledRsyncInfo.isAvailable,
                isTransferRunning: isAutoScrollActive
            )
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }



    private var rsyncHeaderBadgeText: String {
        let info = viewModel.bundledRsyncInfo

        guard !info.isAvailable else {
            return "Bundled rsync \(info.version)"
        }

        let diagnostic = info.diagnostics.first ?? ""
        if diagnostic.localizedCaseInsensitiveContains("not executable") {
            return "Bundled rsync not executable"
        }
        if diagnostic.localizedCaseInsensitiveContains("missing") {
            return "Bundled rsync missing"
        }
        if diagnostic.localizedCaseInsensitiveContains("version mismatch") {
            return "Bundled rsync wrong version \(info.version)"
        }
        if diagnostic.localizedCaseInsensitiveContains("timed out") {
            return "Bundled rsync timeout"
        }
        if diagnostic.localizedCaseInsensitiveContains("unrecognized") {
            return "Bundled rsync invalid"
        }

        return "Bundled rsync unavailable"
    }
}

struct HeaderSocialLinksView: View {
    var body: some View {
        HStack(spacing: 8) {
            SocialIconLink(
                iconName: "icon_facebook_mono",
                url: URL(string: "https://fb.com/cenvu")!,
                accessibilityLabel: "Open CenVu Facebook",
                helpTooltip: "Facebook"
            )
            SocialIconLink(
                iconName: "icon_instagram_mono",
                url: URL(string: "https://www.instagram.com/cenvu/")!,
                accessibilityLabel: "Open CenVu Instagram",
                helpTooltip: "Instagram"
            )
            SocialIconLink(
                iconName: "icon_whatsapp_mono",
                url: URL(string: "https://wa.me/84842841222")!,
                accessibilityLabel: "Message CenVu on WhatsApp",
                helpTooltip: "WhatsApp"
            )
            SocialIconLink(
                iconName: "icon_telegram_mono",
                url: URL(string: "https://t.me/+84842841222")!,
                accessibilityLabel: "Message CenVu on Telegram",
                helpTooltip: "Telegram"
            )
        }
    }
}

struct SocialIconLink: View {
    let iconName: String
    let url: URL
    let accessibilityLabel: String
    let helpTooltip: String
    
    @State private var isHovered = false
    
    var body: some View {
        Link(destination: url) {
            Image(iconName)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(isHovered ? .accentColor : .secondary)
                .opacity(isHovered ? 1.0 : 0.7)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered ? Color.secondary.opacity(0.12) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help(helpTooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct TechnicalLogsMetadataFooter: View {
    let rsyncVersionText: String
    let isRsyncAvailable: Bool
    let isTransferRunning: Bool

    @StateObject private var updateVM = TechnicalLogsUpdateViewModel()

    var body: some View {
        HStack(spacing: 12) {
            MetadataBadge(label: "version", value: "v1.3.5", helpText: "App version from README.md", isError: false)
            MetadataBadge(
                label: "bundled rsync",
                value: rsyncVersionText.replacingOccurrences(of: "Bundled rsync ", with: ""),
                helpText: "Bundled rsync version used by FST",
                isError: !isRsyncAvailable
            )
            MetadataBadge(label: "license", value: "Source Available / Non-Commercial", helpText: "Project license from README.md", isError: false)

            Spacer()

            updateCheckUI
        }
    }

    @ViewBuilder
    private var updateCheckUI: some View {
        HStack(spacing: 8) {
            switch updateVM.state {
            case .idle:
                EmptyView()
            case .checking:
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.5)
                    Text("Checking...")
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundColor(.secondary)
                }
            case .upToDate:
                Text("Up to date")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(.secondary)
            case .updateAvailable(_, let latestVersion, let releaseURL, let downloadURL):
                HStack(spacing: 6) {
                    Text("Update available: v\(latestVersion)")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color(NSColor.controlAccentColor))

                    Button("View Release") {
                        NSWorkspace.shared.open(releaseURL)
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 10.5, weight: .regular))

                    if let downloadURL = downloadURL {
                        Button("Download") {
                            NSWorkspace.shared.open(downloadURL)
                        }
                        .buttonStyle(.link)
                        .font(.system(size: 10.5, weight: .regular))
                    }
                }
            case .failed:
                Text("Update check failed")
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(.orange)
            }

            Button(action: {
                updateVM.checkForUpdates()
            }) {
                Text("Check for Updates")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(isTransferRunning || isChecking ? .secondary.opacity(0.5) : .primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isTransferRunning || isChecking)
            .help(isTransferRunning ? "Update checks are disabled while transfer or verification is running." : "Check GitHub for the latest release")
        }
    }

    private var isChecking: Bool {
        if case .checking = updateVM.state {
            return true
        }
        return false
    }
}

struct MetadataBadge: View {
    let label: String
    let value: String
    let helpText: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 10.5, weight: .regular))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Text(value)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(isError ? .orange : .primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isError ? Color.orange.opacity(0.16) : Color.secondary.opacity(0.15))
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isError ? Color.orange.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .help(helpText)
    }
}
