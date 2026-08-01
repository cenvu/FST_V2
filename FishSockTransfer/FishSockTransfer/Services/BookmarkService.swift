// FST / CenVu | (+84) 842 841 222

import Foundation

/// Persistence seam for bookmark bytes, keyed by role. Production uses
/// `UserDefaults`; deterministic tests inject an isolated in-memory store so
/// they never read or write the user's real defaults domain. `nonisolated`
/// throughout: this project defaults unannotated declarations to
/// `@MainActor`, but `BookmarkService` (an independent actor) calls this
/// seam synchronously from its own isolation domain, never MainActor's.
public protocol BookmarkByteStore: Sendable {
    nonisolated func data(for role: BookmarkRole) -> Data?
    nonisolated func setData(_ data: Data, for role: BookmarkRole)
    nonisolated func removeData(for role: BookmarkRole)
}

public nonisolated final class UserDefaultsBookmarkStore: BookmarkByteStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(for role: BookmarkRole) -> String {
        "com.cen.FishSockTransfer.bookmark.\(role.rawValue)"
    }

    public func data(for role: BookmarkRole) -> Data? {
        defaults.data(forKey: key(for: role))
    }

    public func setData(_ data: Data, for role: BookmarkRole) {
        defaults.set(data, forKey: key(for: role))
    }

    public func removeData(for role: BookmarkRole) {
        defaults.removeObject(forKey: key(for: role))
    }
}

/// The sole place FST calls real macOS bookmark and security-scope APIs.
/// Conforms to `BookmarkPersisting` (save/resolve/refresh/remove app-scoped
/// bookmark bytes) and `SecurityScopedAccessing` (raw, unconditional
/// start/stop syscalls — no role or generation concept here).
///
/// Access-lease tracking and restore-vs-Select/Clear race safety live in
/// `BookmarkAccessCoordinator` (defined in TransferViewModel.swift, which
/// wraps an instance of this type for its `SecurityScopedAccessing`
/// conformance). Keeping that logic in pure Swift outside this file lets it
/// compile and run deterministically inside the canonical XCTest target.
public actor BookmarkService: BookmarkPersisting, SecurityScopedAccessing {
    private let store: BookmarkByteStore
    private var latestGeneration: [BookmarkRole: Int] = [:]

    public init(store: BookmarkByteStore = UserDefaultsBookmarkStore()) {
        self.store = store
    }

    @discardableResult
    public func saveBookmark(for url: URL, role: BookmarkRole, generation: Int) -> Bool {
        guard acceptGeneration(generation, for: role) else { return false }
        do {
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            store.setData(data, for: role)
            return true
        } catch {
            return false
        }
    }

    public func resolveBookmark(for role: BookmarkRole) -> BookmarkResolution {
        guard let data = store.data(for: role) else { return .none }
        var isStale = false
        do {
            let resolved = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return .usable(url: resolved, wasStale: isStale)
        } catch {
            return .corrupt
        }
    }

    /// Creates fresh bookmark data for `url` and persists it under `role`,
    /// replacing stale stored data. Same operation as `saveBookmark`, named
    /// separately so call sites read as "stale bookmark refresh."
    @discardableResult
    public func refreshBookmark(for url: URL, role: BookmarkRole, generation: Int) -> Bool {
        saveBookmark(for: url, role: role, generation: generation)
    }

    public func removeBookmark(for role: BookmarkRole, generation: Int) {
        guard acceptGeneration(generation, for: role) else { return }
        store.removeData(for: role)
    }

    private func acceptGeneration(_ generation: Int, for role: BookmarkRole) -> Bool {
        guard generation >= (latestGeneration[role] ?? Int.min) else { return false }
        latestGeneration[role] = generation
        return true
    }

    public func startAccessing(_ url: URL) -> Bool {
        url.startAccessingSecurityScopedResource()
    }

    public func stopAccessing(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}
