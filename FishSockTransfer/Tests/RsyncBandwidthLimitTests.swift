// FST / CenVu | (+84) 842 841 222

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
        assertEqual(RsyncBandwidthLimit.presetMegabytesPerSecond, [50, 75, 100, 125, 150, 175, 200], "current product presets")
        assertEqual(RsyncBandwidthLimit.minimumMegabytesPerSecond, 20, "defensive minimum")
        assertEqual(RsyncBandwidthLimit.maximumMegabytesPerSecond, 300, "defensive maximum")
        let mappings = [(50, 51_200), (75, 76_800), (100, 102_400), (125, 128_000),
                        (150, 153_600), (175, 179_200), (200, 204_800)]
        for (megabytes, kib) in mappings {
            assertEqual(RsyncBandwidthLimit.kibPerSecond(for: megabytes), kib, "\(megabytes) MB/s conversion")
            assertEqual(try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: Double(megabytes)), kib, "throwing converter")
            assertEqual(try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: kib), "--bwlimit=\(kib)", "preset argv")
        }

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

        for value in [19.0, 301.0, Double.nan, -Double.infinity] {
            assertThrows("invalid MB/s \(value) is rejected") {
                _ = try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: value)
            }
        }

        assertEqual(
            try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 300)),
            "--bwlimit=307200",
            "maximum allowed speed produces valid rsync bwlimit argument"
        )

        let generatedArgument = try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 125))
        assertEqual(generatedArgument?.hasPrefix("--bwlimit="), true, "generated argument stays in rsync argument form")
        assertEqual(generatedArgument?.contains("/usr/bin/rsync"), false, "generated argument must not contain system rsync path")
        assertEqual(generatedArgument?.contains("/opt/homebrew"), false, "generated argument must not contain Homebrew rsync path")

        print("RsyncBandwidthLimitTests passed")
    }
}
