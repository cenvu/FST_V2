import Foundation

nonisolated public struct BundledRsyncInfo: Equatable, Sendable {
    public let executableURL: URL?
    public let version: String
    public let diagnostics: [String]

    public var isAvailable: Bool {
        executableURL != nil
    }

    public var badgeText: String {
        guard let executableURL else {
            return "Bundled Rsync Not Found"
        }

        return "\(executableURL.path) v\(version)"
    }

    public static func unavailable(version: String, diagnostics: [String]) -> BundledRsyncInfo {
        BundledRsyncInfo(executableURL: nil, version: version, diagnostics: diagnostics)
    }
}

public actor BundledRsyncService {
    public static let bundledVersion = "3.4.4"

    private var cachedInfo: BundledRsyncInfo?

    public init() {}

    public func bundledInfo() -> BundledRsyncInfo {
        if let cachedInfo {
            return cachedInfo
        }

        let info = resolveBundledInfo()
        cachedInfo = info
        return info
    }

    private func resolveBundledInfo() -> BundledRsyncInfo {
        guard let executableURL = Bundle.main.url(forResource: "rsync", withExtension: nil) else {
            return .unavailable(
                version: Self.bundledVersion,
                diagnostics: ["Bundled rsync resource missing"]
            )
        }

        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            return .unavailable(
                version: Self.bundledVersion,
                diagnostics: ["Bundled rsync missing at \(executableURL.path)"]
            )
        }

        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            return .unavailable(
                version: Self.bundledVersion,
                diagnostics: ["Bundled rsync is not executable at \(executableURL.path)"]
            )
        }

        return BundledRsyncInfo(
            executableURL: executableURL,
            version: Self.bundledVersion,
            diagnostics: ["Using bundled rsync \(Self.bundledVersion)"]
        )
    }
}
