import Foundation

nonisolated public struct TransferReport: Equatable, Sendable {
    public let date: String
    public let time: String
    public let sourcePath: String
    public let destinationPath: String
    public let totalSize: Int64
    public let fileCount: Int
    public let transferDuration: TimeInterval
    public let averageSpeed: Double
    public let verificationMode: VerificationMode
    public let verificationResult: VerificationStatus?
    public let errorCount: Int
    public let finalStatus: TransferState
    
    public init(
        date: String,
        time: String,
        sourcePath: String,
        destinationPath: String,
        totalSize: Int64,
        fileCount: Int,
        transferDuration: TimeInterval,
        averageSpeed: Double,
        verificationMode: VerificationMode,
        verificationResult: VerificationStatus?,
        errorCount: Int,
        finalStatus: TransferState
    ) {
        self.date = date
        self.time = time
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.totalSize = totalSize
        self.fileCount = fileCount
        self.transferDuration = transferDuration
        self.averageSpeed = averageSpeed
        self.verificationMode = verificationMode
        self.verificationResult = verificationResult
        self.errorCount = errorCount
        self.finalStatus = finalStatus
    }
}
