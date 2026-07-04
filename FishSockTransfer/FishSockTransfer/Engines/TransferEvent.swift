// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public enum TransferError: Error, Equatable, LocalizedError, Sendable {
    case processLaunchFailed
    case sourceUnavailable
    case sourceEmpty
    case destinationUnavailable
    case insufficientSpace
    case rsyncExit(Int32)
    case rsyncNotFound
    case invalidBandwidthLimit
    case interrupted
    case timeout
    case unknown

    public var errorDescription: String? {
        switch self {
        case .sourceEmpty:
            return "No transferable files found after exclusions. Metadata-only files are ignored."
        case .processLaunchFailed:
            return "Failed to launch the underlying transfer process."
        case .sourceUnavailable:
            return "The source location is unavailable or cannot be read."
        case .destinationUnavailable:
            return "The destination location is unavailable or cannot be written."
        case .insufficientSpace:
            return "Not enough free space on the destination drive."
        case .rsyncExit(let code):
            return "Transfer process exited with error code \(code)."
        case .rsyncNotFound:
            return "Bundled rsync is missing, not executable, or not version 3.4.4."
        case .invalidBandwidthLimit:
            return "Invalid bandwidth limit. Choose Unlimited or 20-300 MB/s."
        case .interrupted:
            return "The transfer was interrupted."
        case .timeout:
            return "The transfer timed out."
        case .unknown:
            return "An unknown error occurred during transfer."
        }
    }
}

nonisolated public enum TransferEvent: Equatable, Sendable {
    case started
    case progress(Double)
    case speed(Double)
    case eta(TimeInterval)
    case currentFile(String)
    case log(String)
    case completed
    case cancelled
    case failed(TransferError)
}

nonisolated public enum CopyRuntimeSignalSource: Equatable, Sendable {
    case rsync
    case destinationObserver
    case mixed
    case unavailable
}

nonisolated public enum CopyRuntimeActivityState: Equatable, Sendable {
    case preparing
    case observingDestination
    case copying
    case finalizing
    case complete
    case unavailable
}

/// UI-only copy runtime telemetry. This must never be used as copy success or verification proof.
nonisolated public struct CopyRuntimeSnapshot: Equatable, Sendable {
    public let elapsedSeconds: Int
    public let currentItem: String?
    public let copiedBytes: Int64
    public let totalBytes: Int64?
    public let copiedFiles: Int
    public let totalFiles: Int?
    public let progressFraction: Double?
    public let currentSpeedBytesPerSecond: Double?
    public let averageSpeedBytesPerSecond: Double?
    public let etaSeconds: TimeInterval?
    public let signalSource: CopyRuntimeSignalSource
    public let lastObservedAt: Date
    public let activityState: CopyRuntimeActivityState

    public init(
        elapsedSeconds: Int,
        currentItem: String?,
        copiedBytes: Int64,
        totalBytes: Int64?,
        copiedFiles: Int,
        totalFiles: Int?,
        progressFraction: Double?,
        currentSpeedBytesPerSecond: Double?,
        averageSpeedBytesPerSecond: Double?,
        etaSeconds: TimeInterval?,
        signalSource: CopyRuntimeSignalSource,
        lastObservedAt: Date,
        activityState: CopyRuntimeActivityState
    ) {
        self.elapsedSeconds = elapsedSeconds
        self.currentItem = currentItem
        self.copiedBytes = copiedBytes
        self.totalBytes = totalBytes
        self.copiedFiles = copiedFiles
        self.totalFiles = totalFiles
        self.progressFraction = progressFraction
        self.currentSpeedBytesPerSecond = currentSpeedBytesPerSecond
        self.averageSpeedBytesPerSecond = averageSpeedBytesPerSecond
        self.etaSeconds = etaSeconds
        self.signalSource = signalSource
        self.lastObservedAt = lastObservedAt
        self.activityState = activityState
    }
}
