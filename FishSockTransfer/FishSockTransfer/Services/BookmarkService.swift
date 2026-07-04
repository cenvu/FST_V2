// FST / CenVu | (+84) 842 841 222

import Foundation

public actor BookmarkService {
    private var bookmarks: [URL: Data] = [:]
    
    public init() {}
    
    public func saveBookmark(for url: URL) throws {
        let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        bookmarks[url] = data
    }
    
    public func restoreBookmark(for url: URL) throws -> URL {
        guard let data = bookmarks[url] else {
            throw NSError(domain: "BookmarkService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No bookmark found"])
        }
        var isStale = false
        let resolved = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        if isStale {
            try saveBookmark(for: resolved)
        }
        return resolved
    }
}
