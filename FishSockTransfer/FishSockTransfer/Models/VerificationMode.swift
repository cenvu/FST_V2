// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public enum HashAlgorithm: String, Equatable, Sendable {
    case sha256
    case xxHash64

    public var displayName: String {
        switch self {
        case .sha256:
            return "SHA256"
        case .xxHash64:
            return "xxHash64"
        }
    }

    public var verificationNote: String {
        switch self {
        case .sha256:
            return "Strong cryptographic hash verification"
        case .xxHash64:
            return "Fast non-cryptographic hash verification"
        }
    }
}

nonisolated public enum VerificationMode: String, Equatable, Sendable {
    case none
    case random33
    case full

    public var hashAlgorithm: HashAlgorithm? {
        switch self {
        case .none:
            return nil
        case .random33:
            return .sha256
        case .full:
            return .xxHash64
        }
    }

    public var coverageDescription: String {
        switch self {
        case .none:
            return "None"
        case .random33:
            return "Random 33%"
        case .full:
            return "Full 100%"
        }
    }

    public var operatorLabel: String {
        switch self {
        case .none:
            return "None"
        case .random33:
            return "SHA256 Sample 33%"
        case .full:
            return "xxHash64 Full 100%"
        }
    }

    public var reportLabel: String {
        operatorLabel
    }
}
