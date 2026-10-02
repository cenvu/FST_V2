// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct ContentView: View {
    @Environment(\.locale) private var locale

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
    @State private var autoScrollLogs: Bool = true
    
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
                Text(TransferPresentationLocalization.text(
                    TransferControlsActionPresentation.stateTitle(
                        for: viewModel.transferState,
                        canStartTransfer: viewModel.canStartTransfer,
                        errorMessage: viewModel.errorMessage
                    ),
                    locale: locale
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
        let isTransferRunning = viewModel.transferState == .copying || viewModel.transferState == .verifying

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

            TechnicalLogsActionBar(
                showDiagnostics: $showDiagnostics,
                autoScroll: $autoScrollLogs,
                logs: viewModel.logs,
                isTransferRunning: isTransferRunning
            )
            .padding(.bottom, 8)

            TerminalLogsView(logs: visibleLogs, autoScroll: autoScrollLogs)
                .frame(maxWidth: .infinity, maxHeight: 520)

            HStack(spacing: 12) {
                Text(L2PresentationLocalization.logEntrySummary(
                    visible: visibleLogs.count,
                    total: viewModel.logs.count,
                    locale: locale
                ))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(FSTPalette.muted)
                Spacer(minLength: 8)
                Text("Filtering does not change the complete log.")
                    .font(.system(size: 12))
                    .foregroundStyle(FSTPalette.muted)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
    @Environment(\.locale) private var locale
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
        .accessibilityLabel(L2PresentationLocalization.text(accessibilityLabel, locale: locale))
        .help(helpTooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
