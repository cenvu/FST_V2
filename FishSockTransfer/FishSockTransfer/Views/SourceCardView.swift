import SwiftUI

public struct SourceCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("SOURCE")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, minHeight: 70, maxHeight: 70, alignment: .center)
            
            VStack(spacing: 6) {
                if let url = viewModel.sourceURL {
                    Text(url.lastPathComponent)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(url.path)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let sourceMetadata = viewModel.sourceMetadata {
                        VStack(spacing: 4) {
                            metadataRow(title: "Folder Size", value: formatBytes(sourceMetadata.totalSizeBytes))
                            metadataRow(title: "File Count", value: formatCount(sourceMetadata.fileCount))
                            metadataRow(title: "Folder Count", value: formatCount(sourceMetadata.folderCount))
                        }
                        .padding(.top, 6)
                    } else {
                        Text("Analyzing source metadata...")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                } else {
                    Text("Select Source")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Drop folder here")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray)
                }

                if viewModel.isTransferConfigurationLocked {
                    Label("Selection locked during transfer", systemImage: "lock.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.blue.opacity(0.85))
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 142)

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
                    viewModel.isTransferConfigurationLocked ? viewModel.transferState.statusColor :
                        (isDropTargeted ? Color.blue : Color.blue.opacity(0.5)),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 2 : 1, dash: [5])
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
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .font(.system(.footnote, design: .monospaced))
        .frame(maxWidth: .infinity)
    }
}
