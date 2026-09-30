// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct DestinationCardView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isDropTargeted = false
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "tray.and.arrow.down")
                    .foregroundStyle(.secondary)
                Text("DESTINATION")
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
                if let url = viewModel.destinationURL {
                    Text(url.lastPathComponent)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(url.path)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help(url.path)
                        .accessibilityLabel("Destination path: \(url.path)")

                    if let destinationMetadata = viewModel.destinationMetadata {
                        HStack(alignment: .top, spacing: 20) {
                            metadataValue(title: "FILESYSTEM", value: destinationMetadata.filesystem)
                            metadataValue(title: "FREE SPACE", value: formatBytes(destinationMetadata.freeSpaceBytes))
                            metadataValue(
                                title: "WRITABLE",
                                value: destinationMetadata.isWritable ? "YES" : "NO",
                                isWarning: !destinationMetadata.isWritable
                            )
                            Spacer(minLength: 0)
                        }
                    } else {
                        let metadataUnavailable = viewModel.errorMessage == "Unable to analyze destination folder."
                        Text(metadataUnavailable ? "Destination metadata unavailable." : "Analyzing destination metadata…")
                            .font(.footnote)
                            .foregroundStyle(metadataUnavailable ? Color.orange : Color.secondary)
                    }

                    if let destinationTargetPreview = viewModel.destinationTargetPreview {
                        Label(destinationTargetPreview, systemImage: "arrow.turn.down.right")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(destinationTargetPreview)
                            .accessibilityLabel("Destination target preview: \(destinationTargetPreview)")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select Destination")
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
                    viewModel.selectDestinationFolder(url)
                } label: {
                    Label("Choose Folder", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.isTransferConfigurationLocked)
                .fixedSize()

                Button {
                    viewModel.clearDestinationFolder()
                } label: {
                    Label("Clear Folder", systemImage: "xmark.square")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.destinationURL == nil || viewModel.isTransferConfigurationLocked)
                .fixedSize()
                .accessibilityLabel("Clear Folder")
                .help("Removes this destination selection from FST only. The folder or drive on disk is never deleted or modified.")

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
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(isWarning ? Color.orange : Color.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(value)
        }
    }
}
