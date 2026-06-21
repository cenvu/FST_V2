import SwiftUI

public struct TransferControlsView: View {
    @ObservedObject var viewModel: TransferViewModel
    
    // Limits represented in KiB/s for rsync 3.x --bwlimit semantics.
    private let bandwidthOptions: [(label: String, value: Int?)] = [
        ("50 MB/s", RsyncBandwidthLimit.kibPerSecond(for: 50)),
        ("100 MB/s", RsyncBandwidthLimit.kibPerSecond(for: 100)),
        ("150 MB/s", RsyncBandwidthLimit.kibPerSecond(for: 150)),
        ("200 MB/s", RsyncBandwidthLimit.kibPerSecond(for: 200)),
        ("250 MB/s", RsyncBandwidthLimit.kibPerSecond(for: 250)),
        ("Unlimited", nil)
    ]
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Transfer Settings
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BANDWIDTH LIMIT")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .bold()

                        Picker("", selection: $viewModel.bandwidthLimit) {
                            ForEach(bandwidthOptions, id: \.label) { option in
                                Text(option.label).tag(option.value)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 200, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("VERIFICATION MODE")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .bold()

                        Picker("", selection: $viewModel.verificationMode) {
                            Text("None").tag(VerificationMode.none)
                            Text("Random 33%").tag(VerificationMode.random33)
                            Text("Full 100%").tag(VerificationMode.full)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(width: 200, alignment: .leading)
                    }
                }
                .disabled(viewModel.transferState == .copying || viewModel.transferState == .verifying)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: handleActionButton) {
                    HStack {
                        Image(systemName: actionButtonIcon)
                        Text(actionButtonTitle)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                    .font(.system(size: 18))
                    .frame(width: 300, height: 68)
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(9)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isActionButtonEnabled)
            }
            .frame(maxWidth: .infinity)

            if let storageWarningMessage = viewModel.storageWarningMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(storageWarningMessage)
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color(red: 0.86, green: 0.60, blue: 0.28))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Runtime Feedback
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TRANSFER PROGRESS")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .bold()
                    Spacer()
                    Text("\(Int(displayProgress.rounded()))%")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.blue)
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
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.18))
            .cornerRadius(8)
            
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
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
                .foregroundColor(.gray)
                .bold()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)
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

    private var actionButtonTitle: String {
        switch viewModel.transferState {
        case .copying, .validating:
            return "TRANSFERRING"
        case .verifying:
            return "VERIFYING"
        case .copyComplete, .safeToFormat:
            return "SAFE TO FORMAT"
        case .error:
            return "MANUAL CHECK REQUIRED"
        case .ready, .cancelled:
            return "START"
        }
    }

    private var actionButtonIcon: String {
        switch viewModel.transferState {
        case .copying, .validating, .verifying:
            return "arrow.triangle.2.circlepath"
        case .copyComplete, .safeToFormat:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .ready, .cancelled:
            return "play.fill"
        }
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

    private var buttonColor: Color {
        switch viewModel.transferState {
        case .copying, .validating:
            return Color(red: 0.78, green: 0.60, blue: 0.36)
        case .verifying:
            return Color(red: 0.82, green: 0.52, blue: 0.34)
        case .copyComplete, .safeToFormat:
            return Color(red: 0.43, green: 0.65, blue: 0.48)
        case .error:
            return Color(red: 0.70, green: 0.38, blue: 0.36)
        case .ready, .cancelled:
            return Color(red: 0.42, green: 0.60, blue: 0.78)
        }
    }
}
