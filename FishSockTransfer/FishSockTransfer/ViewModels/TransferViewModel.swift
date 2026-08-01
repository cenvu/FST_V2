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

// MARK: - FR-003 bookmark persistence and access-lease vocabulary
//
// Defined here (not in BookmarkService.swift) so TransferViewModel and its
// deterministic tests never need to reference the concrete BookmarkService
// actor's own compilation unit. BookmarkService.swift conforms to these
// protocols and remains the sole place that calls real macOS bookmark and
// security-scope APIs.

public enum BookmarkRole: String, Sendable {
    case source
    case destination
}

public enum BookmarkResolution: Sendable, Equatable {
    /// No bookmark was ever saved for this role — a normal "nothing to
    /// restore" result, not an error.
    case none
    case usable(url: URL, wasStale: Bool)
    /// Stored data exists but could not be resolved (malformed/corrupt).
    case corrupt
}

public enum BookmarkAccessResult: Sendable, Equatable {
    case started
    /// The OS-level access attempt itself did not succeed. This alone is not
    /// proof the URL is unusable — callers must still validate.
    case failedToStart
    /// A newer generation already claimed this role while this attempt was
    /// in flight. Any access acquired by this attempt has already been
    /// released; the caller must not apply this result.
    case superseded
}

/// Save/resolve/refresh/remove one app-scoped bookmark per role. Implemented
/// by `BookmarkService` in production; deterministic tests inject a fake.
/// `nonisolated` on every requirement: this project defaults unannotated
/// declarations to `@MainActor` isolation, but conforming types are actors
/// with their own isolation (or plain Sendable value types with none) — never
/// MainActor — so the requirements themselves must opt out explicitly.
public protocol BookmarkPersisting: Sendable {
    nonisolated func saveBookmark(for url: URL, role: BookmarkRole, generation: Int) async -> Bool
    nonisolated func resolveBookmark(for role: BookmarkRole) async -> BookmarkResolution
    nonisolated func refreshBookmark(for url: URL, role: BookmarkRole, generation: Int) async -> Bool
    nonisolated func removeBookmark(for role: BookmarkRole, generation: Int) async
}

/// Raw, role-agnostic security-scope syscalls. Implemented by
/// `BookmarkService` in production (wrapping `URL.startAccessingSecurityScopedResource`);
/// deterministic tests inject a fake, optionally gated, to make lease races
/// reproducible without any wall-clock wait.
public protocol SecurityScopedAccessing: Sendable {
    nonisolated func startAccessing(_ url: URL) async -> Bool
    nonisolated func stopAccessing(_ url: URL) async
}

/// Inert default so every existing call site that does not care about
/// bookmarks (nearly all current tests, and `TransferViewModel()` used in
/// isolation) gets harmless no-op behavior with zero UserDefaults or
/// security-scope interaction.
public nonisolated struct NullBookmarkPersistence: BookmarkPersisting {
    public init() {}
    public func saveBookmark(for url: URL, role: BookmarkRole, generation: Int) async -> Bool { false }
    public func resolveBookmark(for role: BookmarkRole) async -> BookmarkResolution { .none }
    public func refreshBookmark(for url: URL, role: BookmarkRole, generation: Int) async -> Bool { false }
    public func removeBookmark(for role: BookmarkRole, generation: Int) async {}
}

public nonisolated struct NullSecurityScopedAccessProvider: SecurityScopedAccessing {
    public init() {}
    public func startAccessing(_ url: URL) async -> Bool { false }
    public func stopAccessing(_ url: URL) async {}
}

/// Owns the single active security-scope access lease per role and makes
/// restore-vs-Select/Clear races deterministic: every attempt is tagged with
/// the caller's monotonic `generation` (bumped by the ViewModel on every
/// Select/Clear). Whichever generation is highest always wins a role's
/// tracked lease, regardless of which call's underlying syscall happens to
/// return first, and a call that loses immediately releases whatever it just
/// acquired. No sleeps, polling, or timeouts are involved.
public actor BookmarkAccessCoordinator {
    private let accessProvider: SecurityScopedAccessing
    private var activeLeases: [BookmarkRole: (url: URL, generation: Int)] = [:]

    public init(accessProvider: SecurityScopedAccessing) {
        self.accessProvider = accessProvider
    }

    @discardableResult
    public func beginAccess(for url: URL, role: BookmarkRole, generation: Int) async -> BookmarkAccessResult {
        if let current = activeLeases[role], current.generation > generation {
            return .superseded
        }

        // Re-selecting the same folder does not require another OS start call.
        // Promote the existing lease to the newer generation without creating
        // an unbalanced security-scope reference.
        if let current = activeLeases[role], current.url == url {
            activeLeases[role] = (url, generation)
            return .started
        }

        let started = await accessProvider.startAccessing(url)

        if let current = activeLeases[role], current.generation > generation {
            // A newer request won this role while the syscall was in flight.
            if started {
                await accessProvider.stopAccessing(url)
            }
            return .superseded
        }

        guard started else { return .failedToStart }

        if let current = activeLeases[role] {
            if current.url == url {
                // Another same-URL attempt acquired a redundant reference
                // while this call was suspended. Release only this attempt.
                if started { await accessProvider.stopAccessing(url) }
                if current.generation < generation {
                    activeLeases[role] = (url, generation)
                }
                return .started
            }
            await accessProvider.stopAccessing(current.url)
        }
        activeLeases[role] = (url, generation)
        return .started
    }

    /// Releases access for `role` only when `url`/`generation` still match
    /// the lease FST currently owns for that role — a stale or already
    /// superseded caller can never release a newer, still-active lease.
    public func endAccess(for role: BookmarkRole, url: URL, generation: Int) async {
        guard let current = activeLeases[role], current.url == url, current.generation == generation else { return }
        await accessProvider.stopAccessing(url)
        activeLeases[role] = nil
    }

    /// Releases every lease FST currently owns, regardless of role or
    /// generation. Used only when the owning ViewModel is being torn down.
    public func endAllAccess() async {
        for (role, lease) in activeLeases {
            await accessProvider.stopAccessing(lease.url)
            activeLeases[role] = nil
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
    private let bookmarkPersistence: BookmarkPersisting
    private let bookmarkAccessCoordinator: BookmarkAccessCoordinator
    private let notificationCoordinator: NotificationCoordinator
    private let notificationSettingsStore: NotificationSettingsStore
    private var callbacksConfiguredTask: Task<Void, Never>?
    private var sourceMetadataTask: Task<Void, Never>?
    private var destinationMetadataTask: Task<Void, Never>?
    private var sourceRestoreTask: Task<Void, Never>?
    private var destinationRestoreTask: Task<Void, Never>?
    private var sourceBookmarkTask: Task<Void, Never>?
    private var destinationBookmarkTask: Task<Void, Never>?
    /// Bumped by every Select/Clear for its role. Captured by an in-flight
    /// restore before any suspension point; the restore drops its result
    /// without applying it if the live counter has since moved on. Also
    /// threaded through to `BookmarkAccessCoordinator` as the access-lease
    /// generation, so a stale restore's security-scope acquisition can never
    /// clobber a newer Select/Clear's lease regardless of scheduling order.
    private var sourceSelectionGeneration = 0
    private var destinationSelectionGeneration = 0
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
        bookmarkPersistence: BookmarkPersisting = NullBookmarkPersistence(),
        bookmarkAccessProvider: SecurityScopedAccessing = NullSecurityScopedAccessProvider(),
        notificationCoordinator: NotificationCoordinator = NotificationCoordinator(),
        notificationSettingsStore: NotificationSettingsStore = NotificationSettingsStore()
    ) {
        self.bundledRsyncService = bundledRsyncService
        self.coordinator = coordinator ?? TransferCoordinator(bundledRsyncService: bundledRsyncService)
        self.driveService = driveService ?? DriveService()
        self.bookmarkPersistence = bookmarkPersistence
        self.bookmarkAccessCoordinator = BookmarkAccessCoordinator(accessProvider: bookmarkAccessProvider)
        self.notificationCoordinator = notificationCoordinator
        self.notificationSettingsStore = notificationSettingsStore
        self.notificationSettings = notificationSettingsStore.loadSettings()
        self.telegramBotToken = notificationSettingsStore.loadBotToken()
        self.notificationStatus = .from(settings: self.notificationSettings, token: self.telegramBotToken)
        setupBindings()
        refreshBundledRsyncInfo()
        restorePersistedFolders()
    }

    deinit {
        let bookmarkAccessCoordinator = bookmarkAccessCoordinator
        Task { await bookmarkAccessCoordinator.endAllAccess() }
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

        sourceRestoreTask?.cancel()
        let releasingGeneration = sourceSelectionGeneration
        let releasingURL = sourceURL
        sourceSelectionGeneration += 1
        let generation = sourceSelectionGeneration

        sourceURL = url
        sourceMetadata = nil
        refreshSourceMetadata(for: url)
        errorMessage = nil

        persistSelection(url, role: .source, generation: generation, releasingURL: releasingURL, releasingGeneration: releasingGeneration)
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

        destinationRestoreTask?.cancel()
        let releasingGeneration = destinationSelectionGeneration
        let releasingURL = destinationURL
        destinationSelectionGeneration += 1
        let generation = destinationSelectionGeneration

        destinationURL = url
        destinationMetadata = nil
        refreshDestinationMetadata(for: url)
        errorMessage = nil

        persistSelection(url, role: .destination, generation: generation, releasingURL: releasingURL, releasingGeneration: releasingGeneration)
        return true
    }

    /// Saves the bookmark for the newly accepted `url` under `role`, acquires
    /// its access lease under `generation`, and releases the previously held
    /// lease (if any and if different) under its own older generation. Fire
    /// and forget from the ViewModel's perspective: a save/access failure is
    /// visible through `errorMessage`/logs but never un-accepts an otherwise
    /// valid current selection.
    private func persistSelection(
        _ url: URL,
        role: BookmarkRole,
        generation: Int,
        releasingURL: URL?,
        releasingGeneration: Int
    ) {
        let bookmarkPersistence = bookmarkPersistence
        let bookmarkAccessCoordinator = bookmarkAccessCoordinator
        let task = Task { [weak self] in
            let isStillCurrent = await MainActor.run { () -> Bool in
                guard let self else { return false }
                let current = role == .source ? self.sourceSelectionGeneration : self.destinationSelectionGeneration
                return current == generation
            }
            guard isStillCurrent else { return }

            let saved = await bookmarkPersistence.saveBookmark(for: url, role: role, generation: generation)
            let remainsCurrentAfterSave = await MainActor.run { () -> Bool in
                guard let self else { return false }
                let current = role == .source ? self.sourceSelectionGeneration : self.destinationSelectionGeneration
                return current == generation
            }
            guard remainsCurrentAfterSave else { return }

            let accessResult = await bookmarkAccessCoordinator.beginAccess(for: url, role: role, generation: generation)
            let remainsCurrentAfterAccess = await MainActor.run { () -> Bool in
                guard let self else { return false }
                let current = role == .source ? self.sourceSelectionGeneration : self.destinationSelectionGeneration
                return current == generation
            }
            guard remainsCurrentAfterAccess else {
                if accessResult == .started {
                    await bookmarkAccessCoordinator.endAccess(for: role, url: url, generation: generation)
                }
                return
            }

            if let releasingURL, releasingURL != url {
                await bookmarkAccessCoordinator.endAccess(for: role, url: releasingURL, generation: releasingGeneration)
            }
            guard !saved else { return }
            await MainActor.run {
                guard let self else { return }
                let currentGeneration = role == .source ? self.sourceSelectionGeneration : self.destinationSelectionGeneration
                guard currentGeneration == generation else { return }
                let roleName = role == .source ? "Source" : "Destination"
                self.errorMessage = "Could not save \(roleName) access for next launch."
                self.addLog(category: .warning, message: "Failed to save \(roleName) bookmark for relaunch restoration.")
            }
        }
        switch role {
        case .source: sourceBookmarkTask = task
        case .destination: destinationBookmarkTask = task
        }
    }

    /// Removes the selected Source from FST only.
    ///
    /// Cancels any in-flight Source metadata/restore task, clears the
    /// selected URL, Source metadata, and Source-derived validation state,
    /// releases the owned Source security-scope lease exactly once, removes
    /// the persisted Source bookmark, then recomputes Start eligibility. The
    /// real folder on disk is never deleted, moved, renamed, or modified.
    /// Transfer logs, terminal reports, notification history, and
    /// Destination selection are untouched.
    public func clearSourceFolder() {
        guard !isTransferConfigurationLocked else { return }
        sourceRestoreTask?.cancel()
        sourceMetadataTask?.cancel()
        sourceMetadataTask = nil
        let releasingGeneration = sourceSelectionGeneration
        let releasingURL = sourceURL
        sourceSelectionGeneration += 1
        sourceURL = nil
        sourceMetadata = nil
        refreshStorageWarning()
        errorMessage = nil
        releasePersistedSelection(role: .source, releasingURL: releasingURL, releasingGeneration: releasingGeneration, removalGeneration: sourceSelectionGeneration)
    }

    /// Removes the selected Destination from FST only.
    ///
    /// Cancels any in-flight Destination metadata/restore task, clears the
    /// selected URL, Destination metadata, free-space information, and
    /// destination-derived warnings, releases the owned Destination
    /// security-scope lease exactly once, removes the persisted Destination
    /// bookmark, then recomputes Start eligibility. The real folder or volume
    /// on disk is never deleted, moved, renamed, formatted, or modified.
    /// Transfer logs, terminal reports, notification history, and Source
    /// selection are untouched.
    public func clearDestinationFolder() {
        guard !isTransferConfigurationLocked else { return }
        destinationRestoreTask?.cancel()
        destinationMetadataTask?.cancel()
        destinationMetadataTask = nil
        let releasingGeneration = destinationSelectionGeneration
        let releasingURL = destinationURL
        destinationSelectionGeneration += 1
        destinationURL = nil
        destinationMetadata = nil
        refreshStorageWarning()
        errorMessage = nil
        releasePersistedSelection(role: .destination, releasingURL: releasingURL, releasingGeneration: releasingGeneration, removalGeneration: destinationSelectionGeneration)
    }

    private func releasePersistedSelection(role: BookmarkRole, releasingURL: URL?, releasingGeneration: Int, removalGeneration: Int) {
        let bookmarkPersistence = bookmarkPersistence
        let bookmarkAccessCoordinator = bookmarkAccessCoordinator
        Task {
            if let releasingURL {
                await bookmarkAccessCoordinator.endAccess(for: role, url: releasingURL, generation: releasingGeneration)
            }
            await bookmarkPersistence.removeBookmark(for: role, generation: removalGeneration)
        }
    }

    /// One explicit, idempotent relaunch-restoration entry point (FR-003).
    /// Calling it more than once returns the same in-flight/completed tasks
    /// rather than starting new ones. Source and Destination restore through
    /// two independent tasks so one role's failure or delay can never affect
    /// the other. Never starts a transfer and never reuses persisted
    /// metadata — restored folders go through the normal metadata refresh
    /// path exactly like a fresh manual selection.
    @discardableResult
    public func restorePersistedFolders() -> (source: Task<Void, Never>, destination: Task<Void, Never>) {
        let sourceTask: Task<Void, Never>
        if let existing = sourceRestoreTask {
            sourceTask = existing
        } else {
            let generation = sourceSelectionGeneration
            let task = Task { [weak self] in
                guard let self else { return }
                await self.restoreSourceFolder(expectedGeneration: generation)
            }
            sourceRestoreTask = task
            sourceTask = task
        }

        let destinationTask: Task<Void, Never>
        if let existing = destinationRestoreTask {
            destinationTask = existing
        } else {
            let generation = destinationSelectionGeneration
            let task = Task { [weak self] in
                guard let self else { return }
                await self.restoreDestinationFolder(expectedGeneration: generation)
            }
            destinationRestoreTask = task
            destinationTask = task
        }

        return (sourceTask, destinationTask)
    }

    private func restoreSourceFolder(expectedGeneration: Int) async {
        let bookmarkPersistence = bookmarkPersistence
        let bookmarkAccessCoordinator = bookmarkAccessCoordinator
        let resolved = await bookmarkPersistence.resolveBookmark(for: .source)

        switch resolved {
        case .none:
            return

        case .corrupt:
            await bookmarkPersistence.removeBookmark(for: .source, generation: expectedGeneration)
            guard sourceSelectionGeneration == expectedGeneration else { return }
            errorMessage = "Saved Source access could not be restored. Choose the Source folder again."
            addLog(category: .warning, message: "Saved Source bookmark data was corrupt and has been removed.")

        case .usable(let url, let wasStale):
            await bookmarkAccessCoordinator.beginAccess(for: url, role: .source, generation: expectedGeneration)

            do {
                try await driveService.validateSource(at: url)
            } catch {
                await bookmarkAccessCoordinator.endAccess(for: .source, url: url, generation: expectedGeneration)
                await bookmarkPersistence.removeBookmark(for: .source, generation: expectedGeneration)
                guard sourceSelectionGeneration == expectedGeneration else { return }
                errorMessage = "Saved Source access could not be restored. Choose the Source folder again."
                addLog(category: .warning, message: "Restored Source folder is no longer usable: \(error.localizedDescription)")
                return
            }

            if wasStale {
                let refreshed = await bookmarkPersistence.refreshBookmark(for: url, role: .source, generation: expectedGeneration)
                guard refreshed else {
                    await bookmarkAccessCoordinator.endAccess(for: .source, url: url, generation: expectedGeneration)
                    await bookmarkPersistence.removeBookmark(for: .source, generation: expectedGeneration)
                    guard sourceSelectionGeneration == expectedGeneration else { return }
                    errorMessage = "Saved Source access could not be restored. Choose the Source folder again."
                    addLog(category: .warning, message: "Stale Source bookmark could not be refreshed.")
                    return
                }
            }

            guard sourceSelectionGeneration == expectedGeneration else {
                await bookmarkAccessCoordinator.endAccess(for: .source, url: url, generation: expectedGeneration)
                return
            }
            sourceURL = url
            refreshSourceMetadata(for: url)
        }
    }

    private func restoreDestinationFolder(expectedGeneration: Int) async {
        let bookmarkPersistence = bookmarkPersistence
        let bookmarkAccessCoordinator = bookmarkAccessCoordinator
        let resolved = await bookmarkPersistence.resolveBookmark(for: .destination)

        switch resolved {
        case .none:
            return

        case .corrupt:
            await bookmarkPersistence.removeBookmark(for: .destination, generation: expectedGeneration)
            guard destinationSelectionGeneration == expectedGeneration else { return }
            errorMessage = "Saved Destination access could not be restored. Choose the Destination folder again."
            addLog(category: .warning, message: "Saved Destination bookmark data was corrupt and has been removed.")

        case .usable(let url, let wasStale):
            await bookmarkAccessCoordinator.beginAccess(for: url, role: .destination, generation: expectedGeneration)

            do {
                try await driveService.validateDestination(at: url)
            } catch {
                await bookmarkAccessCoordinator.endAccess(for: .destination, url: url, generation: expectedGeneration)
                await bookmarkPersistence.removeBookmark(for: .destination, generation: expectedGeneration)
                guard destinationSelectionGeneration == expectedGeneration else { return }
                errorMessage = "Saved Destination access could not be restored. Choose the Destination folder again."
                addLog(category: .warning, message: "Restored Destination folder is no longer usable: \(error.localizedDescription)")
                return
            }

            if wasStale {
                let refreshed = await bookmarkPersistence.refreshBookmark(for: url, role: .destination, generation: expectedGeneration)
                guard refreshed else {
                    await bookmarkAccessCoordinator.endAccess(for: .destination, url: url, generation: expectedGeneration)
                    await bookmarkPersistence.removeBookmark(for: .destination, generation: expectedGeneration)
                    guard destinationSelectionGeneration == expectedGeneration else { return }
                    errorMessage = "Saved Destination access could not be restored. Choose the Destination folder again."
                    addLog(category: .warning, message: "Stale Destination bookmark could not be refreshed.")
                    return
                }
            }

            guard destinationSelectionGeneration == expectedGeneration else {
                await bookmarkAccessCoordinator.endAccess(for: .destination, url: url, generation: expectedGeneration)
                return
            }
            destinationURL = url
            refreshDestinationMetadata(for: url)
        }
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
                let kibPerSecond = RsyncBandwidthLimit.kibPerSecond(for: bandwidthLimit)
                _ = try RsyncBandwidthLimit.validate(kibPerSecond: kibPerSecond)
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

        let bandwidthLimitKiB = bandwidthLimit.map { RsyncBandwidthLimit.kibPerSecond(for: $0) }
        let callbacksConfiguredTask = callbacksConfiguredTask

        // TransferState is Coordinator-owned. No state is asserted here: the
        // Coordinator publishes the real `.validating` transition itself the
        // instant it admits this request. One immediate admission attempt is
        // made with the Source, Destination, bandwidth, and verification mode
        // current right now — no retry loop, no delay, no stale capture. If
        // admission is rejected, nothing here changes: the current state and
        // configuration are left exactly as they were, and the operator may
        // press Retry again.
        Task { [coordinator, sourceURL, destinationURL, bandwidthLimitKiB, verificationMode, callbacksConfiguredTask] in
            await callbacksConfiguredTask?.value
            await coordinator.startTransfer(
                source: sourceURL,
                destination: destinationURL,
                bandwidthLimit: bandwidthLimitKiB,
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
            let kibPerSecond = RsyncBandwidthLimit.kibPerSecond(for: bandwidthLimit)
            _ = try RsyncBandwidthLimit.validate(kibPerSecond: kibPerSecond)
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
                    // URL-identity guard: a stale task must never repopulate a
                    // cleared or re-selected Source.
                    guard self?.sourceURL == url else { return }
                    self?.sourceMetadata = metadata
                    self?.refreshStorageWarning()
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    guard self?.sourceURL == url else { return }
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
                    // URL-identity guard: a stale task must never repopulate a
                    // cleared or re-selected Destination.
                    guard self?.destinationURL == url else { return }
                    self?.destinationMetadata = metadata
                    self?.refreshStorageWarning()
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    guard self?.destinationURL == url else { return }
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

    // Lets deterministic tests await the in-flight metadata tasks to prove a
    // stale completion can never repopulate a cleared folder selection.
    internal var sourceMetadataTaskForTesting: Task<Void, Never>? { sourceMetadataTask }
    internal var destinationMetadataTaskForTesting: Task<Void, Never>? { destinationMetadataTask }

    // Lets deterministic tests await bookmark persistence/restoration work.
    internal var sourceRestoreTaskForTesting: Task<Void, Never>? { sourceRestoreTask }
    internal var destinationRestoreTaskForTesting: Task<Void, Never>? { destinationRestoreTask }
    internal var sourceBookmarkTaskForTesting: Task<Void, Never>? { sourceBookmarkTask }
    internal var destinationBookmarkTaskForTesting: Task<Void, Never>? { destinationBookmarkTask }
    internal var sourceSelectionGenerationForTesting: Int { sourceSelectionGeneration }
    internal var destinationSelectionGenerationForTesting: Int { destinationSelectionGeneration }
#endif
}

/// Single source of truth for the main action button label per state.
/// SwiftUI-free so the canonical XCTest module (which compiles the ViewModel
/// but not the Views) can pin the presentation contract deterministically.
nonisolated public enum TransferActionPresentation {
    public static func title(for state: TransferState, canStartTransfer: Bool = false) -> String {
        if state == .cancelled, canStartTransfer {
            return "START NEW TRANSFER"
        }

        if state == .error, canStartTransfer {
            return "RETRY"
        }

        switch state {
        case .ready:
            return "START"
        case .validating:
            return "PREPARING TRANSFER"
        case .copying, .verifying:
            return "CANCEL"
        case .copyComplete:
            return "TRANSFER COMPLETE"
        case .safeToFormat:
            return "SAFE TO EJECT"
        case .error:
            return "TRANSFER ERROR"
        case .cancelled:
            return "CANCELLED"
        }
    }

    public static func actionIcon(for state: TransferState, canStartTransfer: Bool = false) -> String? {
        if state == .error, canStartTransfer {
            return "arrow.clockwise"
        }
        return nil
    }

    public static func accessibilityLabel(for state: TransferState, canStartTransfer: Bool = false) -> String? {
        if state == .error, canStartTransfer {
            return "Retry Transfer"
        }
        return nil
    }

    /// True only for states whose active workflow has a real cancellation
    /// path (copying and verifying). Validation has no cancellable task, so
    /// it is deliberately excluded.
    public static func isActiveCancellableState(_ state: TransferState) -> Bool {
        state == .copying || state == .verifying
    }
}

/// Smallest View/UI-layer guard that allows exactly one cancellation request
/// per active workflow. Confirmation is a View concern; this type only
/// records that a confirmed cancellation request was sent so the Cancel
/// button disables and no duplicate request can reach the ViewModel. It
/// resets automatically when the workflow leaves the active states.
nonisolated public struct TransferCancelRequestGuard {
    public private(set) var isCancellationRequested = false

    public init() {}

    /// Records the single confirmed cancellation request for this workflow.
    public mutating func confirmCancellationRequest() {
        isCancellationRequested = true
    }

    /// Resets the guard when the workflow leaves `.copying`/`.verifying`, so
    /// a future workflow (or a new transfer) can cancel again.
    public mutating func reset(for state: TransferState) {
        if state != .copying, state != .verifying {
            isCancellationRequested = false
        }
    }

    /// True only in active cancellable states with no request already sent.
    public func allowsNewCancellationRequest(for state: TransferState) -> Bool {
        guard TransferActionPresentation.isActiveCancellableState(state) else { return false }
        return !isCancellationRequested
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
