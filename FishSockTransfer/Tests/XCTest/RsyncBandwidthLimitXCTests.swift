// FST / CenVu | (+84) 842 841 222

import XCTest

final class RsyncBandwidthLimitXCTests: XCTestCase {
    func testPresetConversions() throws {
        XCTAssertEqual(RsyncBandwidthLimit.presetMegabytesPerSecond, [50, 75, 100, 125, 150, 175, 200])
        XCTAssertEqual(RsyncBandwidthLimit.minimumMegabytesPerSecond, 20)
        XCTAssertEqual(RsyncBandwidthLimit.maximumMegabytesPerSecond, 300)
        let mappings = [(50, 51_200), (75, 76_800), (100, 102_400), (125, 128_000),
                        (150, 153_600), (175, 179_200), (200, 204_800)]
        for (megabytes, kib) in mappings {
            XCTAssertEqual(RsyncBandwidthLimit.kibPerSecond(for: megabytes), kib)
            XCTAssertEqual(try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: Double(megabytes)), kib)
            XCTAssertEqual(try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: kib), "--bwlimit=\(kib)")
        }
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
        for value in [19.0, 301.0, Double.nan, -Double.infinity] {
            XCTAssertThrowsError(try RsyncBandwidthLimit.kibPerSecond(forMegabytesPerSecond: value))
        }
    }

    func testInvalidBandwidthErrorOffersPresetsInsteadOfCustomRange() {
        XCTAssertEqual(
            TransferError.invalidBandwidthLimit.errorDescription,
            "Invalid bandwidth limit. Choose a supported bandwidth preset or Unlimited."
        )
    }

    func testMaximumAllowedLimit() throws {
        XCTAssertEqual(
            try RsyncBandwidthLimit.rsyncArgument(forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 300)),
            "--bwlimit=307200"
        )
    }

    func testGeneratedArgumentDoesNotContainRsyncPath() throws {
        let generatedArgument = try RsyncBandwidthLimit.rsyncArgument(
            forKiBPerSecond: RsyncBandwidthLimit.kibPerSecond(for: 125)
        )

        XCTAssertEqual(generatedArgument?.hasPrefix("--bwlimit="), true)
        XCTAssertEqual(generatedArgument?.contains("/usr/bin/rsync"), false)
        XCTAssertEqual(generatedArgument?.contains("/opt/homebrew"), false)
    }
}
