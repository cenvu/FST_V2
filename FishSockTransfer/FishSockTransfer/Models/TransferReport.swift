// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public struct TransferReport: Equatable, Sendable {
    public let jobID: String
    public let date: String
    public let time: String
    public let appName: String
    public let createdAt: Date
    public let startedAt: Date?
    public let endedAt: Date?
    public let sourcePath: String
    public let destinationPath: String
    public let sourceName: String
    public let destinationName: String?
    public let totalSize: Int64
    public let fileCount: Int
    public let copyDuration: TimeInterval?
    public let verificationDuration: TimeInterval?
    public let totalDuration: TimeInterval
    public let copyAverageSpeed: Double?
    public let verificationMode: VerificationMode
    public let verificationResult: VerificationStatus?
    public let verifiedFiles: Int
    public let passedFiles: Int
    public let failedFiles: Int
    public let failureReason: String?
    public let rsyncBinaryPath: String
    public let rsyncVersion: String
    public let exclusionPolicySummary: [String]
    public let errorCount: Int
    public let finalStatus: TransferState
    
    public init(
        jobID: String? = nil,
        date: String,
        time: String,
        appName: String = "FishSockTransfer",
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        sourcePath: String,
        destinationPath: String,
        sourceName: String? = nil,
        destinationName: String? = nil,
        totalSize: Int64,
        fileCount: Int,
        copyDuration: TimeInterval? = nil,
        verificationDuration: TimeInterval? = nil,
        totalDuration: TimeInterval,
        copyAverageSpeed: Double? = nil,
        verificationMode: VerificationMode,
        verificationResult: VerificationStatus?,
        verifiedFiles: Int = 0,
        passedFiles: Int = 0,
        failedFiles: Int = 0,
        failureReason: String? = nil,
        rsyncBinaryPath: String = "Unavailable",
        rsyncVersion: String = "unknown",
        exclusionPolicySummary: [String] = TransferFileExclusionPolicy.rsyncExclusionPatterns,
        errorCount: Int,
        finalStatus: TransferState
    ) {
        self.jobID = jobID ?? Self.makeJobID(createdAt: createdAt)
        self.date = date
        self.time = time
        self.appName = appName
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.sourceName = sourceName ?? URL(fileURLWithPath: sourcePath).lastPathComponent
        self.destinationName = destinationName ?? URL(fileURLWithPath: destinationPath).lastPathComponent
        self.totalSize = totalSize
        self.fileCount = fileCount
        self.copyDuration = copyDuration
        self.verificationDuration = verificationDuration
        self.totalDuration = totalDuration
        self.copyAverageSpeed = copyAverageSpeed
        self.verificationMode = verificationMode
        self.verificationResult = verificationResult
        self.verifiedFiles = verifiedFiles
        self.passedFiles = passedFiles
        self.failedFiles = failedFiles
        self.failureReason = failureReason
        self.rsyncBinaryPath = rsyncBinaryPath
        self.rsyncVersion = rsyncVersion
        self.exclusionPolicySummary = exclusionPolicySummary
        self.errorCount = errorCount
        self.finalStatus = finalStatus
    }

    public static func makeJobID(createdAt: Date, uuid: UUID = UUID()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let timestamp = formatter.string(from: createdAt)
        let suffix = String(uuid.uuidString.replacingOccurrences(of: "-", with: "").prefix(8)).uppercased()
        return "FST-\(timestamp)-\(suffix)"
    }
}
