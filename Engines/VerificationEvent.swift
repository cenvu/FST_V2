import Foundation

public enum VerificationError: Error, Equatable {
    case sourceMissing
    case destinationMissing
    case fileCountMismatch
    case fileSizeMismatch
    case hashMismatch
    case cancelled
    case unknown
}

public enum VerificationEvent: Equatable {
    case started
    case progress(Double)
    case currentFile(String)
    case hashGenerated(String)
    case completed(VerificationResult)
    case cancelled
    case failed(VerificationError)
}
