// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public struct VerificationRequest: Equatable, Sendable {
    public let sourceURL: URL
    public let destinationURL: URL
    public let mode: VerificationMode
    
    public init(sourceURL: URL, destinationURL: URL, mode: VerificationMode) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.mode = mode
    }
}
