// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public struct TransferRequest: Equatable, Sendable {
    public let sourceURL: URL
    public let destinationURL: URL
    public let bandwidthLimit: Int?
    
    public init(sourceURL: URL, destinationURL: URL, bandwidthLimit: Int? = nil) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.bandwidthLimit = bandwidthLimit
    }
}
