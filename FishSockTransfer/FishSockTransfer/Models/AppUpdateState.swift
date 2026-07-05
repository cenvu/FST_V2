// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public enum AppUpdateState: Equatable, Sendable {
    case idle
    case checking
    case upToDate(currentVersion: String, latestVersion: String, releaseURL: URL)
    case updateAvailable(currentVersion: String, latestVersion: String, releaseURL: URL, downloadURL: URL?)
    case failed(message: String)
}
