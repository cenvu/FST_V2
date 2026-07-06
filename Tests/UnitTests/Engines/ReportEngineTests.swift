// FST / CenVu | (+84) 842 841 222

import XCTest

final class ReportEngineTests: XCTestCase {
    
    func testGenerateReportText() async throws {
        let engine = ReportEngine()
        let report = TransferReport(
            date: "2026-06-14",
            time: "01:30:00",
            sourcePath: "/Volumes/SourceCard",
            destinationPath: "/Volumes/DestDrive",
            totalSize: 104857600, // 100 MB
            fileCount: 42,
            copyDuration: 3665, // 1h 1m 5s
            verificationDuration: 30,
            totalDuration: 3695,
            copyAverageSpeed: 120.5,
            verificationMode: .random33,
            verificationResult: .passed,
            errorCount: 0,
            finalStatus: .safeToFormat
        )
        
        let text = await engine.generateReportText(
            report: report,
            bandwidthLimit: RsyncBandwidthLimit.kibPerSecond(for: 240)
        )
        
        XCTAssertTrue(text.contains("Report Created:      2026-06-14 01:30:00"))
        XCTAssertTrue(text.contains("Source Path:         /Volumes/SourceCard"))
        XCTAssertTrue(text.contains("Destination Path:    /Volumes/DestDrive"))
        XCTAssertTrue(text.contains("Total Files:         42"))
        XCTAssertTrue(text.contains("Total Size:          100.00 MB"))
        XCTAssertTrue(text.contains("Bandwidth Limit:     240 MB/s"))
        XCTAssertTrue(text.contains("Copy Duration:       01:01:05"))
        XCTAssertTrue(text.contains("Verification Mode:   SHA256 Sample 33%"))
        XCTAssertTrue(text.contains("Verification Result: PASSED"))
        XCTAssertTrue(text.contains("Error Count:         0"))
        XCTAssertTrue(text.contains("Final Status:        SAFE TO EJECT DESTINATION"))
        XCTAssertFalse(text.contains(["SAFE", "TO", "FORMAT"].joined(separator: " ")))
    }
    
    func testGenerateReportTextWithoutVerification() async throws {
        let engine = ReportEngine()
        let report = TransferReport(
            date: "2026-06-14",
            time: "02:00:00",
            sourcePath: "/Volumes/SourceCard",
            destinationPath: "/Volumes/DestDrive",
            totalSize: 5242880, // 5 MB
            fileCount: 2,
            copyDuration: 12,
            totalDuration: 12,
            copyAverageSpeed: 50.0,
            verificationMode: .none,
            verificationResult: nil,
            errorCount: 1, // Let's say one error occurred
            finalStatus: .error
        )
        
        let text = await engine.generateReportText(report: report, bandwidthLimit: nil)
        
        XCTAssertTrue(text.contains("Bandwidth Limit:     Unlimited"))
        XCTAssertTrue(text.contains("Verification Result: OFF - NOT VERIFIED BY FST"))
        XCTAssertTrue(text.contains("Final Status:        TRANSFER ERROR"))
        XCTAssertTrue(text.contains("Error Count:         1"))
    }
}
