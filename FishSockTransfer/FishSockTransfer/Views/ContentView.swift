// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct ContentView: View {
    private enum MainTab {
        case transfer
        case notification
        case logs
    }

    private let tabContentHeight: CGFloat = 600

    @StateObject private var viewModel = TransferViewModel()
    @State private var selectedTab: MainTab = .transfer
    @State private var showDiagnostics: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

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
            .frame(height: tabContentHeight, alignment: .top)
        }
        .frame(
            minWidth: 900,
            idealWidth: 1120,
            maxWidth: .infinity,
            minHeight: 660,
            idealHeight: 760,
            maxHeight: 860,
            alignment: .top
        )
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var headerBar: some View {
        let headerFont = Font.system(.caption, weight: .semibold)
        
        return ZStack {
            HStack(spacing: 0) {
                Text("CenVu D.I.T Tools")
                    .font(headerFont)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                    .frame(width: 220, alignment: .leading)

                Spacer(minLength: 0)

                HeaderSocialLinksView()
                    .frame(width: 150, alignment: .trailing)
            }

            tabSelector
                .frame(width: 560, alignment: .center)
        }
        .frame(height: 44)
        .layoutPriority(1)
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = .transfer }) {
                Text("TRANSFER")
                    .fontWeight(selectedTab == .transfer ? .bold : .semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .background(selectedTab == .transfer ? Color(NSColor.controlAccentColor).opacity(0.15) : Color.clear)
                    .foregroundColor(selectedTab == .transfer ? Color(NSColor.controlAccentColor) : .secondary)
            }
            .buttonStyle(.plain)

            Button(action: { selectedTab = .notification }) {
                Text("NOTIFICATION")
                    .fontWeight(selectedTab == .notification ? .bold : .semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .background(selectedTab == .notification ? Color(NSColor.controlAccentColor).opacity(0.15) : Color.clear)
                    .foregroundColor(selectedTab == .notification ? Color(NSColor.controlAccentColor) : .secondary)
            }
            .buttonStyle(.plain)
            
            Button(action: { selectedTab = .logs }) {
                HStack(spacing: 6) {
                    Text("TECHNICAL LOG")
                    Text("\(viewModel.logs.count)")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
                .fontWeight(selectedTab == .logs ? .bold : .semibold)
                .padding(.horizontal, 24)
                .padding(.vertical, 6)
                .background(selectedTab == .logs ? Color(NSColor.controlAccentColor).opacity(0.15) : Color.clear)
                .foregroundColor(selectedTab == .logs ? Color(NSColor.controlAccentColor) : .secondary)
            }
            .buttonStyle(.plain)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .layoutPriority(1)
    }

    private var transferTabContent: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                SourceCardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
                DestinationCardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
            
            TransferControlsView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var notificationTabContent: some View {
        NotificationTabView(viewModel: viewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var technicalLogsTabContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Toggle(isOn: $showDiagnostics) {
                    Text("Show Diagnostics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.checkbox)
                .padding(.bottom, 6)
                .padding(.trailing, 2)
            }
            TerminalLogsView(
                logs: showDiagnostics ? viewModel.logs : LogVisibilityFilter.operatorVisible(from: viewModel.logs),
                autoScroll: viewModel.transferState == .copying || viewModel.transferState == .verifying
            )

            TechnicalLogsMetadataFooter(
                rsyncVersionText: rsyncHeaderBadgeText,
                isRsyncAvailable: viewModel.bundledRsyncInfo.isAvailable,
                isTransferRunning: viewModel.transferState == .copying || viewModel.transferState == .verifying
            )
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
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
        HStack(spacing: 10) {
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
                .frame(width: 14, height: 14)
                .foregroundColor(isHovered ? .accentColor : .secondary)
                .opacity(isHovered ? 1.0 : 0.7)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.accentColor.opacity(0.12) : Color.clear)
                )
                .shadow(color: isHovered ? Color.accentColor.opacity(0.2) : .clear, radius: 2)
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
            MetadataBadge(label: "version", value: "v1.3.3", helpText: "App version from README.md", isError: false)
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
