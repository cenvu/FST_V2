import SwiftUI

public struct SourceCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.down")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text("SOURCE CARDS")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            if let url = viewModel.sourceURL {
                Text(url.lastPathComponent)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(url.path)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("Select Source")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Drop folder here")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                Text("Media Volume:")
                    .foregroundColor(.gray)
                Spacer()
                Text("--- GB") // Computed from DriveService in a real implementation
                    .foregroundColor(.white)
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
                    viewModel.transferState == .copying ? viewModel.transferState.statusColor : Color.blue.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, dash: [5])
                )
        )
    }
}
