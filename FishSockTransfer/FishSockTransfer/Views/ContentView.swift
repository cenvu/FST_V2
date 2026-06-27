import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = TransferViewModel()
    @State private var isShowingTechnicalLogs = false
    
    public init() {}
    
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

                Text("Bundled rsync 3.4.4")
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
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
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
}
