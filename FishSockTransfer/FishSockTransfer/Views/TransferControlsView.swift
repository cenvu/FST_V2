// FST / CenVu | (+84) 842 841 222

import SwiftUI

private struct TransferDropdownOption<Value: Hashable>: Identifiable {
    let label: String
    let value: Value

    var id: String { label }
}

private struct TransferDropdownField<Value: Hashable>: View {
    @Environment(\.locale) private var locale
    @Binding var selection: Value

    let accessibilityTitle: LocalizedStringKey
    let options: [TransferDropdownOption<Value>]

    @State private var isPresented = false

    private var selectedLabel: String {
        options.first(where: { $0.value == selection })
            .map { localized($0.label) } ?? "—"
    }

    var body: some View {
        GeometryReader { geometry in
            Button {
                isPresented = true
            } label: {
                HStack(spacing: 10) {
                    Text(selectedLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(FSTPalette.text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FSTPalette.muted)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 10)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(FSTPalette.inset)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(FSTPalette.line, lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .contentShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(accessibilityTitle))
            .accessibilityValue(Text(selectedLabel))
            .popover(isPresented: $isPresented, arrowEdge: .bottom) {
                VStack(spacing: 2) {
                    ForEach(options) { option in
                        optionButton(option)
                    }
                }
                .padding(5)
                .frame(width: max(geometry.size.width, 200))
                .background(FSTPalette.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(FSTPalette.line, lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .presentationBackground(FSTPalette.surface)
                .presentationCornerRadius(6)
            }
        }
        .frame(height: 36)
    }

    private func optionButton(_ option: TransferDropdownOption<Value>) -> some View {
        let isSelected = option.value == selection
        let label = localized(option.label)

        return Button {
            selection = option.value
            isPresented = false
        } label: {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(FSTPalette.text)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FSTPalette.active)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 9)
            .frame(height: 30)
            .background(isSelected ? FSTPalette.raised : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func localized(_ text: String) -> String {
        TransferPresentationLocalization.text(text, locale: locale)
    }
}

private struct TransferSetupColumnLayout: Layout {
    var spacing: CGFloat
    var verificationRatio: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else {
            return subviews.first?.sizeThatFits(proposal) ?? .zero
        }

        let idealWidth = subviews.reduce(spacing) { $0 + $1.sizeThatFits(.unspecified).width }
        let width = proposal.width.map { $0.isFinite ? $0 : idealWidth } ?? idealWidth
        let availableWidth = max(0, width - spacing)
        let bandwidthWidth = availableWidth / (1 + verificationRatio)
        let verificationWidth = availableWidth - bandwidthWidth
        let bandwidthSize = subviews[0].sizeThatFits(ProposedViewSize(width: bandwidthWidth, height: proposal.height))
        let verificationSize = subviews[1].sizeThatFits(ProposedViewSize(width: verificationWidth, height: proposal.height))
        return CGSize(width: width, height: max(bandwidthSize.height, verificationSize.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }

        let availableWidth = max(0, bounds.width - spacing)
        let bandwidthWidth = availableWidth / (1 + verificationRatio)
        let verificationWidth = availableWidth - bandwidthWidth
        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bandwidthWidth, height: bounds.height)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.minX + bandwidthWidth + spacing, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: verificationWidth, height: bounds.height)
        )
    }
}

public struct TransferControlsView: View {
    @Environment(\.locale) private var locale
    @ObservedObject var viewModel: TransferViewModel
    private let onOpenTechnicalLog: (() -> Void)?
    @State private var isShowingCancelConfirmation = false
    @State private var cancelRequestGuard = TransferCancelRequestGuard()

    // Picker values match the ViewModel's MB/s contract; nil means Unlimited.
    private let bandwidthOptions: [(label: String, value: Int?)] =
        RsyncBandwidthLimit.presetMegabytesPerSecond.map {
            (label: "\($0) MB/s", value: Optional($0))
        } + [(label: "Unlimited", value: nil)]
    
    public init(viewModel: TransferViewModel, onOpenTechnicalLog: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onOpenTechnicalLog = onOpenTechnicalLog
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            settingsPanel

            switch viewModel.transferState {
            case .ready, .validating, .copying, .verifying:
                activeControlBar
            case .copyComplete, .safeToFormat, .error, .cancelled:
                terminalControlBar
            }

            progressPanel

            if let storageWarningMessage = viewModel.storageWarningMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(localized(storageWarningMessage))
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let startBlockedReason = TransferControlsActionPresentation.visibleStartBlockedReason(
                for: viewModel.transferState,
                reason: viewModel.startBlockedReason,
                errorMessage: viewModel.errorMessage
            ) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isTransferConfigurationLocked ? "lock.fill" : "info.circle.fill")
                    Text(localized(startBlockedReason))
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let reportStatusMessage = viewModel.reportStatusMessage {
                HStack(spacing: 8) {
                    Image(systemName: reportStatusMessage.hasPrefix("Report saved: ") ? "doc.text.fill" : "exclamationmark.triangle.fill")
                    Text(TransferPresentationLocalization.reportStatus(reportStatusMessage, locale: locale))
                        .help(TransferPresentationLocalization.reportStatus(reportStatusMessage, locale: locale))
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(reportStatusMessage.hasPrefix("Report saved: ") ? Color.secondary : Color.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
        .confirmationDialog("Cancel Transfer?", isPresented: $isShowingCancelConfirmation, titleVisibility: .visible) {
            Button("Cancel Transfer", role: .destructive) {
                cancelRequestGuard.confirmCancellationRequest()
                isShowingCancelConfirmation = false
                viewModel.cancelTransfer()
            }
            Button("Continue Transfer", role: .cancel) {
                isShowingCancelConfirmation = false
            }
        } message: {
            Text("The current transfer will stop. Source and destination selections will remain available.")
        }
        .onChange(of: viewModel.transferState) { newState in
            cancelRequestGuard.reset(for: newState)
        }
    }

    private var progressPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Job Status").font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(localized(TransferControlsActionPresentation.stateTitle(
                    for: viewModel.transferState,
                    canStartTransfer: viewModel.canStartTransfer,
                    errorMessage: viewModel.errorMessage
                )))
                .font(.caption)
                .foregroundStyle(TransferControlsActionPresentation.stateColor(
                    for: viewModel.transferState, errorMessage: viewModel.errorMessage
                ))
            }

            HStack(alignment: .top, spacing: 16) {
                heroMetric(title: jobHeroTitles.progress,
                           value: jobDisplayProgress.map { "\(Int($0.rounded()))%" } ?? "—")
                heroMetric(title: jobHeroTitles.eta, value: phaseETA)
                heroMetric(title: jobHeroTitles.third, value: phaseThirdMetric)
            }

            ProgressView(value: jobDisplayProgress ?? 0, total: 100)
                .progressViewStyle(FSTThinProgressStyle(tint:
                    TransferControlsActionPresentation.stateColor(for: viewModel.transferState, errorMessage: viewModel.errorMessage)
                ))
                .accessibilityLabel(localized(jobHeroTitles.progress))
                .accessibilityValue(progressAccessibilityValue)

            HStack(spacing: 12) {
                Text(localized(TransferControlsActionPresentation.stateSubtitle(
                    for: viewModel.transferState,
                    canStartTransfer: viewModel.canStartTransfer,
                    workflowPhaseTitle: viewModel.workflowPhaseTitle,
                    workflowPhaseMessage: viewModel.workflowPhaseMessage,
                    errorMessage: viewModel.errorMessage
                )))
                if shouldShowProgressDetails && !viewModel.workflowPhaseTitle.isEmpty {
                    Spacer(minLength: 0)
                    Text("Elapsed: \(formatElapsed(viewModel.workflowElapsedSeconds))")
                        .monospacedDigit()
                }
            }
            .font(.caption)
            .foregroundStyle(FSTPalette.muted)

            Divider().overlay(FSTPalette.line)
            HStack(alignment: .top, spacing: 16) {
                runtimeMetric(title: localized("AVERAGE COPY SPEED"), value: TransferRuntimeMetricPresentation.averageCopySpeedValue(snapshot: viewModel.copyRuntimeSnapshot))
                runtimeMetric(title: localized("COPY ELAPSED"), value: viewModel.copyRuntimeSnapshot == nil ? "—" : formatElapsed(copyElapsedSeconds))
                runtimeMetric(title: localized("COPIED"), value: copiedBytesValue)
                runtimeMetric(title: localized("FILES"), value: copiedFilesValue)
            }
            Divider().overlay(FSTPalette.line)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(localized(runtimeFileMetricTitle)).font(.caption).foregroundStyle(FSTPalette.muted)
                Text(displayCurrentFile)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(FSTPalette.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(viewModel.currentFile.isEmpty ? displayCurrentFile : viewModel.currentFile)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var jobHeroTitles: TransferRuntimeMetricPresentation.HeroTitles {
        TransferJobStatusPresentation.heroTitles(for: viewModel.transferState)
    }

    private var jobDisplayProgress: Double? {
        TransferJobStatusPresentation.percentage(for: viewModel.transferState, observedProgress: viewModel.progress)
    }

    private var phaseETA: String {
        switch viewModel.transferState {
        case .copying: return copyEtaValue
        case .verifying: return verifyEtaValue
        default: return "—"
        }
    }

    private var phaseThirdMetric: String {
        switch viewModel.transferState {
        case .copying: return currentSpeedValue
        case .verifying: return formatElapsed(viewModel.verifyElapsedSeconds)
        default: return "—"
        }
    }

    private func heroMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localized(title)).font(.system(size: 12)).foregroundStyle(FSTPalette.muted)
            Text(value)
                .font(.system(size: value.count > 8 ? 20 : 28, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .help(value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var settingsPanel: some View {
        AnyLayout(TransferSetupColumnLayout(spacing: 14, verificationRatio: 1.6)) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bandwidth")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                TransferDropdownField(
                    selection: $viewModel.bandwidthLimit,
                    accessibilityTitle: "Bandwidth Limit",
                    options: bandwidthOptions.map {
                        TransferDropdownOption(label: $0.label, value: $0.value)
                    }
                )

                Text("Copy speed cap")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Verification")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                TransferDropdownField(
                    selection: $viewModel.verificationMode,
                    accessibilityTitle: "Verification Mode",
                    options: [
                        TransferDropdownOption(label: VerificationMode.none.selectionLabel, value: .none),
                        TransferDropdownOption(label: VerificationMode.random33.selectionLabel, value: .random33),
                        TransferDropdownOption(label: VerificationMode.full.selectionLabel, value: .full)
                    ]
                )

                Text(localized(viewModel.verificationMode.operatorDescription))
                    .help(localized(viewModel.verificationMode.operatorDescription))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(viewModel.isTransferConfigurationLocked)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Divider().overlay(FSTPalette.line) }
    }

    private var activeControlBar: some View {
        let state = viewModel.transferState
        let stateColor = TransferControlsActionPresentation.stateColor(for: state)

        return HStack(spacing: 12) {
            Image(systemName: TransferControlsActionPresentation.stateIcon(for: state))
                .font(.system(size: 16))
                .foregroundColor(stateColor)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(localized(TransferControlsActionPresentation.stateTitle(
                    for: state,
                    canStartTransfer: viewModel.canStartTransfer
                )))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(stateColor)

                Text(localized(TransferControlsActionPresentation.stateSubtitle(
                    for: state,
                    canStartTransfer: viewModel.canStartTransfer,
                    startBlockedReason: viewModel.startBlockedReason,
                    workflowPhaseTitle: viewModel.workflowPhaseTitle,
                    workflowPhaseMessage: viewModel.workflowPhaseMessage
                )))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if state == .validating {
                // Validation has no cancellation path. This is status, not an action.
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Preparing Transfer")
            } else {
                activeActionButton
            }
        }
        .operationalPanel()
    }

    @ViewBuilder
    private var activeActionButton: some View {
        let state = viewModel.transferState
        let button = Button(action: handleActionButton) {
            if state == .ready {
                Text(localized(TransferActionPresentation.title(for: state)))
                    .fixedSize()
            } else {
                Label(
                    localized(TransferActionPresentation.title(for: state)),
                    systemImage: TransferControlsActionPresentation.icon(for: state)
                )
                .fixedSize()
            }
        }
        .controlSize(.regular)
        .disabled(!isActionButtonEnabled)
        .accessibilityLabel(accessibilityActionLabel)

        if state == .ready {
            button
                .buttonStyle(FSTPrimaryActionButtonStyle())
        } else {
            button
                .buttonStyle(.bordered)
                .tint(FSTPalette.error)
                .foregroundStyle(FSTPalette.error)
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(FSTPalette.error, lineWidth: 1)
                        .allowsHitTesting(false)
                }
        }
    }

    private var terminalControlBar: some View {
        let state = viewModel.transferState
        let errorMessage = viewModel.errorMessage
        let stateColor = TransferControlsActionPresentation.stateColor(for: state, errorMessage: errorMessage)
        let visualRole = TransferControlsActionPresentation.visualRole(for: state, errorMessage: errorMessage)
        let panelBackground: Color
        switch visualRole {
        case .safeToFormat:
            panelBackground = FSTPalette.statusSuccessSurface
        case .error:
            panelBackground = FSTPalette.statusErrorSurface
        default:
            panelBackground = FSTPalette.surface
        }

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: TransferControlsActionPresentation.stateIcon(for: state, errorMessage: errorMessage))
                    .font(.system(size: 16))
                    .foregroundColor(stateColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(localized(TransferControlsActionPresentation.stateTitle(for: state, errorMessage: errorMessage)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(stateColor)
                    Text(localized(TransferControlsActionPresentation.stateSubtitle(for: state, errorMessage: errorMessage)))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    if let actionTitle = TransferActionPresentation.terminalActionTitle(
                        for: state,
                        canStartTransfer: viewModel.canStartTransfer
                    ) {
                        Button(localized(actionTitle), action: handleActionButton)
                            .buttonStyle(.borderedProminent)
                            .tint(FSTPalette.primaryAction)
                            .controlSize(.regular)
                            .disabled(!isActionButtonEnabled)
                            .fixedSize()
                    }
                    if let openTechnicalLogAction {
                        Button("Open Technical Log", action: openTechnicalLogAction)
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .fixedSize()
                    }
                }
            }

            if let detail = TransferControlsActionPresentation.terminalErrorDetail(for: state, errorMessage: errorMessage) {
                DisclosureGroup("Technical Details") {
                    Text(detail)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
        }
        .operationalPanel(tint: stateColor, background: panelBackground)
    }

    // The same callback supplied by ContentView is used directly by the native Button.
    var openTechnicalLogAction: (() -> Void)? {
        guard viewModel.transferState == .error else { return nil }
        return onOpenTechnicalLog
    }

    private var accessibilityActionLabel: String {
        if TransferActionPresentation.isActiveCancellableState(viewModel.transferState) {
            return localized("Cancel Transfer")
        }
        if viewModel.transferState == .error, viewModel.canStartTransfer {
            return localized("Retry Transfer")
        }
        return localized(TransferControlsActionPresentation.title(
            for: viewModel.transferState,
            errorMessage: viewModel.errorMessage,
            canStartTransfer: viewModel.canStartTransfer
        ))
    }

    private var progressAccessibilityValue: String {
        guard let jobDisplayProgress else { return localized("Unavailable") }
        return "\(Int(jobDisplayProgress.rounded())) \(localized("percent"))"
    }

    private func localized(_ english: String) -> String {
        TransferPresentationLocalization.text(english, locale: locale)
    }

    private var displayCurrentFile: String {
        localized(TransferRuntimeMetricPresentation.currentFileValue(
            currentFile: viewModel.currentFile,
            state: viewModel.transferState
        ))
    }

    private var runtimeFileMetricTitle: String {
        localized(TransferRuntimeMetricPresentation.currentFileTitle(
            currentFile: viewModel.currentFile,
            state: viewModel.transferState
        ))
    }

    private var verifyEtaValue: String {
        if viewModel.progress >= 0.99 {
            return localized("Finalizing...")
        }
        guard viewModel.eta > 0, viewModel.verifyElapsedSeconds > 0 else {
            return localized("Estimating...")
        }
        return TransferPresentationLocalization.remainingTime("~\(formatTransferTime(viewModel.eta)) remaining", locale: locale)
    }

    private func runtimeMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
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
            return TransferPresentationLocalization.remainingTime("\(formatTransferTime(etaSeconds)) remaining", locale: locale)
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
        TransferActionPresentation.isEnabled(
            for: viewModel.transferState,
            canStartTransfer: viewModel.canStartTransfer,
            isCancellationRequested: cancelRequestGuard.isCancellationRequested
        )
    }

    private var shouldShowProgressDetails: Bool {
        return viewModel.transferState == .validating ||
               viewModel.transferState == .copying ||
               viewModel.transferState == .verifying
    }

    private func handleActionButton() {
        if TransferActionPresentation.isActiveCancellableState(viewModel.transferState) {
            // Active cancellable state: request operator confirmation first.
            // No ViewModel cancellation request is sent before confirmation.
            if cancelRequestGuard.allowsNewCancellationRequest(for: viewModel.transferState) {
                isShowingCancelConfirmation = true
            }
            return
        }
        viewModel.startTransfer()
    }
}

public extension VerificationMode {
    var operatorDescription: String {
        switch self {
        case .none:
            return "Copy only. No hash verification by FST."
        case .random33:
            return "SHA256 sample verification. Approximately 33% coverage."
        case .full:
            return "xxHash64 full verification. Fast, non-cryptographic."
        }
    }
}

/// Formatting only. Terminal success comes exclusively from canonical state.
nonisolated public enum TransferJobStatusPresentation {
    public static func heroTitles(for state: TransferState) -> TransferRuntimeMetricPresentation.HeroTitles {
        if let active = TransferRuntimeMetricPresentation.heroTitles(for: state) { return active }
        switch state {
        case .safeToFormat:
            return .init(progress: "VERIFY PROGRESS", eta: "VERIFY ETA", third: "VERIFY ELAPSED")
        case .error, .cancelled:
            return .init(progress: "PHASE PROGRESS", eta: "PHASE ETA", third: "CURRENT SPEED")
        default:
            return .init(progress: "COPY PROGRESS", eta: "COPY ETA", third: "CURRENT COPY SPEED")
        }
    }

    public static func percentage(for state: TransferState, observedProgress: Double) -> Double? {
        switch state {
        case .ready, .validating: return 0
        case .copyComplete, .safeToFormat: return 100
        case .error, .cancelled: return nil // Backend does not expose the stopped phase here.
        case .copying, .verifying:
            guard observedProgress.isFinite else { return nil }
            let percent = state == .verifying && observedProgress <= 1 ? observedProgress * 100 : observedProgress
            return min(max(percent, 0), 100)
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
    /// State identity is separate from the operator action returned by title(for:).
    public static func stateTitle(for state: TransferState, canStartTransfer: Bool = false, errorMessage: String? = nil) -> String {
        switch state {
        case .ready:
            return canStartTransfer ? "READY" : "SETUP REQUIRED"
        case .validating:
            return "PREPARING"
        case .copying:
            return "COPYING"
        case .verifying:
            return "VERIFYING"
        case .copyComplete, .safeToFormat, .error, .cancelled:
            return title(for: state, errorMessage: errorMessage)
        }
    }

    public static func stateSubtitle(
        for state: TransferState,
        canStartTransfer: Bool = false,
        startBlockedReason: String? = nil,
        workflowPhaseTitle: String = "",
        workflowPhaseMessage: String = "",
        errorMessage: String? = nil
    ) -> String {
        switch state {
        case .ready:
            return canStartTransfer ? "Ready to transfer" : (startBlockedReason ?? "Complete transfer setup.")
        case .validating:
            let phase = [workflowPhaseTitle, workflowPhaseMessage].filter { !$0.isEmpty }
            return phase.isEmpty ? subtitle(for: state) : phase.joined(separator: " — ")
        case .copying:
            return "Copy in progress. Do not remove media."
        case .verifying:
            return "Verification in progress. Do not remove media."
        case .error:
            return terminalErrorSummary(errorMessage: errorMessage)
        case .copyComplete, .safeToFormat, .cancelled:
            return subtitle(for: state)
        }
    }

    public static func stateIcon(for state: TransferState, errorMessage: String? = nil) -> String {
        switch state {
        case .ready:
            return "tray"
        case .validating, .verifying:
            return "magnifyingglass"
        case .copying:
            return "doc.on.doc"
        case .copyComplete, .safeToFormat, .error, .cancelled:
            return icon(for: state, errorMessage: errorMessage)
        }
    }

    public static func stateColor(for state: TransferState, errorMessage: String? = nil) -> Color {
        switch visualRole(for: state, errorMessage: errorMessage) {
        case .idle:
            return .secondary
        case .preparing, .transferring:
            return FSTPalette.active
        case .verifying:
            return FSTPalette.warning
        case .copyOnlyComplete, .safeToFormat, .manualCheckRequired, .error, .cancelled:
            return buttonColor(for: state, errorMessage: errorMessage)
        }
    }

    /// Preserve backend text; split only at real line breaks, without diagnosing it.
    public static func terminalErrorSummary(errorMessage: String?) -> String {
        let message = errorMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var summary = message.components(separatedBy: .newlines).first ?? ""
        if let prefix = summary.range(of: "MANUAL CHECK REQUIRED:", options: [.anchored, .caseInsensitive]) {
            summary.removeSubrange(prefix)
            summary = summary.trimmingCharacters(in: .whitespaces)
        }
        if !summary.isEmpty { return summary }
        return isManualCheckRequired(errorMessage: errorMessage)
            ? "Verification did not pass. Review before using media."
            : "Review the error before retrying."
    }

    public static func terminalErrorDetail(for state: TransferState, errorMessage: String?) -> String? {
        guard state == .error, let errorMessage else { return nil }
        let lines = errorMessage.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
        let detail = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return detail.isEmpty ? nil : detail
    }

    public static func visibleStartBlockedReason(for state: TransferState, reason: String?, errorMessage: String?) -> String? {
        // The error is already shown in the terminal bar; preserve other setup blockers.
        if state == .error, reason == errorMessage { return nil }
        return reason
    }

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
        // Outcome wording applies only when no retry is being presented.
        // An admissible retry always retains its explicit operator action label.
        if state == .error, !canStartTransfer, isManualCheckRequired(errorMessage: errorMessage) {
            return "MANUAL CHECK REQUIRED"
        }
        return TransferActionPresentation.title(for: state, canStartTransfer: canStartTransfer)
    }

    public static func icon(
        for state: TransferState,
        errorMessage: String? = nil,
        canStartTransfer: Bool = false
    ) -> String {
        if state == .error, canStartTransfer {
            return "arrow.clockwise"
        }

        switch visualRole(for: state, errorMessage: errorMessage) {
        case .preparing:
            return "magnifyingglass"
        case .transferring, .verifying:
            return "stop.fill"
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
            return FSTPalette.warning
        case .copyOnlyComplete, .idle:
            return FSTPalette.active
        case .safeToFormat:
            return FSTPalette.verified
        case .manualCheckRequired:
            return FSTPalette.warning
        case .error:
            return FSTPalette.error
        case .cancelled:
            return .gray
        }
    }

    public static func isManualCheckRequired(errorMessage: String?) -> Bool {
        guard let errorMessage else { return false }
        return errorMessage.localizedCaseInsensitiveContains("MANUAL CHECK REQUIRED")
    }
}
