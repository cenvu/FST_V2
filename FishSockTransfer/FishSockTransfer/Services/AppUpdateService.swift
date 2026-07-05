// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public protocol AppUpdateServicing: Sendable {
    func checkForUpdates() async -> AppUpdateState
}

public final class AppUpdateService: AppUpdateServicing, @unchecked Sendable {
    public static let defaultRepositoryOwner = "cenvu"
    public static let defaultRepositoryName = "FST_V2"

    private let repositoryOwner: String
    private let repositoryName: String
    private let session: URLSession
    private let currentVersionProvider: @Sendable () -> String?
    private let onLog: @Sendable (String) -> Void

    public init(
        repositoryOwner: String = AppUpdateService.defaultRepositoryOwner,
        repositoryName: String = AppUpdateService.defaultRepositoryName,
        session: URLSession = .shared,
        currentVersionProvider: @escaping @Sendable () -> String? = {
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ??
            Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        },
        onLog: @escaping @Sendable (String) -> Void = { _ in }
    ) {
        self.repositoryOwner = repositoryOwner
        self.repositoryName = repositoryName
        self.session = session
        self.currentVersionProvider = currentVersionProvider
        self.onLog = onLog
    }

    public func checkForUpdates() async -> AppUpdateState {
        onLog("Update check started.")

        guard isRepositoryConfigured else {
            let message = "GitHub update repository is not configured."
            onLog("Update check failed: \(message)")
            return .failed(message: message)
        }

        guard let currentVersionString = currentVersionProvider(),
              let currentVersion = SemanticVersion(rawValue: currentVersionString) else {
            let message = "Unable to read current app version."
            onLog("Update check failed: \(message)")
            return .failed(message: message)
        }

        guard let endpoint = latestReleaseURL else {
            let message = "GitHub update endpoint could not be created."
            onLog("Update check failed: \(message)")
            return .failed(message: message)
        }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("FishSockTransfer", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                let message = "GitHub release request returned no HTTP response."
                onLog("Update check failed: \(message)")
                return .failed(message: message)
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                let message = "GitHub release request failed: HTTP \(httpResponse.statusCode)."
                onLog("Update check failed: \(message)")
                return .failed(message: message)
            }

            let release: GitHubRelease
            do {
                release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            } catch {
                let message = "GitHub release response could not be decoded."
                onLog("Update check failed: \(message)")
                return .failed(message: message)
            }

            guard !release.draft, !release.prerelease else {
                let message = "Latest GitHub release is draft or prerelease."
                onLog("Update check failed: \(message)")
                return .failed(message: message)
            }

            guard let latestVersion = SemanticVersion(rawValue: release.tagName) else {
                let message = "Latest release version is malformed."
                onLog("Update check failed: \(message)")
                return .failed(message: message)
            }

            onLog("Latest release detected: \(latestVersion).")

            if latestVersion > currentVersion {
                let downloadURL = bestDownloadURL(from: release.assets)
                onLog("Update available: \(currentVersion) -> \(latestVersion).")
                return .updateAvailable(
                    currentVersion: currentVersion.description,
                    latestVersion: latestVersion.description,
                    releaseURL: release.htmlURL,
                    downloadURL: downloadURL
                )
            }

            onLog("App is up to date: \(currentVersion).")
            return .upToDate(
                currentVersion: currentVersion.description,
                latestVersion: latestVersion.description,
                releaseURL: release.htmlURL
            )
        } catch {
            let message = "Update check failed: \(error.localizedDescription)"
            onLog(message)
            return .failed(message: message)
        }
    }

    private var isRepositoryConfigured: Bool {
        !repositoryOwner.isEmpty &&
        !repositoryName.isEmpty
    }

    private var latestReleaseURL: URL? {
        URL(string: "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/releases/latest")
    }

    private func bestDownloadURL(from assets: [GitHubRelease.Asset]) -> URL? {
        let preferredExtensions = [".dmg", ".zip", ".pkg"]

        for preferredExtension in preferredExtensions {
            if let asset = assets.first(where: { $0.name.lowercased().hasSuffix(preferredExtension) }) {
                return asset.browserDownloadURL
            }
        }

        return nil
    }
}
