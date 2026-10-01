// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public struct SourceStorageMetadata: Equatable, Sendable {
    public let folderName: String
    public let fullPath: String
    /// Logical content bytes of transferable regular files, not source disk allocation.
    public let totalSizeBytes: Int64
    public let fileCount: Int
    public let folderCount: Int

    public init(folderName: String, fullPath: String, totalSizeBytes: Int64, fileCount: Int, folderCount: Int) {
        self.folderName = folderName
        self.fullPath = fullPath
        self.totalSizeBytes = totalSizeBytes
        self.fileCount = fileCount
        self.folderCount = folderCount
    }
}

nonisolated public struct DestinationStorageMetadata: Equatable, Sendable {
    public let freeSpaceBytes: Int64
    public let filesystem: String
    public let isWritable: Bool
    public let filesystemIdentity: String?
    public let allocationUnit: Int64?
    /// Public statfs mount identity; used to reject a changed destination profile.
    public let volumeIdentity: String?

    public init(freeSpaceBytes: Int64, filesystem: String, isWritable: Bool, filesystemIdentity: String? = nil, allocationUnit: Int64? = nil, volumeIdentity: String? = nil) {
        self.freeSpaceBytes = freeSpaceBytes
        self.filesystem = filesystem
        self.isWritable = isWritable
        self.filesystemIdentity = filesystemIdentity
        self.allocationUnit = allocationUnit
        self.volumeIdentity = volumeIdentity
    }
}

/// Destination-dependent admission evidence. A capacity snapshot is never a reservation.
nonisolated public struct DestinationCapacityAssessment: Equatable, Sendable {
    public enum PolicyKind: Equatable, Sendable {
        case validatedAPFSRounded
        case logicalOnlyUnvalidated
    }
    public enum UncertaintyKind: Equatable, Sendable {
        case filesystemOverheadAndOtherWriters
        case allocationOverheadUnvalidated
    }
    public let sourceURL: URL
    public let destinationURL: URL
    public let logicalPayloadBytes: Int64
    public let admissionFloorBytes: Int64
    public let availableSnapshotBytes: Int64
    public let filesystemIdentity: String?
    public let allocationUnit: Int64?
    public let policyKind: PolicyKind
    public let uncertaintyKind: UncertaintyKind

    public var passesCapacityPrecheck: Bool { availableSnapshotBytes >= admissionFloorBytes }
    public var hasUnvalidatedAllocation: Bool { policyKind == .logicalOnlyUnvalidated }
    public var marginAboveFloorBytes: Int64? {
        passesCapacityPrecheck ? availableSnapshotBytes - admissionFloorBytes : nil
    }
    public var supportingText: String {
        switch uncertaintyKind {
        case .filesystemOverheadAndOtherWriters:
            return "The current capacity snapshot meets the validated APFS allocation floor. Filesystem overhead and other writers may still require additional space."
        case .allocationOverheadUnvalidated:
            return "Allocation overhead is not validated for this filesystem. The current capacity snapshot covers logical payload only and does not guarantee the transfer will fit."
        }
    }
    /// Required-reason disk-space data and derived details stay out of Internet notifications.
    public static func notificationFailureSummary(_ message: String?) -> String? {
        guard let message else { return nil }
        let capacityErrors = ["Destination capacity is below the required preflight floor.",
                              "Unable to determine destination free space.",
                              "Capacity preflight arithmetic overflow.",
                              "Invalid capacity preflight evidence.",
                              "Destination capacity profile changed during preflight."]
        return capacityErrors.contains(where: message.contains)
            ? "Transfer failed. Keep the source media." : message
    }
    public static let passedStatus = "CAPACITY PRECHECK PASSED"

    public func matches(source: URL, destination: URL) -> Bool {
        sourceURL == TransferPreflightValidator.canonicalDirectoryURL(source)
            && destinationURL == TransferPreflightValidator.canonicalDirectoryURL(destination)
    }

    public static func validatedAllocationUnit(filesystemIdentity: String?, allocationUnit: Int64?) -> Int64? {
        filesystemIdentity == "apfs" && allocationUnit == 4096 ? 4096 : nil
    }

    public static func make(source: URL, destination: URL, logicalPayloadBytes: Int64,
                            roundedPayloadBytes: Int64?, snapshot: DestinationStorageMetadata) throws -> Self {
        guard logicalPayloadBytes >= 0, snapshot.freeSpaceBytes >= 0 else {
            throw TransferPreflightError.invalidCapacityEvidence
        }
        let validated = validatedAllocationUnit(filesystemIdentity: snapshot.filesystemIdentity,
                                                allocationUnit: snapshot.allocationUnit) != nil
        let floor: Int64
        if validated {
            guard let roundedPayloadBytes, roundedPayloadBytes >= logicalPayloadBytes else {
                throw TransferPreflightError.invalidCapacityEvidence
            }
            floor = roundedPayloadBytes
        } else {
            floor = logicalPayloadBytes
        }
        return Self(sourceURL: TransferPreflightValidator.canonicalDirectoryURL(source),
                    destinationURL: TransferPreflightValidator.canonicalDirectoryURL(destination),
                    logicalPayloadBytes: logicalPayloadBytes, admissionFloorBytes: floor,
                    availableSnapshotBytes: snapshot.freeSpaceBytes,
                    filesystemIdentity: snapshot.filesystemIdentity, allocationUnit: snapshot.allocationUnit,
                    policyKind: validated ? .validatedAPFSRounded : .logicalOnlyUnvalidated,
                    uncertaintyKind: validated ? .filesystemOverheadAndOtherWriters : .allocationOverheadUnvalidated)
    }
}

nonisolated enum CapacityArithmetic {
    static func add(_ lhs: Int64, _ rhs: Int64) throws -> Int64 {
        guard lhs >= 0, rhs >= 0 else { throw TransferPreflightError.invalidCapacityEvidence }
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        guard !overflow else { throw TransferPreflightError.capacityArithmeticOverflow }
        return sum
    }

    static func roundUp(_ size: Int64, unit: Int64) throws -> Int64 {
        guard size >= 0, unit > 0 else { throw TransferPreflightError.invalidCapacityEvidence }
        let remainder = size % unit
        // Avoid size + unit - 1 and ceil-then-multiply overflow.
        return remainder == 0 ? size : try add(size, unit - remainder)
    }
}
