// FST / CenVu | (+84) 842 841 222

import XCTest

final class BundledRsyncServiceXCTests: XCTestCase {
    private var temporaryRoot: URL!

    override func setUpWithError() throws {
        temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("FSTBundledRsyncServiceXCTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryRoot)
        temporaryRoot = nil
    }

    func testMissingBundledRsyncFailsFast() async {
        let service = BundledRsyncService(
            bundledExecutableURL: nil,
            versionOutputProvider: { _ in
                XCTFail("Version command must not run when bundled rsync is missing.")
                return ""
            }
        )

        let info = await service.bundledInfo()
        XCTAssertFalse(info.isAvailable)
        XCTAssertEqual(info.version, "unknown")
        XCTAssertTrue(info.diagnostics.contains(where: { $0.contains("Bundled rsync resource missing") }))
        XCTAssertEqual(info.badgeText, "Bundled rsync resource missing")
    }

    func testNonExecutableBundledRsyncFailsFast() async throws {
        let rsyncURL = temporaryRoot.appendingPathComponent("rsync-non-executable")
        try "#!/bin/sh\nexit 0\n".write(to: rsyncURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: rsyncURL.path)

        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { _ in
                XCTFail("Version command must not run when bundled rsync is not executable.")
                return ""
            }
        )

        let info = await service.bundledInfo()
        XCTAssertFalse(info.isAvailable)
        XCTAssertTrue(info.diagnostics.contains(where: { $0.contains("not executable") }))
        XCTAssertTrue(info.badgeText.contains("not executable"))
    }

    func testWrongVersionFailsFast() async throws {
        let rsyncURL = try executableFile(named: "rsync-wrong-version")
        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { url in
                XCTAssertEqual(url, rsyncURL)
                return "rsync version 3.3.0 protocol version 31\n"
            }
        )

        let info = await service.bundledInfo()
        XCTAssertFalse(info.isAvailable)
        XCTAssertEqual(info.version, "3.3.0")
        XCTAssertTrue(info.diagnostics.contains(where: { $0.contains("version mismatch") }))
    }

    func testWrongPatchVersionDoesNotPassAsBundledVersion() async throws {
        let rsyncURL = try executableFile(named: "rsync-wrong-patch-version")
        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { url in
                XCTAssertEqual(url, rsyncURL)
                return "rsync version 3.4.40 protocol version 32\n"
            }
        )

        let info = await service.bundledInfo()
        XCTAssertFalse(info.isAvailable)
        XCTAssertEqual(info.version, "3.4.40")
        XCTAssertNotEqual(info.version, BundledRsyncService.bundledVersion)
        XCTAssertTrue(info.diagnostics.contains(where: { $0.contains("version mismatch") }))
    }

    func testMalformedImpersonatorOutputFailsFast() async throws {
        try await assertMalformedVersionOutputFails(output: "not-rsync version 3.4.4 protocol version 32\n")
        try await assertMalformedVersionOutputFails(output: "fake version 3.4.4 protocol version 32\n")
        try await assertMalformedVersionOutputFails(output: "tool version 3.4.4 protocol version 32\n")
        try await assertMalformedVersionOutputFails(output: "warning\nrsync version 3.4.4 protocol version 32\n")
        try await assertMalformedVersionOutputFails(output: "rsync version 3.4.4-custom protocol version 32\n")
        try await assertMalformedVersionOutputFails(output: "")
    }

    func testHangingVersionCommandTimesOut() async throws {
        let rsyncURL = temporaryRoot.appendingPathComponent("rsync-hanging-version")
        try "#!/bin/sh\nsleep 10\n".write(to: rsyncURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: rsyncURL.path)

        let service = BundledRsyncService(bundledExecutableURL: rsyncURL)
        let startedAt = Date()
        let info = await service.bundledInfo()
        let duration = Date().timeIntervalSince(startedAt)

        XCTAssertFalse(info.isAvailable)
        XCTAssertLessThan(duration, 5.0)
        XCTAssertTrue(info.diagnostics.contains(where: { $0.contains("timed out") }))
    }

    func testValidBundledRsyncVersionPasses() async throws {
        let rsyncURL = try executableFile(named: "rsync-valid-version")
        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { url in
                XCTAssertEqual(url, rsyncURL)
                return "rsync version 3.4.4 protocol version 32\n"
            }
        )

        let info = await service.bundledInfo()
        XCTAssertTrue(info.isAvailable)
        XCTAssertEqual(info.executableURL, rsyncURL)
        XCTAssertEqual(info.version, "3.4.4")
    }

    private func executableFile(named name: String) throws -> URL {
        let fileURL = temporaryRoot.appendingPathComponent(name)
        try "#!/bin/sh\nexit 0\n".write(to: fileURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fileURL.path)
        return fileURL
    }

    private func assertMalformedVersionOutputFails(output: String) async throws {
        let rsyncURL = try executableFile(named: "rsync-malformed-\(UUID().uuidString)")
        let service = BundledRsyncService(
            bundledExecutableURL: rsyncURL,
            versionOutputProvider: { url in
                XCTAssertEqual(url, rsyncURL)
                return output
            }
        )

        let info = await service.bundledInfo()
        XCTAssertFalse(info.isAvailable)
        XCTAssertEqual(info.version, "unknown")
        XCTAssertTrue(info.diagnostics.contains(where: { $0.contains("version output unrecognized") }))
    }
}
