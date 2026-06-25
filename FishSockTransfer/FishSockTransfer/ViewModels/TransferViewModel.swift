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
                    self?.transferState = state
                    self?.handleTransferStateChange(state)
                },
                onProgress: { [weak self] p in
                    self?.progress = p
                },
                onSpeed: { [weak self] s in
                    self?.speed = s
                },
                onETA: { [weak self] e in
                    self?.eta = e
                },
                onCurrentFile: { [weak self] f in
                    self?.currentFile = f
                },
                onError: { [weak self] message in
                    self?.errorMessage = message
                    self?.addLog(category: .error, message: message)
                },
                onLog: { [weak self] entry in
                    self?.appendLog(entry)
                }
            )
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
        errorMessage = nil
        addLog(category: .info, message: "Starting transfer workflow")
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
        speed = 0.0
        eta = 0.0
        currentFile = ""
    }

    private func handleTransferStateChange(_ state: TransferState) {
        switch state {
        case .ready:
            resetTransferMetrics()
        case .verifying:
            progress = 0.0
            clearCopyRuntimeMetrics()
        case .copyComplete, .safeToFormat:
            progress = 100.0
            clearCopyRuntimeMetrics()
        case .error, .cancelled:
            clearCopyRuntimeMetrics()
        case .validating, .copying:
            break
        }
    }

    private func clearCopyRuntimeMetrics() {
        speed = 0.0
        eta = 0.0
        currentFile = ""
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
