import SwiftUI

public struct TransferControlsView: View {
    @ObservedObject var viewModel: TransferViewModel
    
    // Limits represented in KiB/s for rsync 3.x --bwlimit semantics.
    private let bandwidthOptions: [(label: String, value: Int?)] = [
        ("50 MB/s", RsyncBandwidthLimit.kibPerSecond(for: 50)),
        ("120 MB/s", RsyncBandwidthLimit.kibPerSecond(for: 120)),
        ("240 MB/s", RsyncBandwidthLimit.kibPerSecond(for: 240)),
        ("Unlimited", nil)
    ]
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                settingsPanel
                    .frame(maxWidth: .infinity, alignment: .leading)

                actionStatusButton
                    .frame(width: 320)
            }
            .frame(maxWidth: .infinity)

            if let storageWarningMessage = viewModel.storageWarningMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(storageWarningMessage)
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let startBlockedReason = viewModel.startBlockedReason {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isTransferConfigurationLocked ? "lock.fill" : "info.circle.fill")
                    Text(startBlockedReason)
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if viewModel.transferState == .cancelled {
                HStack(spacing: 8) {
                    Image(systemName: TransferControlsActionPresentation.icon(for: .cancelled))
                    Text(TransferControlsActionPresentation.title(for: .cancelled))
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(TransferControlsActionPresentation.buttonColor(for: .cancelled))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let reportStatusMessage = viewModel.reportStatusMessage {
                HStack(spacing: 8) {
                    Image(systemName: reportStatusMessage.hasPrefix("Report saved: ") ? "doc.text.fill" : "exclamationmark.triangle.fill")
                    Text(reportStatusMessage)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(reportStatusMessage.hasPrefix("Report saved: ") ? Color.secondary : Color.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Transfer Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .bold()
                    Spacer()
                    Text("\(Int(displayProgress.rounded()))%")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(viewModel.transferState.statusColor)
                        .bold()
                }

                ProgressView(value: displayProgress, total: 100)
                    .progressViewStyle(.linear)

                HStack(spacing: 20) {
                    runtimeMetric(title: "CURRENT FILE", value: displayCurrentFile)
                    runtimeMetric(title: "SPEED", value: formatSpeed(viewModel.speed))
                    runtimeMetric(title: "ETA", value: formatETA(viewModel.eta))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.textBackgroundColor).opacity(0.30))
            .cornerRadius(8)
            
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transfer Settings")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bandwidth Limit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)

                    Picker("", selection: $viewModel.bandwidthLimit) {
                        ForEach(bandwidthOptions, id: \.label) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 170, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Verification Mode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)

                    Picker("", selection: $viewModel.verificationMode) {
                        Text("None").tag(VerificationMode.none)
                        Text("Random 33%").tag(VerificationMode.random33)
                        Text("Full 100%").tag(VerificationMode.full)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 170, alignment: .leading)

                    Text(viewModel.verificationMode.operatorDescription)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .disabled(viewModel.isTransferConfigurationLocked)
        .opacity(viewModel.isTransferConfigurationLocked ? 0.62 : 1)
        .padding(14)
        .background(Color(NSColor.textBackgroundColor).opacity(0.30))
        .cornerRadius(8)
    }

    private var actionStatusButton: some View {
        let statusColor = TransferControlsActionPresentation.buttonColor(
            for: viewModel.transferState,
            errorMessage: viewModel.errorMessage
        )

        return Button(action: handleActionButton) {
            HStack(spacing: 12) {
                Image(systemName: TransferControlsActionPresentation.icon(
                    for: viewModel.transferState,
                    errorMessage: viewModel.errorMessage
                ))
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(statusColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Status")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(TransferControlsActionPresentation.title(
                        for: viewModel.transferState,
                        errorMessage: viewModel.errorMessage,
                        canStartTransfer: viewModel.canStartTransfer
                    ))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .background(statusColor.opacity(isActionButtonEnabled ? 0.14 : 0.07))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(statusColor.opacity(isActionButtonEnabled ? 0.45 : 0.20), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isActionButtonEnabled)
        .opacity(isActionButtonEnabled ? 1 : 0.68)
    }

    private var displayProgress: Double {
        let rawProgress: Double
        if viewModel.transferState == .verifying {
            rawProgress = viewModel.progress <= 1 ? viewModel.progress * 100 : viewModel.progress
        } else {
            rawProgress = viewModel.progress
        }

        return min(max(rawProgress, 0), 100)
    }

    private var displayCurrentFile: String {
        viewModel.currentFile.isEmpty ? "-" : viewModel.currentFile
    }

    private func runtimeMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .bold()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatSpeed(_ speed: Double) -> String {
        guard speed > 0 else { return "-" }
        return String(format: "%.2f MB/s", speed)
    }

    private func formatETA(_ eta: TimeInterval) -> String {
        guard eta > 0 else { return "-" }
        let totalSeconds = Int(eta.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var isActionButtonEnabled: Bool {
        switch viewModel.transferState {
        case .copying, .verifying:
            return true
        case .validating:
            return false
        case .ready, .error, .cancelled, .copyComplete, .safeToFormat:
            return viewModel.canStartTransfer
        }
    }

    private func handleActionButton() {
        if viewModel.transferState == .copying || viewModel.transferState == .verifying {
            viewModel.cancelTransfer()
        } else {
            viewModel.startTransfer()
        }
    }
}

public extension VerificationMode {
    var operatorDescription: String {
        switch self {
        case .none:
            return "Copy only. No hash verification by FST."
        case .random33:
            return "Sample verification. Faster, not full coverage."
        case .full:
            return "Full hash verification. Safest, slower."
        }
    }
}

nonisolated public enum TransferControlsVisualRole: Equatable, Sendable {
    case idle
    case transferring
    case verifying
    case copyOnlyComplete
    case safeToFormat
    case manualCheckRequired
    case error
    case cancelled
}

nonisolated public enum TransferControlsActionPresentation {
    public static func visualRole(for state: TransferState) -> TransferControlsVisualRole {
        visualRole(for: state, errorMessage: nil)
    }

    public static func visualRole(for state: TransferState, errorMessage: String?) -> TransferControlsVisualRole {
        switch state {
        case .ready:
            return .idle
        case .copying, .validating:
            return .transferring
        case .verifying:
            return .verifying
        case .copyComplete:
            return .copyOnlyComplete
        case .safeToFormat:
            return .safeToFormat
        case .error:
            return isManualCheckRequired(errorMessage: errorMessage) ? .manualCheckRequired : .error
        case .cancelled:
            return .cancelled
        }
    }

    public static func title(for state: TransferState, errorMessage: String? = nil) -> String {
        title(for: state, errorMessage: errorMessage, canStartTransfer: false)
    }

    public static func title(
        for state: TransferState,
        errorMessage: String? = nil,
        canStartTransfer: Bool
    ) -> String {
        if state == .cancelled, canStartTransfer {
            return "START NEW TRANSFER"
        }

        switch visualRole(for: state, errorMessage: errorMessage) {
        case .transferring:
            return "TRANSFERRING"
        case .verifying:
            return "VERIFYING"
        case .copyOnlyComplete:
            return "TRANSFER COMPLETE"
        case .safeToFormat:
            return "SAFE TO EJECT"
        case .manualCheckRequired:
            return "MANUAL CHECK REQUIRED"
        case .error:
            return "TRANSFER ERROR"
        case .cancelled:
            return "CANCELLED"
        case .idle:
            return "START"
        }
    }

    public static func icon(for state: TransferState, errorMessage: String? = nil) -> String {
        switch visualRole(for: state, errorMessage: errorMessage) {
        case .transferring, .verifying:
            return "arrow.triangle.2.circlepath"
        case .copyOnlyComplete:
            return "doc.on.doc"
        case .safeToFormat:
            return "checkmark.circle.fill"
        case .manualCheckRequired:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        case .cancelled:
            return "xmark.circle.fill"
        case .idle:
            return "play.fill"
        }
    }

    public static func buttonColor(for state: TransferState, errorMessage: String? = nil) -> Color {
        switch visualRole(for: state, errorMessage: errorMessage) {
        case .transferring:
            return Color(red: 0.78, green: 0.60, blue: 0.36)
        case .verifying:
            return Color(red: 0.82, green: 0.52, blue: 0.34)
        case .copyOnlyComplete:
            return Color(red: 0.42, green: 0.60, blue: 0.78)
        case .safeToFormat:
            return Color(red: 0.43, green: 0.65, blue: 0.48)
        case .manualCheckRequired:
            return Color(red: 0.86, green: 0.60, blue: 0.28)
        case .error:
            return Color(red: 0.70, green: 0.38, blue: 0.36)
        case .cancelled:
            return Color(red: 0.50, green: 0.50, blue: 0.50)
        case .idle:
            return Color(red: 0.42, green: 0.60, blue: 0.78)
        }
    }

    public static func isManualCheckRequired(errorMessage: String?) -> Bool {
        guard let errorMessage else { return false }
        return errorMessage.localizedCaseInsensitiveContains("MANUAL CHECK REQUIRED")
    }
}
