// FST / CenVu | (+84) 842 841 222

import Foundation

private func assertTrue(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError(message)
    }
}

private func assertFalse(_ condition: Bool, _ message: String) {
    assertTrue(!condition, message)
}

private func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

private func assertContains(_ values: [String], _ expectedSubstring: String, _ message: String) {
    guard values.contains(where: { $0.contains(expectedSubstring) }) else {
        fatalError("\(message): missing '\(expectedSubstring)' in \(values)")
    }
}

@main
struct BundledRsyncServiceTests {
    static func main() async throws {
        let temporaryRoot = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FSTBundledRsyncServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer {
            do {
                try FileManager.default.removeItem(at: temporaryRoot)
            } catch {
                fputs("Warning: failed to remove test directory \(temporaryRoot.path): \(error)\n", stderr)
            }
        }

        try await testMissingBundledRsyncFailsFast()
        try await testNonExecutableBundledRsyncFailsFast(temporaryRoot: temporaryRoot)
        try await testWrongBundledRsyncVersionFailsFast(temporaryRoot: temporaryRoot)
        try await testWrongPatchBundledRsyncVersionFailsFast(temporaryRoot: temporaryRoot)
        try await testMalformedImpersonatorOutputFailsFast(temporaryRoot: temporaryRoot)
        try await testDecoratedBundledRsyncVersionFailsFast(temporaryRoot: temporaryRoot)
        try await testEmptyVersionOutputFailsFast(temporaryRoot: temporaryRoot)
        try await testHangingVersionCommandTimesOut(temporaryRoot: temporaryRoot)
        try await testValidBundledRsyncVersionPasses(temporaryRoot: temporaryRoot)
        try await testActualBundledRsyncBinaryPasses()

        print("BundledRsyncServiceTests passed")
    }

    private static func testMissingBundledRsyncFailsFast() async throws {
        let service = BundledRsyncService(
            bundledExecutableURL: nil,
            versionOutputProvider: { _ in
                fatalError("Version command must not run when bundled rsync is missing.")
            }
        )

        let info = await service.bundledInfo()
        assertFalse(info.isAvailable, "Missing bundled rsync must be unavailable.")
        assertEqual(info.version, "unknown", "Missing bundled rsync must not claim version 3.4.4.")
        assertContains(info.diagnostics, "Bundled rsync resource missing", "Missing diagnostic")
        assertEqual(info.badgeText, "Bundled rsync resource missing", "Missing badge should describe missing resource.")
    }

    private static func testNonExecutableBundledRsyncFailsFast(temporaryRoot: URL) async throws {
        let rsyncURL = temporaryRoot.appendingPathComponent("rsync-non-executable")
        try "#!/bin/sh\nexit 0\n".write(to: rsyncURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: rsyncURL.path)

        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { _ in
                fatalError("Version command must not run when bundled rsync is not executable.")
            }
        )

        let info = await service.bundledInfo()
        assertFalse(info.isAvailable, "Non-executable bundled rsync must be unavailable.")
        assertContains(info.diagnostics, "not executable", "Non-executable diagnostic")
        assertContains([info.badgeText], "not executable", "Non-executable badge should describe executable failure.")
    }

    private static func testWrongBundledRsyncVersionFailsFast(temporaryRoot: URL) async throws {
        let rsyncURL = try executableFile(named: "rsync-wrong-version", temporaryRoot: temporaryRoot)
        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { url in
                assertEqual(url, rsyncURL, "Version validation must use the bundled absolute path.")
                return "rsync  version 3.3.0  protocol version 31\n"
            }
        )

        let info = await service.bundledInfo()
        assertFalse(info.isAvailable, "Wrong bundled rsync version must be unavailable.")
        assertEqual(info.version, "3.3.0", "Wrong version should report detected version.")
        assertContains(info.diagnostics, "version mismatch", "Wrong-version diagnostic")
        assertContains([info.badgeText], "version mismatch", "Wrong-version badge should describe mismatch.")
    }

    private static func testWrongPatchBundledRsyncVersionFailsFast(temporaryRoot: URL) async throws {
        let rsyncURL = try executableFile(named: "rsync-wrong-patch-version", temporaryRoot: temporaryRoot)
        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { url in
                assertEqual(url, rsyncURL, "Version validation must use the bundled absolute path.")
                return "rsync version 3.4.40 protocol version 32\n"
            }
        )

        let info = await service.bundledInfo()
        assertFalse(info.isAvailable, "Wrong patch version must be unavailable.")
        assertEqual(info.version, "3.4.40", "Wrong patch version should report detected version.")
        assertContains(info.diagnostics, "version mismatch", "Wrong patch diagnostic")
    }

    private static func testMalformedImpersonatorOutputFailsFast(temporaryRoot: URL) async throws {
        try await assertMalformedVersionOutputFails(
            output: "not-rsync version 3.4.4 protocol version 32\n",
            temporaryRoot: temporaryRoot,
            message: "not-rsync output"
        )
        try await assertMalformedVersionOutputFails(
            output: "fake version 3.4.4 protocol version 32\n",
            temporaryRoot: temporaryRoot,
            message: "fake output"
        )
        try await assertMalformedVersionOutputFails(
            output: "tool version 3.4.4 protocol version 32\n",
            temporaryRoot: temporaryRoot,
            message: "generic tool output"
        )
        try await assertMalformedVersionOutputFails(
            output: "warning\nrsync version 3.4.4 protocol version 32\n",
            temporaryRoot: temporaryRoot,
            message: "canonical line hidden after non-canonical output"
        )
    }

    private static func testDecoratedBundledRsyncVersionFailsFast(temporaryRoot: URL) async throws {
        try await assertMalformedVersionOutputFails(
            output: "rsync version 3.4.4-custom protocol version 32\n",
            temporaryRoot: temporaryRoot,
            message: "decorated custom version output"
        )
    }

    private static func testEmptyVersionOutputFailsFast(temporaryRoot: URL) async throws {
        try await assertMalformedVersionOutputFails(
            output: "",
            temporaryRoot: temporaryRoot,
            message: "empty output"
        )
    }

    private static func testHangingVersionCommandTimesOut(temporaryRoot: URL) async throws {
        let rsyncURL = temporaryRoot.appendingPathComponent("rsync-hanging-version")
        try "#!/bin/sh\nsleep 10\n".write(to: rsyncURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: rsyncURL.path)

        let service = BundledRsyncService(bundledExecutableURL: rsyncURL)
        let startedAt = Date()
        let info = await service.bundledInfo()
        let duration = Date().timeIntervalSince(startedAt)

        assertFalse(info.isAvailable, "Hanging version command must be unavailable.")
        assertTrue(duration < 5.0, "Hanging version command must fail fast, duration was \(duration).")
        assertContains(info.diagnostics, "timed out", "Timeout diagnostic")
        assertContains([info.badgeText], "timed out", "Timeout badge should describe timeout.")
    }

    private static func testValidBundledRsyncVersionPasses(temporaryRoot: URL) async throws {
        let rsyncURL = try executableFile(named: "rsync-valid-version", temporaryRoot: temporaryRoot)
        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { url in
                assertEqual(url, rsyncURL, "Version validation must use the bundled absolute path.")
                return "rsync  version 3.4.4  protocol version 32\n"
            }
        )

        let info = await service.bundledInfo()
        assertTrue(info.isAvailable, "Valid bundled rsync 3.4.4 must be available.")
        assertEqual(info.executableURL, rsyncURL, "Validated path must be the bundled path.")
        assertEqual(info.version, "3.4.4", "Valid version should be detected from --version output.")
        assertContains(info.diagnostics, "Bundled rsync path: \(rsyncURL.path)", "Path diagnostic")
        assertContains(info.diagnostics, "Bundled rsync version: 3.4.4", "Version diagnostic")
    }

    private static func testActualBundledRsyncBinaryPasses() async throws {
        let actualBundledRsyncURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("FishSockTransfer/FishSockTransfer/rsync")
        let service = BundledRsyncService(bundledExecutableURL: actualBundledRsyncURL)

        let info = await service.bundledInfo()
        assertTrue(info.isAvailable, "Actual bundled rsync binary must validate.")
        assertEqual(info.executableURL, actualBundledRsyncURL, "Actual bundled rsync path mismatch.")
        assertEqual(info.version, "3.4.4", "Actual bundled rsync must report 3.4.4.")
        assertContains(info.diagnostics, "Bundled rsync path:", "Actual path diagnostic")
        assertContains(info.diagnostics, "Bundled rsync version: 3.4.4", "Actual version diagnostic")
    }

    private static func executableFile(named name: String, temporaryRoot: URL) throws -> URL {
        let fileURL = temporaryRoot.appendingPathComponent(name)
        try "#!/bin/sh\nexit 0\n".write(to: fileURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fileURL.path)
        return fileURL
    }

    private static func assertMalformedVersionOutputFails(
        output: String,
        temporaryRoot: URL,
        message: String
    ) async throws {
        let rsyncURL = try executableFile(named: "rsync-malformed-\(UUID().uuidString)", temporaryRoot: temporaryRoot)
        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { url in
                assertEqual(url, rsyncURL, "Version validation must use the bundled absolute path.")
                return output
            }
        )

        let info = await service.bundledInfo()
        assertFalse(info.isAvailable, "\(message) must be unavailable.")
        assertEqual(info.version, "unknown", "\(message) must not claim version 3.4.4.")
        assertContains(info.diagnostics, "version output unrecognized", "\(message) malformed-output diagnostic")
        assertContains([info.badgeText], "version output unrecognized", "\(message) badge should describe malformed output.")
    }
}
