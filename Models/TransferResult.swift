import Foundation

public struct TransferResult: Equatable {
    public let status: TransferState
    public let duration: TimeInterval
    public let speed: Double
    public let transferredBytes: Int64
    
    public init(status: TransferState, duration: TimeInterval, speed: Double, transferredBytes: Int64) {
        self.status = status
        self.duration = duration
        self.speed = speed
        self.transferredBytes = transferredBytes
    }
}
