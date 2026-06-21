import SwiftUI

public struct DestinationCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("DESTINATION")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, minHeight: 70, maxHeight: 70, alignment: .center)
            
            VStack(spacing: 6) {
                if let url = viewModel.destinationURL {
                    Text(url.lastPathComponent)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(url.path)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let destinationMetadata = viewModel.destinationMetadata {
                        VStack(spacing: 4) {
                            metadataRow(title: "Filesystem", value: destinationMetadata.filesystem)
                            metadataRow(title: "Free Space", value: formatBytes(destinationMetadata.freeSpaceBytes))
                            metadataRow(title: "Writable Status", value: destinationMetadata.isWritable ? "YES" : "NO")
                        }
                        .padding(.top, 6)
                    } else {
                        Text("Analyzing destination metadata...")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                } else {
                    Text("Select Destination")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Drop folder here")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 142)

            Button {
                guard let url = FolderPicker.chooseFolder() else { return }
                viewModel.selectDestinationFolder(url)
            } label: {
                Label("Choose Folder", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .frame(width: 160)
            
            Spacer()
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 360, maxHeight: 360, alignment: .top)
        .background(Color.black.opacity(0.10))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isDropTargeted ? Color.green :
                        (viewModel.transferState == .copying ? viewModel.transferState.statusColor : Color.green.opacity(0.5)),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 2 : 1, dash: [5])
                )
        )
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            return viewModel.selectDestinationFolder(url)
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .font(.system(.footnote, design: .monospaced))
        .frame(maxWidth: .infinity)
    }
}
