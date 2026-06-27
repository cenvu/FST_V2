import SwiftUI

public struct ContentView: View {
    private static let defaultCollapsedForOperatorMode = true

    @StateObject private var viewModel = TransferViewModel()
    @State private var isShowingTechnicalLogs: Bool
    
    public init() {
        _isShowingTechnicalLogs = State(initialValue: !Self.defaultCollapsedForOperatorMode)
    }
    
    public var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FishSock Transfer")
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Beta DIT workflow tool")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(rsyncHeaderBadgeText)
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(rsyncBadgeBackgroundColor)
                    .clipShape(Capsule())
                    .foregroundColor(rsyncBadgeForegroundColor)
            }
            
            HStack(spacing: 20) {
                SourceCardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
                DestinationCardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
            TransferControlsView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
            
            technicalLogsDisclosure

            Spacer(minLength: 0)

            VStack(spacing: 2) {
                Text("FishSock Transfer by CenVu")
                Text("DIT Workflow Tool • hungvh.hfs@gmail.com")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .opacity(0.74)
            .padding(.top, 2)
        }
        .padding(24)
        .frame(
            minWidth: 1000,
            idealWidth: 1120,
            maxWidth: .infinity,
            minHeight: 900,
            idealHeight: 940,
            maxHeight: .infinity
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
