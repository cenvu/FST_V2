import SwiftUI

public struct TransferControlsView: View {
    @ObservedObject var viewModel: TransferViewModel
    @State private var isActionHovered = false
    
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
        VStack(spacing: 12) {
            settingsPanel

            actionStatusButton

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

            progressPanel
        }
    }

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(TransferRuntimeMetricPresentation.progressTitle(for: viewModel.transferState))
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(displayProgress.rounded()))%")
                    .font(.system(.title3, design: .monospaced, weight: .semibold))
                    .foregroundColor(viewModel.transferState == .verifying ? .orange : (viewModel.transferState == .copying ? .blue : viewModel.transferState.statusColor))
            }

            ProgressView(value: displayProgress, total: 100)
                .progressViewStyle(.linear)

            if shouldShowProgressDetails {
                if !viewModel.workflowPhaseTitle.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                        Text(viewModel.workflowPhaseTitle)
                            .fontWeight(.semibold)
                        Text(viewModel.workflowPhaseMessage)
                        Spacer(minLength: 0)
                        Text("Elapsed: \(formatElapsed(viewModel.workflowElapsedSeconds))")
                            .font(.system(.footnote, design: .monospaced))
                    }
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.secondary)
                }

                VStack(spacing: 12) {
                    if viewModel.transferState == .copying {
                        copyRuntimeMetrics
                    } else if viewModel.transferState == .verifying {
                        verifyRuntimeMetrics
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }

    private var settingsPanel: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("Transfer Settings")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
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
                .frame(maxWidth: 220, alignment: .leading)

                Text("Copy speed cap")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.6)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Verification Mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)

                Picker("", selection: $viewModel.verificationMode) {
                    Text(VerificationMode.none.operatorLabel).tag(VerificationMode.none)
                    Text(VerificationMode.random33.operatorLabel).tag(VerificationMode.random33)
                    Text(VerificationMode.full.operatorLabel).tag(VerificationMode.full)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 220, alignment: .leading)

                Text(viewModel.verificationMode.operatorDescription)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.secondary)
                    .opacity(0.6)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(viewModel.isTransferConfigurationLocked)
        .opacity(viewModel.isTransferConfigurationLocked ? 0.70 : 1)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }

    private var actionStatusButton: some View {
        let statusColor = TransferControlsActionPresentation.buttonColor(
            for: viewModel.transferState,
            errorMessage: viewModel.errorMessage
        )

        let isStart = isStartAction
        let iconSize: CGFloat = isStart ? 28 : 22
        let iconFrame: CGFloat = isStart ? 42 : 34
        
        let strokeOpacity = isStart ? (isActionHovered ? 0.8 : 0.45) : (isActionButtonEnabled ? 0.20 : 0.10)
        let bgOpacity = isStart ? (isActionHovered ? 0.20 : 0.14) : (isActionButtonEnabled ? 0.07 : 0.04)

        return Button(action: handleActionButton) {
            HStack(spacing: 12) {
                Image(systemName: TransferControlsActionPresentation.icon(
                    for: viewModel.transferState,
                    errorMessage: viewModel.errorMessage
                ))
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(statusColor)
                .frame(width: iconFrame, height: iconFrame)
                .background(statusColor.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(TransferControlsActionPresentation.title(
                        for: viewModel.transferState,
                        errorMessage: viewModel.errorMessage,
                        canStartTransfer: viewModel.canStartTransfer
                    ))
                        .font(.system(size: isStart ? 19 : 17, weight: isStart ? .heavy : .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                    Text(TransferControlsActionPresentation.subtitle(
                        for: viewModel.transferState,
                        errorMessage: viewModel.errorMessage,
                        canStartTransfer: viewModel.canStartTransfer
                    ))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(statusColor.opacity(bgOpacity))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(statusColor.opacity(strokeOpacity), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isActionButtonEnabled)
        .opacity(isActionButtonEnabled ? 1 : 0.68)
        .onHover { hovering in
            isActionHovered = hovering
        }
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
        TransferRuntimeMetricPresentation.currentFileValue(
            currentFile: viewModel.currentFile,
            state: viewModel.transferState
        )
    }

    private var runtimeFileMetricTitle: String {
        TransferRuntimeMetricPresentation.currentFileTitle(
            currentFile: viewModel.currentFile,
            state: viewModel.transferState
        )
    }

    private var copyRuntimeMetrics: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                runtimeMetric(title: "COPY ELAPSED", value: formatElapsed(copyElapsedSeconds))
                runtimeMetric(title: "ETA", value: copyEtaValue)
                runtimeMetric(title: "CURRENT SPEED", value: currentSpeedValue)
                runtimeMetric(title: "COPIED", value: copiedBytesValue)
            }

            GridRow {
                runtimeMetric(title: runtimeFileMetricTitle, value: displayCurrentFile)
                    .gridCellColumns(3)
                runtimeMetric(title: "FILES", value: copiedFilesValue)
            }
        }
    }

    private var verifyRuntimeMetrics: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
                Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
            }
            GridRow {
                runtimeMetric(title: runtimeFileMetricTitle, value: displayCurrentFile)
                    .gridCellColumns(3)
                runtimeMetric(title: "ETA", value: "Estimating...")
            }
        }
    }

    private func runtimeMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .bold()
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.34))
        .cornerRadius(7)
    }

    private func formatSpeed(_ speed: Double) -> String {
        guard speed > 0 else { return "-" }
        return String(format: "%.2f MB/s", speed)
    }

    private func formatTransferTime(_ time: TimeInterval) -> String {
        TransferRuntimeMetricPresentation.timeValue(seconds: time)
    }

    private func formatElapsed(_ elapsedSeconds: Int) -> String {
        formatDuration(max(0, elapsedSeconds))
    }

    private var copyElapsedSeconds: Int {
        viewModel.copyRuntimeSnapshot?.elapsedSeconds ?? viewModel.copyElapsedSeconds
    }

    private var copiedBytesValue: String {
        guard let snapshot = viewModel.copyRuntimeSnapshot else { return "-" }
        return TransferRuntimeMetricPresentation.copiedBytesValue(
            copiedBytes: snapshot.copiedBytes,
            totalBytes: snapshot.totalBytes
        )
    }

    private var copiedFilesValue: String {
        guard let snapshot = viewModel.copyRuntimeSnapshot else { return "-" }
        return TransferRuntimeMetricPresentation.copiedFilesValue(
            copiedFiles: snapshot.copiedFiles,
            totalFiles: snapshot.totalFiles
        )
    }

    private var copyEtaValue: String {
        if let etaSeconds = viewModel.copyRuntimeSnapshot?.etaSeconds {
            return "\(formatTransferTime(etaSeconds)) remaining"
        }

        return formatTransferTime(viewModel.eta)
    }

    private var currentSpeedValue: String {
        if let snapshot = viewModel.copyRuntimeSnapshot,
           let currentSpeed = snapshot.currentSpeedBytesPerSecond {
            return TransferRuntimeMetricPresentation.speedValue(bytesPerSecond: currentSpeed)
        }

        return formatSpeed(viewModel.speed)
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
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

    private var isStartAction: Bool {
        isActionButtonEnabled && viewModel.transferState != .copying && viewModel.transferState != .verifying && viewModel.transferState != .validating
    }

    private var shouldShowProgressDetails: Bool {
        return viewModel.transferState == .validating ||
               viewModel.transferState == .copying ||
               viewModel.transferState == .verifying
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
            return "SHA256 sample verification. 33% coverage."
        case .full:
            return "xxHash64 full verification. Fast, non-cryptographic."
        }
    }
}

nonisolated public enum TransferControlsVisualRole: Equatable, Sendable {
    case idle
    case preparing
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
        case .validating:
            return .preparing
        case .copying:
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
        case .preparing:
            return "PREPARING TRANSFER"
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
        case .preparing:
            return "magnifyingglass"
        case .transferring:
            return "arrow.right.circle.fill"
        case .verifying:
            return "checkmark.shield.fill"
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

    public static func subtitle(
        for state: TransferState,
        errorMessage: String? = nil,
        canStartTransfer: Bool = false
    ) -> String {
        if state == .cancelled, canStartTransfer {
            return "Click to begin copy."
        }

        switch visualRole(for: state, errorMessage: errorMessage) {
        case .preparing:
            return "Scanning source and checking destination..."
        case .transferring:
            return "Copy in progress. Do not remove media."
        case .verifying:
            return "Comparing source and destination hashes."
        case .copyOnlyComplete:
            return "Copy completed. Verification was disabled."
        case .safeToFormat:
            return "Verification completed successfully."
        case .manualCheckRequired:
            return errorMessage ?? "Verification did not pass. Review before using media."
        case .error:
            return errorMessage ?? "Review the error before retrying."
        case .cancelled:
            return "Transfer was cancelled."
        case .idle:
            return "Click to begin copy."
        }
    }

    public static func buttonColor(for state: TransferState, errorMessage: String? = nil) -> Color {
        switch visualRole(for: state, errorMessage: errorMessage) {
        case .preparing, .transferring, .verifying:
            return .orange
        case .copyOnlyComplete, .idle:
            return .blue
        case .safeToFormat:
            return .green
        case .manualCheckRequired:
            return .orange
        case .error:
            return .red
        case .cancelled:
            return .gray
        }
    }

    public static func isManualCheckRequired(errorMessage: String?) -> Bool {
        guard let errorMessage else { return false }
        return errorMessage.localizedCaseInsensitiveContains("MANUAL CHECK REQUIRED")
    }
}
