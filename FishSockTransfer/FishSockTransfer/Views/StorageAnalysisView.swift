// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct StorageAnalysisView: View {
    @ObservedObject var viewModel: TransferViewModel
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "externaldrive")
                    .foregroundStyle(.secondary)
                Text("STORAGE READINESS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            readinessContent
        }
        .standardPanel()
    }

    @ViewBuilder
    private var readinessContent: some View {
        if viewModel.sourceURL == nil || viewModel.destinationURL == nil {
            readinessStatus(
                "Select source and destination.",
                systemImage: "info.circle",
                tint: .secondary
            )
        } else if let metadataErrorMessage {
            readinessStatus(
                metadataErrorMessage,
                systemImage: "exclamationmark.triangle.fill",
                tint: .orange
            )
        } else if viewModel.sourceMetadata == nil || viewModel.destinationMetadata == nil {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Analyzing storage…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if let sourceMetadata = viewModel.sourceMetadata,
                  let destinationMetadata = viewModel.destinationMetadata {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.hasInsufficientDestinationSpace {
                    readinessStatus(
                        "INSUFFICIENT DESTINATION SPACE",
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .orange
                    )
                    if let storageWarningMessage = viewModel.storageWarningMessage {
                        Text(storageWarningMessage)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !destinationMetadata.isWritable {
                    readinessStatus(
                        "DESTINATION NOT WRITABLE",
                        systemImage: "lock.fill",
                        tint: .orange
                    )
                }

                if !viewModel.hasInsufficientDestinationSpace && destinationMetadata.isWritable {
                    readinessStatus(
                        "STORAGE READY",
                        systemImage: "checkmark.circle.fill",
                        tint: .green,
                        help: "Based on current storage metadata. Transfer preflight remains authoritative."
                    )
                }

                valueRow("Required", value: formatBytes(sourceMetadata.totalSizeBytes))
                valueRow("Available", value: formatBytes(destinationMetadata.freeSpaceBytes))

                if let remaining = remainingAfterCopyBytes {
                    valueRow("Remaining After Copy", value: formatBytes(remaining))
                }
            }
        }
    }

    private var metadataErrorMessage: String? {
        if viewModel.sourceMetadata == nil,
           viewModel.errorMessage == "Unable to analyze source folder." {
            return "Unable to analyze source metadata."
        }
        if viewModel.destinationMetadata == nil,
           viewModel.errorMessage == "Unable to analyze destination folder." {
            return "Unable to analyze destination metadata."
        }
        return nil
    }

    private var remainingAfterCopyBytes: Int64? {
        guard let sourceMetadata = viewModel.sourceMetadata,
              let destinationMetadata = viewModel.destinationMetadata,
              destinationMetadata.freeSpaceBytes >= sourceMetadata.totalSizeBytes else {
            return nil
        }
        return destinationMetadata.freeSpaceBytes - sourceMetadata.totalSizeBytes
    }

    private func readinessStatus(
        _ title: String,
        systemImage: String,
        tint: Color,
        help: String? = nil
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
        .help(help ?? title)
    }

    private func valueRow(_ title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
