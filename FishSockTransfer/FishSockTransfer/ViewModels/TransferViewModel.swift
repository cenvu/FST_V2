import Foundation
import Combine

nonisolated public enum TransferInteractionLock {
    public static func isConfigurationLocked(for state: TransferState) -> Bool {
        switch state {
        case .validating, .copying, .verifying:
            return true
        case .ready, .copyComplete, .safeToFormat, .error, .cancelled:
            return false
        }
    }
}

@MainActor
public final class TransferViewModel: ObservableObject {
    @Published public var sourceURL: URL?
    @Published public var destinationURL: URL?
    @Published public var bandwidthLimit: Int? = nil
    @Published public var verificationMode: VerificationMode = .random33
    
    @Published public var transferState: TransferState = .ready
    @Published public var progress: Double = 0.0
    @Published public var speed: Double = 0.0
    @Published public var eta: TimeInterval = 0.0
    @Published public var currentFile: String = ""
    @Published public var logs: [LogEntry] = []
    @Published public var errorMessage: String? = nil
    @Published public var sourceMetadata: SourceStorageMetadata?
    @Published public var destinationMetadata: DestinationStorageMetadata?
    @Published public var storageWarningMessage: String? = nil
    @Published public var reportStatusMessage: String? = nil
    @Published public var workflowPhaseTitle: String = ""
    @Published public var workflowPhaseMessage: String = ""
    @Published public var workflowElapsedSeconds: Int = 0
    @Published public var projectETA: TimeInterval = 0.0
    @Published public var isPreparingVerify: Bool = false
    @Published public var verifyPhaseDescription: String = ""
    @Published public var copyElapsedSeconds: Int = 0
    @Published public var lastCopyDuration: Int? = nil
    @Published public var bundledRsyncInfo: BundledRsyncInfo = .unavailable(
        version: BundledRsyncService.bundledVersion,
        diagnostics: []
    )
    
    private let coordinator: TransferCoordinator
    private let driveService: DriveService
    private let bundledRsyncService: BundledRsyncService
    private var callbacksConfiguredTask: Task<Void, Never>?
    private var sourceMetadataTask: Task<Void, Never>?
    private var destinationMetadataTask: Task<Void, Never>?
    private var workflowElapsedTask: Task<Void, Never>?
    private var copyElapsedTask: Task<Void, Never>?
    private var workflowPhaseStartedAt: Date?
    private var copyStartedAt: Date?
    private var copyTransferredBytes: Int64 = 0
    private var didLogFirstAppliedProgress = false
    private var didLogFirstAppliedSpeed = false
    private var didLogFirstAppliedTransferTime = false
    
    public init(
        coordinator: TransferCoordinator? = nil,
        driveService: DriveService? = nil,
        bundledRsyncService: BundledRsyncService = BundledRsyncService()
    ) {
        self.bundledRsyncService = bundledRsyncService
        self.coordinator = coordinator ?? TransferCoordinator(bundledRsyncService: bundledRsyncService)
        self.driveService = driveService ?? DriveService()
        setupBindings()
        refreshBundledRsyncInfo()
    }

    @discardableResult
    public func selectSourceFolder(_ url: URL) -> Bool {
        guard !isTransferConfigurationLocked else {
            errorMessage = "Transfer in progress. Source and destination are locked."
            return false
        }

        guard isDirectory(url) else {
            errorMessage = "Source selection must be a folder."
            return false
        }

        sourceURL = url
        sourceMetadata = nil
        refreshSourceMetadata(for: url)
        errorMessage = nil
        return true
    }

    @discardableResult
    public func selectDestinationFolder(_ url: URL) -> Bool {
        guard !isTransferConfigurationLocked else {
            errorMessage = "Transfer in progress. Source and destination are locked."
            return false
        }

        guard isDirectory(url) else {
            errorMessage = "Destination selection must be a folder."
            return false
        }

        destinationURL = url
        destinationMetadata = nil
        refreshDestinationMetadata(for: url)
        errorMessage = nil
        return true
    }
    
    private func setupBindings() {
        callbacksConfiguredTask = Task { [weak self, coordinator] in
            await coordinator.configureCallbacks(
                onStateChanged: { [weak self] state in
                    self?.applyTransferState(state)
                },
                onProgress: { [weak self] p in
                    self?.applyTransferProgress(p)
                },
                onSpeed: { [weak self] s in
                    self?.applyTransferSpeed(s)
                },
                onTransferTime: { [weak self] e in
                    self?.applyTransferTime(e)
                },
                onTransferredBytes: { [weak self] bytes in
                    self?.applyTransferredBytes(bytes)
                },
                onCurrentFile: { [weak self] f in
                    self?.applyCurrentFile(f)
                },
                onVerifyPreparing: { [weak self] description in
                    self?.applyVerifyPreparing(description)
                },
                onError: { [weak self] message in
                    self?.errorMessage = message
                    self?.addLog(category: .error, message: message)
                },
                onLog: { [weak self] entry in
                    self?.appendLog(entry)
                },
                // Full unfiltered snapshot for TXT report.
                // viewModel.logs is the source of truth — it includes DIAG [VIEWMODEL]
                // entries that TransferCoordinator's LoggerService does not hold.
                onLogsSnapshot: { [weak self] in
                    self?.logs ?? []
                }
            )
        }
    }

    internal func applyTransferState(_ state: TransferState) {
        let previousState = transferState
        transferState = state
        handleTransferStateChange(state, previousState: previousState)
    }

    internal func applyTransferProgress(_ progress: Double) {
        self.progress = progress
        if progress > 0, !didLogFirstAppliedProgress {
            didLogFirstAppliedProgress = true
            addLog(category: .progress, message: String(format: "DIAG [VIEWMODEL] First progress applied: %.1f%%", progress))
        }
    }

    internal func applyTransferSpeed(_ speed: Double) {
        self.speed = speed
        recalculateProjectETA()
        if speed > 0, !didLogFirstAppliedSpeed {
            didLogFirstAppliedSpeed = true
            addLog(category: .progress, message: String(format: "DIAG [VIEWMODEL] First speed applied: %.2f MB/s", speed))
        }
    }

    internal func applyTransferTime(_ time: TimeInterval) {
        self.eta = time
        if time > 0, !didLogFirstAppliedTransferTime {
            didLogFirstAppliedTransferTime = true
            addLog(category: .progress, message: "DIAG [VIEWMODEL] First rsync time applied: \(TransferRuntimeMetricPresentation.timeValue(seconds: time))")
        }
    }

    internal func applyCurrentFile(_ currentFile: String) {
        self.currentFile = currentFile
    }

    internal func applyTransferredBytes(_ transferredBytes: Int64?, now: Date = Date()) {
        guard let transferredBytes, transferredBytes > 0 else {
            clearProjectETA()
            return
        }

        copyTransferredBytes = transferredBytes
        recalculateProjectETA(now: now)
    }

    internal func applyVerifyPreparing(_ description: String) {
        guard !description.isEmpty else {
            isPreparingVerify = false
            verifyPhaseDescription = ""
            return
        }

        isPreparingVerify = true
        verifyPhaseDescription = description
    }

    internal func beginCopyRuntime(at startedAt: Date = Date()) {
        copyStartedAt = startedAt
        copyTransferredBytes = 0
        copyElapsedSeconds = 0
        lastCopyDuration = nil
        clearProjectETA()
        startCopyElapsedTimer()
    }
    
    public func startTransfer() {
        reportStatusMessage = nil

        guard bundledRsyncInfo.isAvailable else {
            errorMessage = "Bundled rsync executable was not found."
            addLog(category: .error, message: "Bundled rsync executable was not found.")
            return
        }

        guard let sourceURL = sourceURL, let destinationURL = destinationURL else {
            errorMessage = "Please select both source and destination folders."
            return
        }

        guard !hasInsufficientDestinationSpace else {
            let message = insufficientDestinationSpaceMessage ?? "Insufficient destination space."
            errorMessage = message
            addLog(category: .warning, message: message)
            return
        }

        if let bandwidthLimit {
            do {
                _ = try RsyncBandwidthLimit.validate(kibPerSecond: bandwidthLimit)
            } catch {
                errorMessage = error.localizedDescription
                addLog(category: .error, message: error.localizedDescription)
                return
            }
        }
        
        resetTransferMetrics()
        beginPreparationPhase()
        errorMessage = nil
        addLog(category: .info, message: "Starting transfer workflow")
        addLog(category: .info, message: "Preparing transfer...")
        addLog(category: .info, message: "Scanning source and checking destination...")
        addLog(category: .info, message: "Source: \(sourceURL.lastPathComponent)")
        addLog(category: .info, message: "Destination: \(destinationURL.lastPathComponent)")
        
        let callbacksConfiguredTask = callbacksConfiguredTask
        Task { [coordinator, sourceURL, destinationURL, bandwidthLimit, verificationMode, callbacksConfiguredTask] in
            await callbacksConfiguredTask?.value
            await coordinator.startTransfer(
                source: sourceURL,
                destination: destinationURL,
                bandwidthLimit: bandwidthLimit,
                mode: verificationMode
            )
        }
    }
    
    public func cancelTransfer() {
        addLog(category: .warning, message: "User requested transfer cancellation")
        Task { [coordinator] in
            await coordinator.cancelTransfer()
        }
    }
    
    private func resetTransferMetrics() {
        progress = 0.0
        lastCopyDuration = nil
        clearCopyRuntimeMetrics()
        clearProjectETAState()
        clearVerifyPreparing()
        clearWorkflowPhase()
        resetRuntimeDiagnosticMarkers()
    }

    private func handleTransferStateChange(_ state: TransferState, previousState: TransferState) {
        switch state {
        case .ready:
            resetTransferMetrics()
        case .verifying:
            snapshotLastCopyDuration()
            progress = 0.0
            clearWorkflowPhase()
            clearCopyRuntimeMetrics()
            clearProjectETAState()
            applyVerifyPreparing("Preparing verification...")
        case .copyComplete, .safeToFormat:
            snapshotLastCopyDuration()
            progress = 100.0
            clearWorkflowPhase()
            clearCopyRuntimeMetrics()
            clearProjectETAState()
            clearVerifyPreparing()
        case .error, .cancelled:
            clearWorkflowPhase()
            clearCopyRuntimeMetrics()
            clearProjectETAState()
            clearVerifyPreparing()
        case .validating:
            progress = 0.0
            clearCopyRuntimeMetrics()
            clearProjectETAState()
            clearVerifyPreparing()
            if workflowPhaseStartedAt == nil {
                beginPreparationPhase()
            }
        case .copying:
            clearWorkflowPhase()
            clearVerifyPreparing()
            if previousState != .copying {
                clearCopyRuntimeMetrics()
                beginCopyRuntime()
            }
        }
    }

    private func clearCopyRuntimeMetrics() {
        speed = 0.0
        eta = 0.0
        currentFile = ""
        copyElapsedTask?.cancel()
        copyElapsedTask = nil
    }

    private func snapshotLastCopyDuration() {
        if let startedAt = copyStartedAt {
            lastCopyDuration = max(0, Int(Date().timeIntervalSince(startedAt).rounded(.down)))
        }
    }

    private func clearProjectETAState() {
        copyStartedAt = nil
        copyTransferredBytes = 0
        clearProjectETA()
    }

    private func clearProjectETA() {
        projectETA = 0.0
    }

    private func clearVerifyPreparing() {
        isPreparingVerify = false
        verifyPhaseDescription = ""
    }

    private func recalculateProjectETA(now: Date = Date()) {
        guard let copyStartedAt else {
            clearProjectETA()
            return
        }

        let elapsed = now.timeIntervalSince(copyStartedAt)
        guard elapsed >= 10,
              let sourceTotalBytes = sourceMetadata?.totalSizeBytes,
              sourceTotalBytes > 0,
              copyTransferredBytes > 0,
              speed > 0,
              speed.isFinite else {
            clearProjectETA()
            return
        }

        let speedBytesPerSecond = speed * 1024 * 1024
        guard speedBytesPerSecond.isFinite, speedBytesPerSecond > 0 else {
            clearProjectETA()
            return
        }

        let remainingBytes = max(sourceTotalBytes - copyTransferredBytes, 0)
        let eta = Double(remainingBytes) / speedBytesPerSecond
        guard eta.isFinite, eta > 0 else {
            clearProjectETA()
            return
        }

        projectETA = eta
    }

    private func resetRuntimeDiagnosticMarkers() {
        didLogFirstAppliedProgress = false
        didLogFirstAppliedSpeed = false
        didLogFirstAppliedTransferTime = false
    }

    private func beginPreparationPhase() {
        workflowPhaseTitle = "PREPARING TRANSFER"
        workflowPhaseMessage = "Scanning source and checking destination..."
        workflowElapsedSeconds = 0
        workflowPhaseStartedAt = Date()
        startWorkflowElapsedTimer()
    }

    private func clearWorkflowPhase() {
        workflowElapsedTask?.cancel()
        workflowElapsedTask = nil
        workflowPhaseStartedAt = nil
        workflowPhaseTitle = ""
        workflowPhaseMessage = ""
        workflowElapsedSeconds = 0
    }

    private func startWorkflowElapsedTimer() {
        workflowElapsedTask?.cancel()
        workflowElapsedTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { [weak self] in
                    guard let self, let startedAt = self.workflowPhaseStartedAt else { return }
                    self.workflowElapsedSeconds = max(0, Int(Date().timeIntervalSince(startedAt).rounded(.down)))
                }
            }
        }
    }

    private func startCopyElapsedTimer() {
        copyElapsedTask?.cancel()
        copyElapsedTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { [weak self] in
                    guard let self, let startedAt = self.copyStartedAt else { return }
                    self.copyElapsedSeconds = max(0, Int(Date().timeIntervalSince(startedAt).rounded(.down)))
                }
            }
        }
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    public var hasInsufficientDestinationSpace: Bool {
        guard let sourceMetadata, let destinationMetadata else { return false }
        return sourceMetadata.totalSizeBytes > destinationMetadata.freeSpaceBytes
    }

    public var isTransferConfigurationLocked: Bool {
        TransferInteractionLock.isConfigurationLocked(for: transferState)
    }

    public var destinationTargetPreview: String? {
        guard let sourceURL, let destinationURL else { return nil }
        return TransferDestinationPreview.message(source: sourceURL, destination: destinationURL)
    }

    public var canStartTransfer: Bool {
        guard sourceURL != nil else { return false }
        guard destinationURL != nil else { return false }
        guard bundledRsyncInfo.isAvailable else { return false }
        guard !hasInsufficientDestinationSpace else { return false }
        guard isBandwidthLimitValid else { return false }

        switch transferState {
        case .ready, .error, .cancelled, .copyComplete, .safeToFormat:
            return true
        case .validating, .copying, .verifying:
            return false
        }
    }

    public var estimatedCopyTimeSeconds: TimeInterval {
        guard let sourceTotalBytes = sourceMetadata?.totalSizeBytes,
              sourceTotalBytes > 0,
              let bandwidthLimit,
              bandwidthLimit > 0 else {
            return 0
        }

        let selectedLimitMBps = Double(bandwidthLimit) / 1024.0
        guard selectedLimitMBps.isFinite, selectedLimitMBps > 0 else {
            return 0
        }

        let bandwidthBytesPerSecond = selectedLimitMBps * 1024.0 * 1024.0
        guard bandwidthBytesPerSecond.isFinite, bandwidthBytesPerSecond > 0 else {
            return 0
        }

        let estimate = Double(sourceTotalBytes) / bandwidthBytesPerSecond
        guard estimate.isFinite, estimate > 0 else {
            return 0
        }

        return estimate
    }

    public var startBlockedReason: String? {
        if isTransferConfigurationLocked {
            return "Transfer in progress. Source, destination, and settings locked."
        }

        if sourceURL == nil {
            return "Select a source folder."
        }

        if destinationURL == nil {
            return "Select a destination folder."
        }

        if !bundledRsyncInfo.isAvailable {
            return bundledRsyncInfo.diagnostics.first ?? "Bundled rsync unavailable."
        }

        if hasInsufficientDestinationSpace {
            return insufficientDestinationSpaceMessage
        }

        if let bandwidthLimitValidationMessage {
            return bandwidthLimitValidationMessage
        }

        if transferState == .error, let errorMessage {
            return errorMessage
        }

        return nil
    }

    private var isBandwidthLimitValid: Bool {
        bandwidthLimitValidationMessage == nil
    }

    private var bandwidthLimitValidationMessage: String? {
        guard let bandwidthLimit else { return nil }
        do {
            _ = try RsyncBandwidthLimit.validate(kibPerSecond: bandwidthLimit)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    private var insufficientDestinationSpaceMessage: String? {
        guard let sourceMetadata, let destinationMetadata else { return nil }
        return TransferPreflightError.insufficientDestinationSpace(
            required: sourceMetadata.totalSizeBytes,
            available: destinationMetadata.freeSpaceBytes
        ).errorDescription
    }

    private func refreshSourceMetadata(for url: URL) {
        sourceMetadataTask?.cancel()
        sourceMetadataTask = Task { [driveService, weak self] in
            do {
                let metadata = try await driveService.sourceMetadata(for: url)
                try Task.checkCancellation()
                await MainActor.run {
                    self?.sourceMetadata = metadata
                    self?.refreshStorageWarning()
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self?.sourceMetadata = nil
                    self?.storageWarningMessage = nil
                    self?.errorMessage = "Unable to analyze source folder."
                }
            }
        }
    }

    private func refreshDestinationMetadata(for url: URL) {
        destinationMetadataTask?.cancel()
        destinationMetadataTask = Task { [driveService, weak self] in
            do {
                let metadata = try await driveService.destinationMetadata(for: url)
                try Task.checkCancellation()
                await MainActor.run {
                    self?.destinationMetadata = metadata
                    self?.refreshStorageWarning()
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self?.destinationMetadata = nil
                    self?.storageWarningMessage = nil
                    self?.errorMessage = "Unable to analyze destination folder."
                }
            }
        }
    }

    private func refreshStorageWarning() {
        storageWarningMessage = hasInsufficientDestinationSpace ? insufficientDestinationSpaceMessage : nil
    }

    private func refreshBundledRsyncInfo() {
        Task { [weak self, bundledRsyncService] in
            let bundledInfo = await bundledRsyncService.bundledInfo()
            await MainActor.run {
                self?.bundledRsyncInfo = bundledInfo
            }
        }
    }
    
    private func addLog(category: LogCategory, message: String) {
        appendLog(LogEntry(category: category, message: message))
    }

    private func appendLog(_ entry: LogEntry) {
        logs.append(entry)
        if let message = TransferReportStatusPresentation.message(forLogMessage: entry.message) {
            reportStatusMessage = message
        }
    }
}

nonisolated public enum TransferDestinationPreview {
    public static func message(source: URL?, destination: URL?) -> String? {
        guard let source, let destination else { return nil }
        return message(source: source, destination: destination)
    }

    public static func message(source: URL, destination: URL) -> String {
        "Will create: \(destination.lastPathComponent)/\(source.lastPathComponent)"
    }
}

nonisolated public enum TransferReportStatusPresentation {
    public static func message(forLogMessage logMessage: String) -> String? {
        if logMessage.hasPrefix("Report saved: ") {
            return logMessage
        }

        if logMessage.hasPrefix("Report skipped: ") {
            return "Report skipped: no report was written because the destination was unsafe for report output."
        }

        if logMessage.hasPrefix("Report write failed: ") {
            let reason = String(logMessage.dropFirst("Report write failed: ".count))
            return "Report warning: \(reason)"
        }

        return nil
    }
}

nonisolated public enum TransferRuntimeMetricPresentation {
    public static func currentFileTitle(currentFile: String, state: TransferState, isPreparingVerify: Bool = false) -> String {
        if state == .copying && currentFile.isEmpty {
            return "COPY STATUS"
        }

        if state == .verifying {
            if isPreparingVerify { return "VERIFY STATUS" }
            if currentFile.isEmpty { return "VERIFY PROGRESS" }
        }

        return "CURRENT FILE"
    }

    public static func currentFileValue(currentFile: String, state: TransferState, isPreparingVerify: Bool = false, verifyPhaseDescription: String = "") -> String {
        guard currentFile.isEmpty else {
            return currentFile
        }

        if state == .copying {
            return "Waiting for rsync progress output..."
        }

        if state == .verifying {
            if isPreparingVerify {
                return verifyPhaseDescription.isEmpty ? "Preparing verification..." : verifyPhaseDescription
            }
            return "Verifying..."
        }

        return "-"
    }

    public static func timeValue(seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "-" }
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    public static func estimatedCopyTimeValue(seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "-" }
        return "~\(timeValue(seconds: seconds))"
    }
}
