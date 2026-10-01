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
                Text("CAPACITY PRECHECK")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            readinessContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        } else if viewModel.sourceMetadata == nil || viewModel.destinationMetadata == nil || viewModel.currentCapacityAssessment == nil {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Analyzing storage…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if let assessment = viewModel.currentCapacityAssessment,
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
                        DestinationCapacityAssessment.passedStatus,
                        systemImage: assessment.hasUnvalidatedAllocation ? "exclamationmark.triangle.fill" : "info.circle",
                        tint: assessment.hasUnvalidatedAllocation ? .orange : .secondary,
                        help: "Capacity is a snapshot, not a reservation. Transfer preflight remains authoritative."
                    )
                }

                if assessment.passesCapacityPrecheck {
                    Text(assessment.supportingText)
                        .font(.footnote)
                        .foregroundStyle(assessment.hasUnvalidatedAllocation ? Color.orange : Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                valueRow("Payload", value: formatBytes(assessment.logicalPayloadBytes))
                valueRow("Admission Floor", value: formatBytes(assessment.admissionFloorBytes))
                valueRow("Available", value: formatBytes(assessment.availableSnapshotBytes))

                if let margin = assessment.marginAboveFloorBytes {
                    valueRow("Margin Above Floor", value: formatBytes(margin))
                }
            }
        }
    }

    private var metadataErrorMessage: String? {
        if let error = viewModel.capacityAssessmentError { return error }
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
