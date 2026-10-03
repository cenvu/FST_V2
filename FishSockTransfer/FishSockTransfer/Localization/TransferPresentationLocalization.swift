
import Foundation

/// String Catalog lookup for known, computed operator-facing Transfer text.
/// Unknown runtime strings pass through untouched.
public enum TransferPresentationLocalization {
    private static let knownKeys: Set<String> = Set(TransferPresentationKey.allCases.map(\.rawValue))

    public static func text(_ english: String, locale: Locale, bundle: Bundle = .main) -> String {
        guard knownKeys.contains(english) else { return english }
        return StringCatalogPresentationLookup.text(english, locale: locale, bundle: bundle)
    }

    public static func sourcePathLabel(_ path: String, locale: Locale, bundle: Bundle = .main) -> String {
        "\(text("Source path:", locale: locale, bundle: bundle)) \(path)"
    }

    public static func destinationPathLabel(_ path: String, locale: Locale, bundle: Bundle = .main) -> String {
        "\(text("Destination path:", locale: locale, bundle: bundle)) \(path)"
    }

    public static func destinationTargetPreview(_ preview: String, locale: Locale, bundle: Bundle = .main) -> String {
        let prefix = "Will create: "
        guard preview.hasPrefix(prefix) else { return preview }
        let pathSuffix = String(preview.dropFirst(prefix.count))
        return "\(text("Will create:", locale: locale, bundle: bundle)) \(pathSuffix)"
    }

    public static func reportStatus(_ status: String, locale: Locale, bundle: Bundle = .main) -> String {
        let wrappers = ["Report saved:", "Report warning:"]
        for wrapper in wrappers {
            let prefix = wrapper + " "
            guard status.hasPrefix(prefix) else { continue }
            let suffix = String(status.dropFirst(prefix.count))
            return "\(text(wrapper, locale: locale, bundle: bundle)) \(suffix)"
        }
        return text(status, locale: locale, bundle: bundle)
    }

    public static func remainingTime(_ value: String, locale: Locale, bundle: Bundle = .main) -> String {
        let suffix = " remaining"
        guard value.hasSuffix(suffix) else { return text(value, locale: locale, bundle: bundle) }
        let duration = String(value.dropLast(suffix.count))
        return "\(duration) \(text("remaining", locale: locale, bundle: bundle))"
    }
}

/// Shared String Catalog lookup for allowlisted, computed presentation text.
/// Callers must bound keys before reaching this locale-resolution primitive.
private enum StringCatalogPresentationLookup {
    static func text(_ english: String, locale: Locale, bundle: Bundle) -> String {
        let languageCode = locale.identifier
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init) ?? locale.identifier
        guard languageCode == "vi",
              let localizationPath = bundle.path(forResource: languageCode, ofType: "lproj"),
              let localizationBundle = Bundle(path: localizationPath) else {
            // English is the catalog source language and the safe fallback.
            return english
        }
        return String(
            localized: String.LocalizationValue(stringLiteral: english),
            table: "Localizable",
            bundle: localizationBundle,
            locale: locale
        )
    }
}

/// Bounded EN/VI presentation for known strings outside the Transfer flow.
/// Runtime strings not explicitly listed below pass through unchanged.
public enum L2PresentationLocalization {
    private static let knownKeys = Set(L2PresentationKey.allCases.map(\.rawValue))

    public static func text(_ english: String, locale: Locale, bundle: Bundle = .main) -> String {
        guard knownKeys.contains(english) else { return english }
        return StringCatalogPresentationLookup.text(english, locale: locale, bundle: bundle)
    }

    public static func logEntrySummary(visible: Int, total: Int, locale: Locale, bundle: Bundle = .main) -> String {
        let format = text("%1$d visible / %2$d total entries", locale: locale, bundle: bundle)
        return String(format: format, locale: locale, arguments: [visible, total])
    }

    public static func updateAvailable(version: String, locale: Locale, bundle: Bundle = .main) -> String {
        let format = text("Update available: v%@", locale: locale, bundle: bundle)
        return String(format: format, locale: locale, arguments: [version])
    }

    /// Preserves the existing diagnostic classification and returns its
    /// canonical English status for display-layer localization.
    public static func bundledRsyncStatus(isAvailable: Bool, version: String, firstDiagnostic: String) -> String {
        guard !isAvailable else {
            return "Bundled rsync \(version)"
        }
        if firstDiagnostic.localizedCaseInsensitiveContains("not executable") {
            return "Bundled rsync not executable"
        }
        if firstDiagnostic.localizedCaseInsensitiveContains("missing") {
            return "Bundled rsync missing"
        }
        if firstDiagnostic.localizedCaseInsensitiveContains("version mismatch") {
            return "Bundled rsync wrong version \(version)"
        }
        if firstDiagnostic.localizedCaseInsensitiveContains("timed out") {
            return "Bundled rsync timeout"
        }
        if firstDiagnostic.localizedCaseInsensitiveContains("unrecognized") {
            return "Bundled rsync invalid"
        }
        return "Bundled rsync unavailable"
    }

    /// Localizes the known visible rsync status while preserving an available
    /// or mismatched version suffix byte-for-byte.
    public static func rsyncStatusValue(
        _ englishStatus: String,
        isAvailable: Bool,
        locale: Locale,
        bundle: Bundle = .main
    ) -> String {
        let prefix = "Bundled rsync "
        guard englishStatus.hasPrefix(prefix) else { return englishStatus }
        let value = String(englishStatus.dropFirst(prefix.count))
        if isAvailable {
            return value.isEmpty ? englishStatus : value
        }

        let wrongVersionPrefix = "wrong version "
        if value.hasPrefix(wrongVersionPrefix) {
            let version = String(value.dropFirst(wrongVersionPrefix.count))
            guard !version.isEmpty else { return englishStatus }
            let format = text("wrong version %@", locale: locale, bundle: bundle)
            return String(format: format, locale: locale, arguments: [version])
        }
        guard ["missing", "not executable", "timeout", "invalid", "unavailable"].contains(value) else {
            return englishStatus
        }
        return text(value, locale: locale, bundle: bundle)
    }
}

private enum L2PresentationKey: String, CaseIterable {
    case notifications = "Notifications"
    case notificationSubtitle = "Optional · best-effort · separate from job safety"
    case telegramSetup = "Telegram Setup"
    case notificationDeliverySummary = "Notification delivery never changes transfer or verification results."
    case enableTelegramNotification = "Enable Telegram Notification"
    case botToken = "Bot Token"
    case tokenKeychainHelp = "Stored in Keychain. The token is not shown in plain text."
    case chatID = "Chat ID"
    case testMessage = "Test Message"
    case telegramBestEffortSummary = "Telegram notification is optional and best-effort. It never changes transfer, verify, report, or SAFE TO EJECT results."
    case notifyEvents = "Notify Events"
    case jobStarts = "Job starts"
    case heartbeatWhileRunning = "Heartbeat while running"
    case transferFails = "Transfer fails"
    case copyCompleted = "Copy completed"
    case verifyCompletedSafeToEject = "Verify completed / Safe to eject"
    case heartbeatInterval = "Heartbeat Interval"
    case messageDetail = "Message Detail"
    case notificationStatus = "Notification Status"
    case telegramStatus = "Telegram status"
    case connectionStatus = "Connection status"
    case lastMessage = "Last message"
    case lastError = "Last error"
    case messagePreview = "Message Preview"
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case compact = "Compact"
    case standard = "Standard"
    case disabled = "Disabled"
    case notConfigured = "Not Configured"
    case enabled = "Enabled"
    case notTested = "Not Tested"
    case ready = "Ready"
    case error = "Error"
    case noMessagesSent = "No messages sent"
    case technicalLog = "Technical Log"
    case operationalLogSubtitle = "Operational runtime log · Diagnostics optional"
    case showDiagnostics = "Show Diagnostics"
    case showDiagnosticsHelp = "Show or hide diagnostic entries in the log view."
    case autoScroll = "Auto-scroll"
    case autoScrollHelp = "Automatically scroll to the newest log entries."
    case copyAllLogs = "Copy All Logs"
    case copyAllLogsHelp = "Copies the complete retained log history, including diagnostic entries."
    case logDetails = "Log details"
    case logDetailsHelp = "Open a selectable view of the complete log history."
    case checkForUpdate = "Check for Update"
    case copyLogsSuccess = "All log entries copied to the clipboard, including diagnostics."
    case copyLogsFailure = "Could not copy logs to the clipboard. Please try again."
    case fullLogHistory = "Full log history"
    case fullLogHistoryDescription = "All currently retained runtime log entries are shown here, including diagnostics."
    case close = "Close"
    case autoScrollActive = "Auto-scroll active"
    case logEntrySummary = "%1$d visible / %2$d total entries"
    case filteringNotice = "Filtering does not change the complete log."
    case noLogEntries = "No log entries yet"
    case startJobEmptyState = "Select source and destination, then start a job."
    case version = "version"
    case bundledRsync = "bundled rsync"
    case license = "license"
    case appVersionHelp = "App version from README.md"
    case bundledRsyncHelp = "Bundled rsync version used by FST"
    case licenseHelp = "Project license from README.md"
    case checking = "Checking..."
    case upToDate = "Up to date"
    case updateAvailable = "Update available: v%@"
    case viewRelease = "View Release"
    case download = "Download"
    case updateCheckFailed = "Update check failed"
    case checkForUpdates = "Check for Updates"
    case updatesDisabledWhileRunning = "Update checks are disabled while transfer or verification is running."
    case checkGitHubRelease = "Check GitHub for the latest release"
    case rsyncMissing = "missing"
    case rsyncNotExecutable = "not executable"
    case rsyncWrongVersion = "wrong version %@"
    case rsyncTimeout = "timeout"
    case rsyncInvalid = "invalid"
    case rsyncUnavailable = "unavailable"
    case openCenVuFacebook = "Open CenVu Facebook"
    case openCenVuInstagram = "Open CenVu Instagram"
    case messageCenVuWhatsApp = "Message CenVu on WhatsApp"
    case messageCenVuTelegram = "Message CenVu on Telegram"
}

/// English source keys shared by the String Catalog and the bounded dynamic
/// lookup above. Translation text lives only in Localizable.xcstrings.
private enum TransferPresentationKey: String, CaseIterable {
    case sourcePath = "Source path:"
    case destinationPath = "Destination path:"
    case destinationTargetPreview = "Destination target preview:"
    case willCreate = "Will create:"
    case reportSaved = "Report saved:"
    case reportWarning = "Report warning:"
    case reportSkipped = "Report skipped: no report was written because the destination was unsafe for report output."
    case unavailable = "Unavailable"
    case percent = "percent"
    case unlimited = "Unlimited"
    case copyOnly = "COPY ONLY — Fastest"
    case sample33 = "SAMPLE 33% — Balanced"
    case full100 = "FULL 100% — Verify all files"
    case copyOnlyDescription = "Copy only. No hash verification by FST."
    case sample33Description = "SHA256 sample verification. Approximately 33% coverage."
    case full100Description = "xxHash64 full verification. Fast, non-cryptographic."
    case currentItem = "CURRENT ITEM"
    case currentVerifyFile = "CURRENT VERIFY FILE"
    case currentFile = "CURRENT FILE"
    case waitingForFirstFile = "Waiting for first file..."
    case preparingVerification = "Preparing verification..."
    case processingCinemaDNG = "Processing CinemaDNG frame sequence..."
    case finalizing = "Finalizing..."
    case estimating = "Estimating..."
    case remaining = "remaining"
    case jobStatus = "Job Status"
    case copyProgress = "COPY PROGRESS"
    case copyETA = "COPY ETA"
    case currentCopySpeed = "CURRENT COPY SPEED"
    case verifyProgress = "VERIFY PROGRESS"
    case verifyETA = "VERIFY ETA"
    case verifyElapsed = "VERIFY ELAPSED"
    case phaseProgress = "PHASE PROGRESS"
    case phaseETA = "PHASE ETA"
    case currentSpeed = "CURRENT SPEED"
    case averageCopySpeed = "AVERAGE COPY SPEED"
    case copyElapsed = "COPY ELAPSED"
    case copied = "COPIED"
    case files = "FILES"
    case totalSize = "TOTAL SIZE"
    case folders = "FOLDERS"
    case filesystem = "FILESYSTEM"
    case freeSpace = "FREE SPACE"
    case writable = "WRITABLE"
    case yes = "YES"
    case no = "NO"
    case payload = "Payload"
    case admissionFloor = "Admission Floor"
    case available = "Available"
    case marginAboveFloor = "Margin Above Floor"
    case ready = "READY"
    case setupRequired = "SETUP REQUIRED"
    case preparing = "PREPARING"
    case copying = "COPYING"
    case verifying = "VERIFYING"
    case transferComplete = "TRANSFER COMPLETE"
    case safeToEject = "SAFE TO EJECT"
    case manualCheckRequired = "MANUAL CHECK REQUIRED"
    case transferError = "TRANSFER ERROR"
    case cancelled = "CANCELLED"
    case startTransfer = "START TRANSFER"
    case preparingTransfer = "PREPARING TRANSFER"
    case cancel = "CANCEL"
    case retry = "RETRY"
    case startNewTransfer = "START NEW TRANSFER"
    case cancelTransfer = "Cancel Transfer"
    case retryTransfer = "Retry Transfer"
    case sourceMetadataUnavailable = "Source metadata unavailable."
    case analyzingSourceMetadata = "Analyzing source metadata…"
    case destinationMetadataUnavailable = "Destination metadata unavailable."
    case analyzingDestinationMetadata = "Analyzing destination metadata…"
    case selectSourceAndDestination = "Select source and destination."
    case analyzingStorage = "Analyzing storage…"
    case capacityPrecheckPassed = "CAPACITY PRECHECK PASSED"
    case insufficientDestinationSpace = "INSUFFICIENT DESTINATION SPACE"
    case destinationNotWritable = "DESTINATION NOT WRITABLE"
    case capacitySnapshotHelp = "Capacity is a snapshot, not a reservation. Transfer preflight remains authoritative."
    case apfsCapacitySupport = "The current capacity snapshot meets the validated APFS allocation floor. Filesystem overhead and other writers may still require additional space."
    case unvalidatedCapacitySupport = "Allocation overhead is not validated for this filesystem. The current capacity snapshot covers logical payload only and does not guarantee the transfer will fit."
    case sourceProtection = "Source protection · Read-only"
    case openTechnicalLog = "Open Technical Log"
    case technicalDetails = "Technical Details"
    case readyToTransfer = "Ready to transfer"
    case completeTransferSetup = "Complete transfer setup."
    case copyInProgress = "Copy in progress. Do not remove media."
    case verificationInProgress = "Verification in progress. Do not remove media."
    case clickToBeginCopy = "Click to begin copy."
    case scanningSource = "Scanning source and checking destination..."
    case compareHashes = "Comparing source and destination hashes."
    case copyCompletedVerificationDisabled = "Copy completed. Verification was disabled."
    case verificationCompleted = "Verification completed successfully."
    case verificationDidNotPass = "Verification did not pass. Review before using media."
    case reviewErrorBeforeRetrying = "Review the error before retrying."
    case transferWasCancelled = "Transfer was cancelled."
}
