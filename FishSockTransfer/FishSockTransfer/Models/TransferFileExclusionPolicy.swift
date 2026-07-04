// FST / CenVu | (+84) 842 841 222

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
        let relativePath = relativePath(for: url, rootURL: rootURL)
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

    public static func relativePath(for url: URL, rootURL: URL) -> String {
        let rootPath = rootURL.resolvingSymlinksInPath().standardizedFileURL.path
        let itemPath = url.resolvingSymlinksInPath().standardizedFileURL.path

        guard itemPath.hasPrefix(rootPath + "/") else {
            return url.lastPathComponent
        }

        return String(itemPath.dropFirst(rootPath.count + 1))
    }
}
