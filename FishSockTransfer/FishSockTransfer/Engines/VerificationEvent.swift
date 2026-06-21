import Foundation

nonisolated public enum VerificationError: Error, Equatable, Sendable {
    case sourceMissing
    case destinationMissing
    case fileCountMismatch
    case fileSizeMismatch
    case hashMismatch
    case cancelled
    case unknown
}

nonisolated public enum VerificationEvent: Equatable, Sendable {
    case started
    case progress(Double)
    case currentFile(String)
    case log(String)
    case hashGenerated(String)
    case completed(VerificationResult)
    case cancelled
    case failed(VerificationError)
}
