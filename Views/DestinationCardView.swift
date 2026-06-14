import SwiftUI

public struct DestinationCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive")
                .font(.system(size: 32))
                .foregroundColor(.green)
            
            Text("DESTINATION DRIVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            if let url = viewModel.destinationURL {
                Text(url.lastPathComponent)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(url.path)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("Select Destination")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Drop folder here")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                Text("Available Space:")
                    .foregroundColor(.gray)
                Spacer()
                Text("--- TB") // Computed from DriveService in a real implementation
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            }
            .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    viewModel.transferState == .copying ? viewModel.transferState.statusColor : Color.green.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, dash: [5])
                )
        )
    }
}
