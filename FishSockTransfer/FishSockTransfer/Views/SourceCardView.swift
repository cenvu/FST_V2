// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct SourceCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("Source")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(FSTPalette.muted)
                .frame(width: 116, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                if let url = viewModel.sourceURL {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(viewModel.sourceMetadata?.folderName ?? url.lastPathComponent)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        if let sourceMetadata = viewModel.sourceMetadata {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                metadataValue(title: "TOTAL SIZE", value: formatBytes(sourceMetadata.totalSizeBytes))
                                metadataValue(title: "FILES", value: formatCount(sourceMetadata.fileCount))
                                metadataValue(title: "FOLDERS", value: formatCount(sourceMetadata.folderCount))
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    let fullPath = viewModel.sourceMetadata?.fullPath ?? url.path
                    Text(fullPath)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(FSTPalette.muted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help(fullPath)
                        .accessibilityLabel("Source path: \(fullPath)")

                    if viewModel.sourceMetadata == nil {
                        let metadataUnavailable = viewModel.errorMessage == "Unable to analyze source folder."
                        Text(metadataUnavailable ? "Source metadata unavailable." : "Analyzing source metadata…")
                            .font(.system(size: 14))
                            .foregroundStyle(metadataUnavailable ? Color.orange : Color.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Select Source")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Drop folder here")
                            .font(.system(size: 15))
                            .foregroundStyle(FSTPalette.muted)
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
                    Text(viewModel.sourceURL == nil ? "Choose…" : "Change…")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityLabel("Choose Source Folder")
                .disabled(viewModel.isTransferConfigurationLocked)
                .fixedSize()

                Button {
                    viewModel.clearSourceFolder()
                } label: {
                    Image(systemName: viewModel.isTransferConfigurationLocked ? "lock.fill" : "xmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(viewModel.sourceURL == nil || viewModel.isTransferConfigurationLocked)
                .fixedSize()
                .accessibilityLabel("Clear Source Folder")
                .help("Removes this source selection from FST only. The folder on disk is never deleted or modified.")

            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDropTargeted ? Color.accentColor : Color.clear, style: StrokeStyle(lineWidth: 2, dash: [5]))
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
                .font(.system(size: 14))
                .foregroundStyle(FSTPalette.muted)
            Text(value)
                .font(.system(size: 14, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}
