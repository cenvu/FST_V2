// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct DestinationCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("Destination")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(FSTPalette.muted)
                .frame(width: 104, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                if let url = viewModel.destinationURL {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(url.lastPathComponent)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        if let destinationMetadata = viewModel.destinationMetadata {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                metadataValue(title: "FILESYSTEM", value: destinationMetadata.filesystem)
                                metadataValue(title: "FREE SPACE", value: formatBytes(destinationMetadata.freeSpaceBytes))
                                metadataValue(
                                    title: "WRITABLE",
                                    value: destinationMetadata.isWritable ? "YES" : "NO",
                                    isWarning: !destinationMetadata.isWritable
                                )
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    Text(url.path)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(FSTPalette.muted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help(url.path)
                        .accessibilityLabel("Destination path: \(url.path)")

                    if viewModel.destinationMetadata == nil {
                        let metadataUnavailable = viewModel.errorMessage == "Unable to analyze destination folder."
                        Text(metadataUnavailable ? "Destination metadata unavailable." : "Analyzing destination metadata…")
                            .font(.system(size: 12))
                            .foregroundStyle(metadataUnavailable ? Color.orange : Color.secondary)
                    }

                    if let destinationTargetPreview = viewModel.destinationTargetPreview {
                        Label(destinationTargetPreview, systemImage: "arrow.turn.down.right")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(FSTPalette.muted)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(destinationTargetPreview)
                            .accessibilityLabel("Destination target preview: \(destinationTargetPreview)")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select Destination")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("Drop folder here")
                            .font(.system(size: 13))
                            .foregroundStyle(FSTPalette.muted)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button {
                    guard !viewModel.isTransferConfigurationLocked else { return }
                    guard let url = FolderPicker.chooseFolder() else { return }
                    viewModel.selectDestinationFolder(url)
                } label: {
                    Text(viewModel.destinationURL == nil ? "Choose…" : "Change…")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityLabel("Choose Destination Folder")
                .disabled(viewModel.isTransferConfigurationLocked)
                .fixedSize()

                Button {
                    viewModel.clearDestinationFolder()
                } label: {
                    Image(systemName: viewModel.isTransferConfigurationLocked ? "lock.fill" : "xmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(viewModel.destinationURL == nil || viewModel.isTransferConfigurationLocked)
                .fixedSize()
                .accessibilityLabel("Clear Destination Folder")
                .help("Removes this destination selection from FST only. The folder or drive on disk is never deleted or modified.")

            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDropTargeted ? Color.accentColor : Color.clear, style: StrokeStyle(lineWidth: 2, dash: [5]))
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

    private func metadataValue(title: String, value: String, isWarning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(FSTPalette.muted)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(isWarning ? Color.orange : Color.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(value)
        }
    }
}
