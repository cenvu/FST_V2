// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct StorageAnalysisView: View {
    @Environment(\.locale) private var locale
    @ObservedObject var viewModel: TransferViewModel
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            readinessContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
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
                Text(TransferPresentationLocalization.text("Analyzing storage…", locale: locale))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        } else if let assessment = viewModel.currentCapacityAssessment,
                  let destinationMetadata = viewModel.destinationMetadata {
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.hasInsufficientDestinationSpace {
                    readinessStatus(
                        "INSUFFICIENT DESTINATION SPACE",
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .orange
                    )
                    if let storageWarningMessage = viewModel.storageWarningMessage {
                        Text(TransferPresentationLocalization.text(storageWarningMessage, locale: locale))
                            .font(.system(size: 12))
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
                    Text(TransferPresentationLocalization.text(assessment.supportingText, locale: locale))
                        .font(.system(size: 12))
                        .foregroundStyle(assessment.hasUnvalidatedAllocation ? Color.orange : Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .top, spacing: 16) {
                    valueRow("Payload", value: formatBytes(assessment.logicalPayloadBytes))
                    valueRow("Admission Floor", value: formatBytes(assessment.admissionFloorBytes))
                    valueRow("Available", value: formatBytes(assessment.availableSnapshotBytes))
                    if let margin = assessment.marginAboveFloorBytes {
                        valueRow("Margin Above Floor", value: formatBytes(margin))
                    }
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
        let localizedTitle = TransferPresentationLocalization.text(title, locale: locale)
        return HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(localizedTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .help(TransferPresentationLocalization.text(help ?? title, locale: locale))
    }

    private func valueRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(TransferPresentationLocalization.text(title, locale: locale))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .font(.system(size: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
