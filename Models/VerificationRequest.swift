import Foundation

public struct VerificationRequest: Equatable {
    public let sourceURL: URL
    public let destinationURL: URL
    public let mode: VerificationMode
    
    public init(sourceURL: URL, destinationURL: URL, mode: VerificationMode) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.mode = mode
    }
}
