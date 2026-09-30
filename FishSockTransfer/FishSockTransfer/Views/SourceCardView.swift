// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct SourceCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive")
                    .foregroundStyle(.secondary)
                Text("SOURCE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.isTransferConfigurationLocked {
                    Label("Selection locked during transfer", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                if let url = viewModel.sourceURL {
                    Text(viewModel.sourceMetadata?.folderName ?? url.lastPathComponent)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    let fullPath = viewModel.sourceMetadata?.fullPath ?? url.path
                    Text(fullPath)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help(fullPath)
                        .accessibilityLabel("Source path: \(fullPath)")

                    if let sourceMetadata = viewModel.sourceMetadata {
                        HStack(alignment: .top, spacing: 20) {
                            metadataValue(title: "TOTAL SIZE", value: formatBytes(sourceMetadata.totalSizeBytes))
                            metadataValue(title: "FILES", value: formatCount(sourceMetadata.fileCount))
                            metadataValue(title: "FOLDERS", value: formatCount(sourceMetadata.folderCount))
                            Spacer(minLength: 0)
                        }
                    } else {
                        let metadataUnavailable = viewModel.errorMessage == "Unable to analyze source folder."
                        Text(metadataUnavailable ? "Source metadata unavailable." : "Analyzing source metadata…")
                            .font(.footnote)
                            .foregroundStyle(metadataUnavailable ? Color.orange : Color.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select Source")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Drop folder here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button {
                    guard !viewModel.isTransferConfigurationLocked else { return }
                    guard let url = FolderPicker.chooseFolder() else { return }
                    viewModel.selectSourceFolder(url)
                } label: {
                    Label("Choose Folder", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.isTransferConfigurationLocked)
                .fixedSize()

                Button {
                    viewModel.clearSourceFolder()
                } label: {
                    Label("Clear Folder", systemImage: "xmark.square")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.sourceURL == nil || viewModel.isTransferConfigurationLocked)
                .fixedSize()
                .accessibilityLabel("Clear Folder")
                .help("Removes this source selection from FST only. The folder on disk is never deleted or modified.")

                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isDropTargeted ? Color.accentColor.opacity(0.50) : Color.secondary.opacity(viewModel.isTransferConfigurationLocked ? 0.28 : 0.16),
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

    private func metadataValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}
