import Foundation

nonisolated public enum RsyncBandwidthLimitError: Error, Equatable, LocalizedError, Sendable {
    case notFinite
    case belowMinimum
    case aboveMaximum

    public var errorDescription: String? {
        switch self {
        case .notFinite:
            return "Bandwidth limit must be a finite MB/s value."
        case .belowMinimum:
            return "Bandwidth limit must be at least 20 MB/s or Unlimited."
        case .aboveMaximum:
            return "Bandwidth limit must be 300 MB/s or lower."
        }
    }
}

nonisolated public enum RsyncBandwidthLimit {
    public static let minimumMegabytesPerSecond = 20.0
    public static let maximumMegabytesPerSecond = 300.0
    public static let presetMegabytesPerSecond = [50, 120, 240]

    public static func kibPerSecond(for megabytesPerSecond: Int) -> Int {
        do {
            return try kibPerSecond(forMegabytesPerSecond: Double(megabytesPerSecond))
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }

    public static func kibPerSecond(forMegabytesPerSecond megabytesPerSecond: Double) throws -> Int {
        guard megabytesPerSecond.isFinite else {
            throw RsyncBandwidthLimitError.notFinite
        }

        guard megabytesPerSecond >= minimumMegabytesPerSecond else {
            throw RsyncBandwidthLimitError.belowMinimum
        }

        guard megabytesPerSecond <= maximumMegabytesPerSecond else {
            throw RsyncBandwidthLimitError.aboveMaximum
        }

        return Int((megabytesPerSecond * 1024.0).rounded(.toNearestOrAwayFromZero))
    }

    public static func validate(kibPerSecond value: Int) throws -> Int {
        guard value >= kibPerSecond(for: Int(minimumMegabytesPerSecond)) else {
            throw RsyncBandwidthLimitError.belowMinimum
        }

        guard value <= kibPerSecond(for: Int(maximumMegabytesPerSecond)) else {
            throw RsyncBandwidthLimitError.aboveMaximum
        }

        return value
    }

    public static func rsyncArgument(forKiBPerSecond kibPerSecond: Int?) throws -> String? {
        guard let kibPerSecond else { return nil }
        let validatedLimit = try validate(kibPerSecond: kibPerSecond)
        return "--bwlimit=\(validatedLimit)"
    }

    public static func displayDescription(kibPerSecond: Int?) -> String {
        guard let kibPerSecond else { return "Unlimited" }

        let megabytesPerSecond = Double(kibPerSecond) / 1024.0
        if megabytesPerSecond.rounded() == megabytesPerSecond {
            return "\(Int(megabytesPerSecond)) MB/s"
        }

        return String(format: "%.2f MB/s", megabytesPerSecond)
    }
}
