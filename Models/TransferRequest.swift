import Foundation

public struct TransferRequest: Equatable {
    public let sourceURL: URL
    public let destinationURL: URL
    public let bandwidthLimit: Int?
    
    public init(sourceURL: URL, destinationURL: URL, bandwidthLimit: Int? = nil) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.bandwidthLimit = bandwidthLimit
    }
}
