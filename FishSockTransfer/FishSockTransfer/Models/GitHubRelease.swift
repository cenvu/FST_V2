// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public struct GitHubRelease: Decodable, Equatable, Sendable {
    public let tagName: String
    public let name: String?
    public let htmlURL: URL
    public let publishedAt: String?
    public let prerelease: Bool
    public let draft: Bool
    public let assets: [Asset]

    public struct Asset: Decodable, Equatable, Sendable {
        public let name: String
        public let browserDownloadURL: URL

        private enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlURL = "html_url"
        case publishedAt = "published_at"
        case prerelease
        case draft
        case assets
    }
}
