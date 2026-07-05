// FST / CenVu | (+84) 842 841 222

import XCTest

final class SemanticVersionXCTests: XCTestCase {
    func testLeadingVNormalizes() throws {
        XCTAssertEqual(SemanticVersion(rawValue: "v1.3.0"), SemanticVersion(rawValue: "1.3.0"))
        XCTAssertEqual(SemanticVersion(rawValue: "V1.3.0")?.description, "1.3.0")
    }

    func testMissingPatchDefaultsToZero() throws {
        XCTAssertEqual(SemanticVersion(rawValue: "1.3"), SemanticVersion(rawValue: "1.3.0"))
    }

    func testPatchComparison() throws {
        XCTAssertGreaterThan(
            try XCTUnwrap(SemanticVersion(rawValue: "1.3.1")),
            try XCTUnwrap(SemanticVersion(rawValue: "1.3.0"))
        )
    }

    func testMinorComparisonUsesNumericOrdering() throws {
        XCTAssertGreaterThan(
            try XCTUnwrap(SemanticVersion(rawValue: "1.10.0")),
            try XCTUnwrap(SemanticVersion(rawValue: "1.9.9"))
        )
    }

    func testMajorComparison() throws {
        XCTAssertGreaterThan(
            try XCTUnwrap(SemanticVersion(rawValue: "2.0.0")),
            try XCTUnwrap(SemanticVersion(rawValue: "1.99.99"))
        )
    }

    func testMalformedVersionsFailSafely() {
        XCTAssertNil(SemanticVersion(rawValue: ""))
        XCTAssertNil(SemanticVersion(rawValue: "not-a-version"))
        XCTAssertNil(SemanticVersion(rawValue: "1..3"))
        XCTAssertNil(SemanticVersion(rawValue: "1.2.3.4"))
    }

    func testPrereleaseAndBuildMetadataAreIgnoredForMVPComparison() {
        XCTAssertEqual(SemanticVersion(rawValue: "v1.3.0-beta.1"), SemanticVersion(rawValue: "1.3.0"))
        XCTAssertEqual(SemanticVersion(rawValue: "1.3.0+build.7"), SemanticVersion(rawValue: "1.3.0"))
    }
}
