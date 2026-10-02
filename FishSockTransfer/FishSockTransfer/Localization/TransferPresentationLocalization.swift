// FST / CenVu | (+84) 842 841 222

import Foundation

/// String Catalog lookup for known, computed operator-facing Transfer text.
/// Unknown runtime strings pass through untouched.
public enum TransferPresentationLocalization {
    private static let knownKeys: Set<String> = Set(TransferPresentationKey.allCases.map(\.rawValue))

    public static func text(_ english: String, locale: Locale, bundle: Bundle = .main) -> String {
        guard knownKeys.contains(english) else { return english }
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
    case full100 = "FULL 100% — Maximum confidence"
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
