import SwiftUI

public struct DestinationCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "tray.and.arrow.down")
                Text("Destination")
                    .fontWeight(.semibold)
                Spacer()
                if viewModel.isTransferConfigurationLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .font(.headline)
            .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                if let url = viewModel.destinationURL {
                    Text(url.lastPathComponent)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(url.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let destinationMetadata = viewModel.destinationMetadata {
                        VStack(spacing: 4) {
                            metadataRow(title: "Filesystem", value: destinationMetadata.filesystem)
                            metadataRow(title: "Free Space", value: formatBytes(destinationMetadata.freeSpaceBytes))
                            metadataRow(title: "Writable Status", value: destinationMetadata.isWritable ? "YES" : "NO")
                        }
                        .padding(.top, 8)
                    } else {
                        Text("Analyzing destination metadata...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    if let destinationTargetPreview = viewModel.destinationTargetPreview {
                        Text(destinationTargetPreview)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.top, 4)
                    }
                } else {
                    Text("Select Destination")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Drop folder here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if viewModel.isTransferConfigurationLocked {
                    Label("Selection locked during transfer", systemImage: "lock.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .padding(14)
            .background(Color(NSColor.textBackgroundColor).opacity(0.35))
            .cornerRadius(8)

            Button {
                guard !viewModel.isTransferConfigurationLocked else { return }
                guard let url = FolderPicker.chooseFolder() else { return }
                viewModel.selectDestinationFolder(url)
            } label: {
                Label("Choose Folder", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isTransferConfigurationLocked)
            .opacity(viewModel.isTransferConfigurationLocked ? 0.55 : 1.0)
            .controlSize(.regular)
            
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 320, alignment: .top)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.58))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    viewModel.isTransferConfigurationLocked ? viewModel.transferState.statusColor :
                        (isDropTargeted ? Color.blue : Color.secondary.opacity(0.18)),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 2 : 1, dash: isDropTargeted ? [5] : [])
                )
        )
        .dropDestination(for: URL.self) { urls, _ in
            guard !viewModel.isTransferConfigurationLocked else { return false }
            guard let url = urls.first else { return false }
            return viewModel.selectDestinationFolder(url)
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted && !viewModel.isTransferConfigurationLocked
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .font(.system(.footnote, design: .rounded))
        .frame(maxWidth: .infinity)
    }
}
