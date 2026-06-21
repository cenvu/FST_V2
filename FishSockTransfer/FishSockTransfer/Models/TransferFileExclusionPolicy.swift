import Foundation

nonisolated public enum TransferFileExclusionPolicy {
    public static let rsyncExclusionPatterns = [
        ".DS_Store",
        "._*",
        ".Spotlight-V100",
        ".Trashes",
        ".fseventsd",
        ".TemporaryItems"
    ]

    public static var rsyncExclusionArguments: [String] {
        rsyncExclusionPatterns.map { "--exclude=\($0)" }
    }

    public static func shouldExclude(_ url: URL, rootURL: URL) -> Bool {
        let relativePath = url.path.replacingOccurrences(of: rootURL.path + "/", with: "")
        let components = relativePath.split(separator: "/").map(String.init)

        return components.contains { component in
            component == ".DS_Store" ||
            component.hasPrefix("._") ||
            component == ".Spotlight-V100" ||
            component == ".Trashes" ||
            component == ".fseventsd" ||
            component == ".TemporaryItems"
        }
    }
}
