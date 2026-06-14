import SwiftUI

public struct ContentView: View {
    @StateObject private var viewModel = TransferViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // App Header
            HStack(alignment: .lastTextBaseline) {
                Text("FishSock Transfer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("/usr/bin/rsync v3.1.2")
                    .font(.system(.subheadline, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(4)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Status Badge Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.transferState.statusColor)
                        .frame(width: 8, height: 8)
                    Text("\(viewModel.transferState.rawValue.uppercased()) STATUS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.transferState.statusColor)
                }
            }
            
            Text("Professional high-speed media copy engine wrapper.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Core UI Sections
            HStack(spacing: 20) {
                SourceCardView(viewModel: viewModel)
                DestinationCardView(viewModel: viewModel)
            }
            
            StorageAnalysisView(viewModel: viewModel)
            
            TransferControlsView(viewModel: viewModel)
            
            TerminalLogsView(logs: viewModel.logs)
        }
        .padding(24)
        .frame(minWidth: 1000, minHeight: 750)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
