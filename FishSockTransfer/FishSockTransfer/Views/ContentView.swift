import SwiftUI

public struct ContentView: View {
    private static let defaultCollapsedForOperatorMode = true

    @StateObject private var viewModel = TransferViewModel()
    @State private var isShowingTechnicalLogs: Bool
    
    public init() {
        _isShowingTechnicalLogs = State(initialValue: !Self.defaultCollapsedForOperatorMode)
    }
    
    public var body: some View {
        VStack(spacing: 12) {
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
            
            HStack(alignment: .top, spacing: 16) {
                SourceCardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
                DestinationCardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
            .layoutPriority(1)
            
            TransferControlsView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            
            technicalLogsDisclosure
        }
        .padding(16)
        .frame(
            minWidth: 900,
            idealWidth: 1120,
            maxWidth: .infinity,
            minHeight: 600,
            alignment: .top
        )
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var technicalLogsDisclosure: some View {
        DisclosureGroup(isExpanded: $isShowingTechnicalLogs) {
            TerminalLogsView(
                logs: viewModel.logs,
                autoScroll: viewModel.transferState == .copying || viewModel.transferState == .verifying
            )
            .padding(.top, 10)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                Text("Technical Logs")
                    .fontWeight(.semibold)
                Text("\(viewModel.logs.count)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
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
