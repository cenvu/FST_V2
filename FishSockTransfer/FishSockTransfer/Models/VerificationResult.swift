import Foundation

nonisolated public enum VerificationStatus: String, Equatable, Sendable {
    case passed
    case failed
    case cancelled
}

nonisolated public struct VerificationResult: Equatable, Sendable {
    public let totalFiles: Int
    public let verifiedFiles: Int
    public let passedFiles: Int
    public let failedFiles: Int
    public let duration: TimeInterval
    public let status: VerificationStatus
    
    public init(
        totalFiles: Int,
        verifiedFiles: Int,
        passedFiles: Int,
        failedFiles: Int,
        duration: TimeInterval,
        status: VerificationStatus
    ) {
        self.totalFiles = totalFiles
        self.verifiedFiles = verifiedFiles
        self.passedFiles = passedFiles
        self.failedFiles = failedFiles
        self.duration = duration
        self.status = status
    }
}
