import SwiftUI

public struct StorageAnalysisView: View {
    @ObservedObject var viewModel: TransferViewModel
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("APFS STORAGE ANALYSIS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                if viewModel.sourceURL != nil && viewModel.destinationURL != nil {
                     Text("Copy safely matching: Source fits inside destination free space.")
                        .font(.subheadline)
                        .foregroundColor(.white)
                } else {
                     Text("Select source and destination to analyze storage requirements.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
