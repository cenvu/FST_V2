import Foundation

func assertEqual(_ actual: Int, _ expected: Int, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

assertEqual(RsyncBandwidthLimit.kibPerSecond(for: 50), 51200, "50 MB/s conversion")
assertEqual(RsyncBandwidthLimit.kibPerSecond(for: 100), 102400, "100 MB/s conversion")
assertEqual(RsyncBandwidthLimit.kibPerSecond(for: 150), 153600, "150 MB/s conversion")
assertEqual(RsyncBandwidthLimit.kibPerSecond(for: 200), 204800, "200 MB/s conversion")
assertEqual(RsyncBandwidthLimit.kibPerSecond(for: 250), 256000, "250 MB/s conversion")

print("RsyncBandwidthLimitTests passed")
