import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = TransferViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // App Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FishSock Transfer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(viewModel.bundledRsyncInfo.badgeText)
                        .font(.system(.subheadline, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(rsyncBadgeBackgroundColor)
                        .cornerRadius(4)
                        .foregroundColor(rsyncBadgeForegroundColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("From CenVu with love")
                    Text("📱 (+84) 842 841 222")
                    Text("✉️ hunghv.hfs@gmail.com")
                        .foregroundColor(.blue)
                }
                .font(.caption)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .opacity(0.7)
            }
            
            // Core UI Sections
            HStack(spacing: 20) {
                SourceCardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
                DestinationCardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
            TransferControlsView(viewModel: viewModel)
                .frame(maxWidth: .infinity)
            
            TerminalLogsView(
                logs: viewModel.logs,
                autoScroll: viewModel.transferState == .copying || viewModel.transferState == .verifying
            )
            .frame(maxWidth: .infinity)
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

    private var rsyncBadgeBackgroundColor: Color {
        viewModel.bundledRsyncInfo.isAvailable ? Color.gray.opacity(0.3) : Color.yellow.opacity(0.25)
    }

    private var rsyncBadgeForegroundColor: Color {
        viewModel.bundledRsyncInfo.isAvailable ? Color.gray : Color.yellow.opacity(0.85)
    }
}
