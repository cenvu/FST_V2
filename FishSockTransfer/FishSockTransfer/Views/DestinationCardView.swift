import SwiftUI

public struct DestinationCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        let hasAnyFolder = viewModel.sourceURL != nil || viewModel.destinationURL != nil
        let innerPanelHeight: CGFloat = hasAnyFolder ? 148 : 100
        let outerCardHeight: CGFloat = hasAnyFolder ? 236 : 188

        return VStack(alignment: .leading, spacing: 0) {
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
            .frame(height: 24)
            
            Color.clear.frame(height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                if let url = viewModel.destinationURL {
                    Text(url.lastPathComponent)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(url.path)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .help(url.path)

                    if let destinationMetadata = viewModel.destinationMetadata {
                        VStack(spacing: 2) {
                            metadataRow(title: "Filesystem", value: destinationMetadata.filesystem)
                            metadataRow(title: "Free Space", value: formatBytes(destinationMetadata.freeSpaceBytes))
                            metadataRow(title: "Writable Status", value: destinationMetadata.isWritable ? "YES" : "NO")
                        }
                        .padding(.top, 4)
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select Destination")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Drop folder here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.isTransferConfigurationLocked {
                    Label("Selection locked during transfer", systemImage: "lock.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: innerPanelHeight, alignment: .topLeading)
            .padding(10)
            .background(Color.black.opacity(0.16))
            .cornerRadius(8)

            Color.clear.frame(height: 8)

            HStack {
                Button {
                    guard !viewModel.isTransferConfigurationLocked else { return }
                    guard let url = FolderPicker.chooseFolder() else { return }
                    viewModel.selectDestinationFolder(url)
                } label: {
                    Label("Choose Folder", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isTransferConfigurationLocked)
                .opacity(viewModel.isTransferConfigurationLocked ? 0.25 : 1.0)
                .controlSize(.regular)
                .fixedSize()
                Spacer(minLength: 0).frame(width: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: outerCardHeight)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.58))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isDropTargeted ? Color.blue.opacity(0.50) : Color.secondary.opacity(viewModel.isTransferConfigurationLocked ? 0.28 : 0.16),
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
            Spacer(minLength: 8)
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .font(.system(.footnote, design: .rounded))
        .frame(maxWidth: .infinity)
    }
}
