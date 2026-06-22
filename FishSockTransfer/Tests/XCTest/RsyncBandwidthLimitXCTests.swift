import XCTest

final class RsyncBandwidthLimitXCTests: XCTestCase {
    func testPresetConversions() {
        XCTAssertEqual(RsyncBandwidthLimit.kibPerSecond(for: 50), 51_200)
        XCTAssertEqual(RsyncBandwidthLimit.kibPerSecond(for: 120), 122_880)
        XCTAssertEqual(RsyncBandwidthLimit.kibPerSecond(for: 240), 245_760)
    }

    func testFractionalConversionRoundsPredictably() throws {
        let fractionalLimit = try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: 20.001)
        XCTAssertEqual(fractionalLimit, 20_481)
        XCTAssertEqual(try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: fractionalLimit), "--bwlimit=20481")
    }

    func testUnlimitedOmitsBwlimit() throws {
        XCTAssertNil(try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: nil))
    }

    func testValidLimitProducesBwlimitArgument() throws {
        XCTAssertEqual(
            try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 50)),
            "--bwlimit=51200"
        )
    }

    func testInvalidLimitsThrow() {
        XCTAssertThrowsError(try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: 0))
        XCTAssertThrowsError(try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: -1))
        XCTAssertThrowsError(try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: 1))
        XCTAssertThrowsError(try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: Int.max))
        XCTAssertThrowsError(try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: Double.greatestFiniteMagnitude))
        XCTAssertThrowsError(try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: Double.infinity))
    }

    func testMaximumAllowedLimit() throws {
        XCTAssertEqual(
            try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 300)),
            "--bwlimit=307200"
        )
    }

    func testGeneratedArgumentDoesNotContainRsyncPath() throws {
        let generatedArgument = try RsyncBandwidthLimit.rsyncArgument(
            forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 120)
        )

        XCTAssertEqual(generatedArgument?.hasPrefix("--bwlimit="), true)
        XCTAssertEqual(generatedArgument?.contains("/usr/bin/rsync"), false)
        XCTAssertEqual(generatedArgument?.contains("/opt/homebrew"), false)
    }
}
