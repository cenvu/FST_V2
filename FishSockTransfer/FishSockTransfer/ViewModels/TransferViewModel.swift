// FST / CenVu | (+84) 842 841 222

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
    @Published public var copyRuntimeSnapshot: CopyRuntimeSnapshot?
    @Published public var copyRuntimeSignalSource: CopyRuntimeSignalSource = .unavailable
    @Published public var copyElapsedSeconds: Int = 0
    @Published public var bundledRsyncInfo: BundledRsyncInfo = .unavailable(
        version: BundledRsyncService.bundledVersion,
        diagnostics: []
    )
    @Published public var notificationSettings: NotificationSettings = .default
    @Published public var telegramBotToken: String = ""
    @Published public var notificationStatus: NotificationRuntimeStatus = .from(settings: .default, token: "")
    @Published public var isSendingTelegramTestMessage: Bool = false

    private let coordinator: TransferCoordinator
    private let driveService: DriveService
    private let bundledRsyncService: BundledRsyncService
    private let notificationCoordinator: NotificationCoordinator
    private let notificationSettingsStore: NotificationSettingsStore
    private var callbacksConfiguredTask: Task<Void, Never>?
    private var sourceMetadataTask: Task<Void, Never>?
    private var destinationMetadataTask: Task<Void, Never>?
    private var workflowElapsedTask: Task<Void, Never>?
    private var notificationHeartbeatTask: Task<Void, Never>?
    private var workflowPhaseStartedAt: Date?
    private var runtimeElapsedTask: Task<Void, Never>?
    private var copyStartedAt: Date?
    private var verifyStartedAt: Date?
    public private(set) var verifyElapsedSeconds: Int = 0
    private var lastRsyncRuntimeUpdateAt: Date?
    private var rsyncCurrentFile = ""
    private var didLogFirstAppliedProgress = false
    private var didLogFirstAppliedSpeed = false
    private var didLogFirstAppliedTransferTime = false
    private var didLogFirstAppliedCurrentFile = false
    private var didLogUsingDestinationObserver = false
    private var didLogUsingRsyncMetrics = false
    private var lastNotificationWarningMessage: String?
    private var lastNotificationWarningLoggedAt: Date?
    private let observerFallbackDelay: TimeInterval = 10
    private let notificationWarningRepeatInterval: TimeInterval = 300

    public init(
        coordinator: TransferCoordinator? = nil,
        driveService: DriveService? = nil,
        bundledRsyncService: BundledRsyncService = BundledRsyncService(),
        notificationCoordinator: NotificationCoordinator = NotificationCoordinator(),
        notificationSettingsStore: NotificationSettingsStore = NotificationSettingsStore()
    ) {
        self.bundledRsyncService = bundledRsyncService
        self.coordinator = coordinator ?? TransferCoordinator(bundledRsyncService: bundledRsyncService)
        self.driveService = driveService ?? DriveService()
        self.notificationCoordinator = notificationCoordinator
        self.notificationSettingsStore = notificationSettingsStore
        self.notificationSettings = notificationSettingsStore.loadSettings()
        self.telegramBotToken = notificationSettingsStore.loadBotToken()
        self.notificationStatus = .from(settings: self.notificationSettings, token: self.telegramBotToken)
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
                onCurrentFile: { [weak self] f in
                    self?.applyCurrentFile(f)
                },
                onCopyRuntimeSnapshot: { [weak self] snapshot in
                    self?.applyCopyRuntimeSnapshot(snapshot)
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
        notifyTransferStateChange(state, previousState: previousState)
    }

    internal func applyTransferProgress(_ progress: Double) {
        markRsyncRuntimeUpdate()
        self.progress = progress
        updateVerifyETA()
        if progress > 0, !didLogFirstAppliedProgress {
            didLogFirstAppliedProgress = true
            addLog(category: .progress, message: String(format: "DIAG [VIEWMODEL] First progress applied: %.1f%%", progress))
        }
    }

    internal func applyTransferSpeed(_ speed: Double) {
        markRsyncRuntimeUpdate()
        self.speed = speed
        if speed > 0, !didLogFirstAppliedSpeed {
            didLogFirstAppliedSpeed = true
            addLog(category: .progress, message: String(format: "DIAG [VIEWMODEL] First speed applied: %.2f MB/s", speed))
        }
    }

    internal func applyTransferTime(_ time: TimeInterval) {
        markRsyncRuntimeUpdate()
        self.eta = time
        if time > 0, !didLogFirstAppliedTransferTime {
            didLogFirstAppliedTransferTime = true
            addLog(category: .progress, message: "DIAG [VIEWMODEL] First rsync time applied: \(TransferRuntimeMetricPresentation.timeValue(seconds: time))")
        }
    }

    internal func applyCurrentFile(_ currentFile: String) {
        if transferState == .copying, currentFile.isEmpty, !self.currentFile.isEmpty {
            return
        }

        if !currentFile.isEmpty {
            markRsyncRuntimeUpdate()
            rsyncCurrentFile = currentFile
        }

        self.currentFile = currentFile
        if !currentFile.isEmpty, !didLogFirstAppliedCurrentFile {
            didLogFirstAppliedCurrentFile = true
            addLog(category: .file, message: "DIAG [VIEWMODEL] VIEWMODEL currentFile updated: \(currentFile)")
        }
    }

    internal func applyCopyRuntimeSnapshot(_ snapshot: CopyRuntimeSnapshot) {
        copyRuntimeSnapshot = snapshot
        copyElapsedSeconds = snapshot.elapsedSeconds

        guard transferState == .copying else { return }

        let rsyncIsUseful = progress > 0 && isRsyncRuntimeFresh(relativeTo: snapshot.lastObservedAt)
        if rsyncIsUseful {
            copyRuntimeSignalSource = snapshot.copiedBytes > 0 ? .mixed : .rsync
            logUsingRsyncMetricsIfNeeded()
            return
        }

        if let progressFraction = snapshot.progressFraction {
            progress = min(max(progressFraction * 100, 0), 99)
        }

        let displaySpeed = snapshot.currentSpeedBytesPerSecond ?? snapshot.averageSpeedBytesPerSecond
        if let displaySpeed, displaySpeed > 0 {
            speed = displaySpeed / 1_048_576.0
        }

        eta = snapshot.etaSeconds ?? 0

        if rsyncCurrentFile.isEmpty, let observedItem = snapshot.currentItem, !observedItem.isEmpty {
            currentFile = observedItem
        }

        copyRuntimeSignalSource = rsyncCurrentFile.isEmpty ? .destinationObserver : .mixed

        if !didLogUsingDestinationObserver {
            didLogUsingDestinationObserver = true
            addLog(category: .progress, message: "DIAG [VIEWMODEL] VIEWMODEL using destination observer metrics")
        }
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
        notifyJobStarted()

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
        clearCopyRuntimeMetrics()
        clearVerifyRuntimeMetrics()
        clearWorkflowPhase()
        resetRuntimeDiagnosticMarkers()
    }

    private func handleTransferStateChange(_ state: TransferState, previousState: TransferState) {
        switch state {
        case .ready:
            resetTransferMetrics()
        case .verifying:
            progress = 0.0
            clearWorkflowPhase()
            clearCopyRuntimeMetrics()
            if previousState != .verifying {
                clearVerifyRuntimeMetrics()
                beginVerifyRuntimePhase()
            }
        case .copyComplete, .safeToFormat:
            progress = 100.0
            clearWorkflowPhase()
            clearCopyRuntimeMetrics()
            clearVerifyRuntimeMetrics()
        case .error, .cancelled:
            clearWorkflowPhase()
            clearCopyRuntimeMetrics()
            clearVerifyRuntimeMetrics()
        case .validating:
            progress = 0.0
            clearCopyRuntimeMetrics()
            clearVerifyRuntimeMetrics()
            if workflowPhaseStartedAt == nil {
                beginPreparationPhase()
            }
        case .copying:
            clearWorkflowPhase()
            if previousState != .copying {
                clearCopyRuntimeMetrics()
                beginCopyRuntimePhase()
            }
        }
    }

    public func persistNotificationSettings() {
        notificationSettingsStore.saveSettings(notificationSettings)
        notificationStatus = .from(settings: notificationSettings, token: telegramBotToken)
    }

    public func persistTelegramBotToken() {
        do {
            try notificationSettingsStore.saveBotToken(telegramBotToken)
            notificationStatus = .from(settings: notificationSettings, token: telegramBotToken)
        } catch {
            notificationStatus = NotificationRuntimeStatus(
                telegramStatus: notificationSettings.isTelegramEnabled ? "Enabled" : "Disabled",
                connectionStatus: .error,
                lastMessageStatus: "Unable to save Telegram token",
                lastErrorSummary: error.localizedDescription
            )
        }
    }

    public func testTelegramNotification() {
        guard !isSendingTelegramTestMessage else { return }
        isSendingTelegramTestMessage = true

        let settings = notificationSettings
        let token = telegramBotToken
        let context = makeNotificationContext(phase: "Test")

        Task { [weak self, notificationCoordinator] in
            let status = await notificationCoordinator.sendTestMessage(
                settings: settings,
                token: token,
                context: context
            )
            await MainActor.run {
                self?.applyNotificationStatus(status)
                self?.isSendingTelegramTestMessage = false
            }
        }
    }

    private func notifyJobStarted() {
        let settings = notificationSettings
        let token = telegramBotToken
        let context = makeNotificationContext(phase: "Starting")

        Task { [weak self, notificationCoordinator] in
            if let status = await notificationCoordinator.notifyJobStarted(
                settings: settings,
                token: token,
                context: context
            ) {
                await MainActor.run {
                    self?.applyNotificationStatus(status)
                }
            }
        }
    }

    private func notifyTransferStateChange(_ state: TransferState, previousState: TransferState) {
        if state == .copying || state == .verifying {
            startNotificationHeartbeatIfNeeded()
            Task { [notificationCoordinator] in
                await notificationCoordinator.markRunningStarted()
            }
        } else {
            stopNotificationHeartbeat()
        }

        if previousState == .copying && (state == .verifying || state == .copyComplete) {
            sendCopyCompletedNotification()
        }

        switch state {
        case .safeToFormat:
            sendVerifiedSuccessNotification()
        case .error:
            sendFailureNotification()
        default:
            break
        }
    }

    private func sendCopyCompletedNotification() {
        let settings = notificationSettings
        let token = telegramBotToken
        let context = makeNotificationContext(phase: "Copy Completed", progressPercent: 100)

        Task { [weak self, notificationCoordinator] in
            if let status = await notificationCoordinator.notifyCopyCompleted(
                settings: settings,
                token: token,
                context: context
            ) {
                await MainActor.run {
                    self?.applyNotificationStatus(status)
                }
            }
        }
    }

    private func sendFailureNotification() {
        let settings = notificationSettings
        let token = telegramBotToken
        let context = makeNotificationContext(phase: "Transfer Error", failureSummary: errorMessage)

        Task { [weak self, notificationCoordinator] in
            if let status = await notificationCoordinator.notifyFailure(
                settings: settings,
                token: token,
                context: context
            ) {
                await MainActor.run {
                    self?.applyNotificationStatus(status)
                }
            }
        }
    }

    private func sendVerifiedSuccessNotification() {
        let settings = notificationSettings
        let token = telegramBotToken
        let context = makeNotificationContext(phase: "SAFE TO EJECT", progressPercent: 100)

        Task { [weak self, notificationCoordinator] in
            if let status = await notificationCoordinator.notifyVerifiedSuccess(
                settings: settings,
                token: token,
                context: context
            ) {
                await MainActor.run {
                    self?.applyNotificationStatus(status)
                }
            }
        }
    }

    private func startNotificationHeartbeatIfNeeded() {
        guard notificationHeartbeatTask == nil else { return }

        notificationHeartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                await MainActor.run {
                    self?.sendHeartbeatNotificationIfDue()
                }
            }
        }
    }

    private func stopNotificationHeartbeat() {
        notificationHeartbeatTask?.cancel()
        notificationHeartbeatTask = nil
    }

    private func sendHeartbeatNotificationIfDue() {
        guard transferState == .copying || transferState == .verifying else {
            stopNotificationHeartbeat()
            return
        }

        let settings = notificationSettings
        let token = telegramBotToken
        let context = makeNotificationContext(phase: transferState == .copying ? "Copying" : "Verifying")

        Task { [weak self, notificationCoordinator] in
            if let status = await notificationCoordinator.sendHeartbeatIfDue(
                settings: settings,
                token: token,
                context: context
            ) {
                await MainActor.run {
                    self?.applyNotificationStatus(status)
                }
            }
        }
    }

    private func makeNotificationContext(
        phase: String,
        progressPercent: Double? = nil,
        failureSummary: String? = nil
    ) -> NotificationTransferContext {
        let sourceName = sourceURL?.lastPathComponent ?? "Source Volume"
        let destinationName = destinationURL?.lastPathComponent ?? "Destination Volume"
        let elapsedSeconds = transferState == .verifying ? verifyElapsedSeconds : copyElapsedSeconds
        let displayProgress: Double
        if let progressPercent {
            displayProgress = progressPercent
        } else if transferState == .verifying, progress <= 1 {
            displayProgress = progress * 100
        } else {
            displayProgress = progress
        }

        return NotificationTransferContext(
            sourceName: sourceName,
            destinationName: destinationName,
            phase: phase,
            progressPercent: displayProgress,
            elapsedSeconds: elapsedSeconds,
            etaSeconds: eta > 0 ? eta : nil,
            failureSummary: failureSummary
        )
    }

    private func applyNotificationStatus(_ status: NotificationRuntimeStatus) {
        notificationStatus = status
        if status.connectionStatus == .error {
            addNotificationWarningIfNeeded(status.lastErrorSummary ?? status.lastMessageStatus)
        } else if status.lastMessageStatus.hasPrefix("Sent ") {
            addLog(category: .info, message: "Telegram notification: \(status.lastMessageStatus)")
        }
    }

    private func addNotificationWarningIfNeeded(_ warning: String, now: Date = Date()) {
        if lastNotificationWarningMessage == warning,
           let lastNotificationWarningLoggedAt,
           now.timeIntervalSince(lastNotificationWarningLoggedAt) < notificationWarningRepeatInterval {
            return
        }

        lastNotificationWarningMessage = warning
        lastNotificationWarningLoggedAt = now
        addLog(category: .warning, message: "Telegram notification warning: \(warning)")
    }

    private func clearCopyRuntimeMetrics() {
        if transferState != .verifying {
            stopRuntimeElapsedTimer()
        }
        speed = 0.0
        eta = 0.0
        currentFile = ""
        rsyncCurrentFile = ""
        lastRsyncRuntimeUpdateAt = nil
        copyRuntimeSnapshot = nil
        copyRuntimeSignalSource = .unavailable
        copyElapsedSeconds = 0
    }

    private func resetRuntimeDiagnosticMarkers() {
        didLogFirstAppliedProgress = false
        didLogFirstAppliedSpeed = false
        didLogFirstAppliedTransferTime = false
        didLogFirstAppliedCurrentFile = false
        didLogUsingDestinationObserver = false
        didLogUsingRsyncMetrics = false
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

    private func beginCopyRuntimePhase() {
        copyStartedAt = Date()
        copyElapsedSeconds = 0
        startRuntimeElapsedTimer()
    }

    private func beginVerifyRuntimePhase() {
        verifyStartedAt = Date()
        verifyElapsedSeconds = 0
        eta = 0.0
        startRuntimeElapsedTimer()
    }

    private func clearVerifyRuntimeMetrics() {
        if transferState != .copying {
            stopRuntimeElapsedTimer()
        }
        verifyStartedAt = nil
        verifyElapsedSeconds = 0
        eta = 0.0
    }

    private func stopRuntimeElapsedTimer() {
        runtimeElapsedTask?.cancel()
        runtimeElapsedTask = nil
        copyStartedAt = nil
        verifyStartedAt = nil
    }

    private func startRuntimeElapsedTimer() {
        runtimeElapsedTask?.cancel()
        runtimeElapsedTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    if let copyStartedAt = self.copyStartedAt, self.transferState == .copying {
                        self.copyElapsedSeconds = max(0, Int(Date().timeIntervalSince(copyStartedAt).rounded(.down)))
                    } else if let verifyStartedAt = self.verifyStartedAt, self.transferState == .verifying {
                        self.verifyElapsedSeconds = max(0, Int(Date().timeIntervalSince(verifyStartedAt).rounded(.down)))
                        self.updateVerifyETA()
                    }
                }
            }
        }
    }

    private func updateVerifyETA() {
        guard transferState == .verifying else { return }

        let progressFraction = self.progress
        guard progressFraction > 0, progressFraction < 1, progressFraction.isFinite else {
            return
        }

        guard verifyElapsedSeconds > 0 else { return }

        let remainingSeconds = Double(verifyElapsedSeconds) * (1.0 - progressFraction) / progressFraction
        self.eta = remainingSeconds
    }

    private func markRsyncRuntimeUpdate(now: Date = Date()) {
        lastRsyncRuntimeUpdateAt = now
        if transferState == .copying {
            copyRuntimeSignalSource = copyRuntimeSnapshot == nil ? .rsync : .mixed
        }
        logUsingRsyncMetricsIfNeeded()
    }

    private func isRsyncRuntimeFresh(relativeTo date: Date) -> Bool {
        guard let lastRsyncRuntimeUpdateAt else { return false }
        return date.timeIntervalSince(lastRsyncRuntimeUpdateAt) <= observerFallbackDelay
    }

    private func logUsingRsyncMetricsIfNeeded() {
        guard transferState == .copying, !didLogUsingRsyncMetrics else { return }
        didLogUsingRsyncMetrics = true
        addLog(category: .progress, message: "DIAG [VIEWMODEL] VIEWMODEL using rsync metrics")
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

#if DEBUG
    internal func setVerifyElapsedSecondsForTesting(_ seconds: Int) {
        self.verifyElapsedSeconds = seconds
        self.updateVerifyETA()
    }
#endif
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
    public static func progressTitle(for state: TransferState) -> String {
        switch state {
        case .copying:
            return "Copy Progress"
        case .verifying:
            return "Verify Progress"
        default:
            return "Transfer Progress"
        }
    }

    public static func currentFileTitle(currentFile: String, state: TransferState) -> String {
        if state == .copying && currentFile.isEmpty {
            return "CURRENT ITEM"
        }

        if state == .copying {
            return "CURRENT ITEM"
        }

        if state == .verifying {
            return "CURRENT VERIFY FILE"
        }

        return "CURRENT FILE"
    }

    public static func currentFileValue(currentFile: String, state: TransferState) -> String {
        guard currentFile.isEmpty else {
            return currentFile
        }

        if state == .copying {
            return "Waiting for first file..."
        }

        if state == .verifying {
            return "Preparing verification..."
        }

        return "-"
    }

    public static func shouldShowRsyncTime(for state: TransferState) -> Bool {
        false
    }

    public static func signalText(_ signalSource: CopyRuntimeSignalSource?) -> String {
        switch signalSource {
        case .rsync:
            return "Rsync"
        case .destinationObserver:
            return "Observed destination"
        case .mixed:
            return "Mixed"
        case .unavailable, nil:
            return "-"
        }
    }

    public static func copiedBytesValue(copiedBytes: Int64, totalBytes: Int64?) -> String {
        if let totalBytes, totalBytes > 0 {
            return "\(byteValue(copiedBytes)) / \(byteValue(totalBytes))"
        }

        guard copiedBytes > 0 else { return "-" }
        return byteValue(copiedBytes)
    }

    public static func copiedFilesValue(copiedFiles: Int, totalFiles: Int?) -> String {
        if let totalFiles, totalFiles > 0 {
            return "\(copiedFiles) / \(totalFiles)"
        }

        guard copiedFiles > 0 else { return "-" }
        return "\(copiedFiles)"
    }

    public static func speedValue(bytesPerSecond: Double?) -> String {
        guard let bytesPerSecond, bytesPerSecond > 0 else { return "-" }
        return String(format: "%.2f MB/s", bytesPerSecond / 1_048_576.0)
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

    private static func byteValue(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(max(0, bytes))
        var unitIndex = 0

        while value >= 1024, unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(value)) B"
        }

        return String(format: "%.1f %@", value, units[unitIndex])
    }
}
