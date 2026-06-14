import XCTest

final class LoggerServiceTests: XCTestCase {
    func testLoggerAppendsLog() async {
        let logger = LoggerService()
        await logger.log(category: .info, message: "Test")
        let logs = await logger.exportLogs()
        XCTAssertTrue(logs.contains("[INFO] Test"))
    }
}
