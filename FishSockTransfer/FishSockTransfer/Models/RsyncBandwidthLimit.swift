import Foundation

nonisolated public enum RsyncBandwidthLimit {
    public static func kibPerSecond(for megabytesPerSecond: Int) -> Int {
        megabytesPerSecond * 1024
    }
}
