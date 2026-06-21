import Foundation

private func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

private func assertNil<T>(_ actual: T?, _ message: String) {
    guard actual == nil else {
        fatalError("\(message): expected nil, got \(String(describing: actual))")
    }
}

private func assertThrows(_ message: String, _ block: () throws -> Void) {
    do {
        try block()
        fatalError("\(message): expected throw")
    } catch {
        return
    }
}

@main
struct RsyncBandwidthLimitTests {
    static func main() throws {
        assertEqual(RsyncBandwidthLimit.kibPerSecond(for: 50), 51200, "50 MB/s conversion")
        assertEqual(RsyncBandwidthLimit.kibPerSecond(for: 120), 122880, "120 MB/s conversion")
        assertEqual(RsyncBandwidthLimit.kibPerSecond(for: 240), 245760, "240 MB/s conversion")

        let fractionalLimit = try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: 20.001)
        assertEqual(fractionalLimit, 20481, "fractional MB/s rounds to nearest KiB/s")

        let unlimitedArgument = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: nil)
        assertNil(unlimitedArgument, "unlimited speed must omit --bwlimit")

        let validArgument = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 50))
        assertEqual(validArgument, "--bwlimit=51200", "valid speed produces rsync bwlimit argument")

        let validFractionalArgument = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: fractionalLimit)
        assertEqual(validFractionalArgument, "--bwlimit=20481", "fractional speed produces rounded rsync bwlimit argument")

        assertThrows("zero KiB/s is rejected") {
            _ = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: 0)
        }

        assertThrows("negative KiB/s is rejected") {
            _ = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: -1)
        }

        assertThrows("extremely small positive KiB/s is rejected") {
            _ = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: 1)
        }

        assertThrows("very large KiB/s is rejected") {
            _ = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: Int.max)
        }

        assertThrows("very large MB/s is rejected before conversion overflow") {
            _ = try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: Double.greatestFiniteMagnitude)
        }

        assertThrows("non-finite MB/s is rejected") {
            _ = try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: Double.infinity)
        }

        assertEqual(
            try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 300)),
            "--bwlimit=307200",
            "maximum allowed speed produces valid rsync bwlimit argument"
        )

        let generatedArgument = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 120))
        assertEqual(generatedArgument?.hasPrefix("--bwlimit="), true, "generated argument stays in rsync argument form")
        assertEqual(generatedArgument?.contains("/usr/bin/rsync"), false, "generated argument must not contain system rsync path")
        assertEqual(generatedArgument?.contains("/opt/homebrew"), false, "generated argument must not contain Homebrew rsync path")

        print("RsyncBandwidthLimitTests passed")
    }
}
