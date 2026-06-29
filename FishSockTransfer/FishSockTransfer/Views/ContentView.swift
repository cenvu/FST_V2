import SwiftUI

public struct ContentView: View {
    private enum MainTab {
        case transfer
        case logs
    }

    private let tabContentHeight: CGFloat = 600

    @StateObject private var viewModel = TransferViewModel()
    @State private var selectedTab: MainTab = .transfer
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            tabSelector
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            Group {
                if selectedTab == .transfer {
                    transferTabContent
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
        ZStack {
            let headerFont = Font.system(.caption, weight: .semibold)
            
            HStack {
                Text("FishSock Transfer")
                    .font(headerFont)
                    .foregroundColor(.primary)

                Spacer()

                Text("CenVu | hungvh.hfs@gmail.com")
                    .font(headerFont)
                    .foregroundColor(.secondary)
            }

            Text(rsyncHeaderBadgeText)
                .font(headerFont)
                .foregroundColor(rsyncBadgeForegroundColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(rsyncBadgeBackgroundColor)
                .clipShape(Capsule())
        }
        .frame(height: 32)
        .layoutPriority(1)
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            Button(action: { selectedTab = .transfer }) {
                Text("Transfer")
                    .fontWeight(selectedTab == .transfer ? .semibold : .regular)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .background(selectedTab == .transfer ? Color(NSColor.controlAccentColor).opacity(0.15) : Color.clear)
                    .foregroundColor(selectedTab == .transfer ? Color(NSColor.controlAccentColor) : .secondary)
            }
            .buttonStyle(.plain)
            
            Button(action: { selectedTab = .logs }) {
                HStack(spacing: 6) {
                    Text("Technical Logs")
                    Text("\(viewModel.logs.count)")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
                .fontWeight(selectedTab == .logs ? .semibold : .regular)
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
        .padding(.bottom, 8)
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

    private var technicalLogsTabContent: some View {
        TerminalLogsView(
            logs: viewModel.logs,
            autoScroll: viewModel.transferState == .copying || viewModel.transferState == .verifying
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var rsyncBadgeBackgroundColor: Color {
        viewModel.bundledRsyncInfo.isAvailable ? Color.secondary.opacity(0.12) : Color.orange.opacity(0.16)
    }

    private var rsyncBadgeForegroundColor: Color {
        viewModel.bundledRsyncInfo.isAvailable ? Color.secondary : Color.orange
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
