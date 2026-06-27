import SwiftUI

public struct SourceCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive")
                Text("Source")
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
            
            VStack(alignment: .leading, spacing: 10) {
                if let url = viewModel.sourceURL {
                    Text(url.lastPathComponent)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(url.path)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let sourceMetadata = viewModel.sourceMetadata {
                        VStack(spacing: 4) {
                            metadataRow(title: "Folder Size", value: formatBytes(sourceMetadata.totalSizeBytes))
                            metadataRow(title: "File Count", value: formatCount(sourceMetadata.fileCount))
                            metadataRow(title: "Folder Count", value: formatCount(sourceMetadata.folderCount))
                        }
                        .padding(.top, 8)
                    } else {
                        Text("Analyzing source metadata...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                } else {
                    Text("Select Source")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
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
            .background(Color.black.opacity(0.16))
            .cornerRadius(8)

            Divider()
                .opacity(0.45)

            Button {
                guard !viewModel.isTransferConfigurationLocked else { return }
                guard let url = FolderPicker.chooseFolder() else { return }
                viewModel.selectSourceFolder(url)
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
        .frame(maxWidth: .infinity, minHeight: 330, maxHeight: 330, alignment: .top)
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
            return viewModel.selectSourceFolder(url)
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted && !viewModel.isTransferConfigurationLocked
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func formatCount(_ count: Int) -> String {
        count.formatted(.number)
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .font(.system(.footnote, design: .rounded))
        .frame(maxWidth: .infinity)
    }
}
