// FST / CenVu | (+84) 842 841 222

import XCTest

final class NotificationCoordinatorXCTests: XCTestCase {
    func testNotificationDisabledSendsNothing() async {
        let service = MockNotificationService()
        let coordinator = NotificationCoordinator(service: service)
        let settings = NotificationSettings(isTelegramEnabled: false, chatID: "123")

        let status = await coordinator.sendTestMessage(
            settings: settings,
            token: "token",
            context: context()
        )

        XCTAssertEqual(service.sentMessages(), [])
        XCTAssertEqual(status.telegramStatus, "Disabled")
        XCTAssertEqual(status.lastMessageStatus, "Skipped: Telegram notification disabled")
    }

    func testMissingTokenOrChatIDHandledSafely() async {
        let service = MockNotificationService()
        let coordinator = NotificationCoordinator(service: service)

        let missingToken = await coordinator.sendTestMessage(
            settings: NotificationSettings(isTelegramEnabled: true, chatID: "123"),
            token: "",
            context: context()
        )
        XCTAssertEqual(missingToken.telegramStatus, "Not Configured")
        XCTAssertEqual(missingToken.connectionStatus, .error)

        let missingChat = await coordinator.sendTestMessage(
            settings: NotificationSettings(isTelegramEnabled: true, chatID: ""),
            token: "token",
            context: context()
        )
        XCTAssertEqual(missingChat.telegramStatus, "Not Configured")
        XCTAssertEqual(missingChat.connectionStatus, .error)
        XCTAssertEqual(service.sentMessages(), [])
    }

    func testTestMessageSuccessPath() async {
        let service = MockNotificationService()
        let coordinator = NotificationCoordinator(service: service)

        let status = await coordinator.sendTestMessage(
            settings: enabledSettings(),
            token: "token",
            context: context()
        )

        XCTAssertEqual(status.telegramStatus, "Enabled")
        XCTAssertEqual(status.connectionStatus, .ready)
        XCTAssertTrue(status.lastMessageStatus.contains("test message"))
        XCTAssertEqual(service.sentMessages().count, 1)
    }

    func testTestMessageFailurePathDoesNotThrow() async {
        let service = MockNotificationService(error: TelegramNotificationError.transport("offline"))
        let coordinator = NotificationCoordinator(service: service)

        let status = await coordinator.sendTestMessage(
            settings: enabledSettings(),
            token: "token",
            context: context()
        )

        XCTAssertEqual(status.telegramStatus, "Enabled")
        XCTAssertEqual(status.connectionStatus, .error)
        XCTAssertEqual(status.lastMessageStatus, "Telegram send failed")
        XCTAssertTrue(status.lastErrorSummary?.contains("offline") == true)
        XCTAssertEqual(service.sentMessages().count, 1)
    }

    func testTelegramHTTP200WithInvalidJSONIsSurfacedAsError() async throws {
        let session = URLSession.fstTestSession(
            statusCode: 200,
            body: Data("not-json".utf8)
        )
        let service = TelegramNotificationService(session: session)

        do {
            try await service.sendMessage(
                "test",
                configuration: TelegramNotificationConfiguration(botToken: "token", chatID: "123")
            )
            XCTFail("Invalid Telegram JSON must not be treated as a successful send.")
        } catch let error as TelegramNotificationError {
            XCTAssertEqual(error, .apiRejected("Invalid Telegram response."))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testHeartbeatIntervalSupportsOnlyFifteenAndThirtyMinutes() {
        XCTAssertEqual(TelegramHeartbeatInterval.allCases.map(\.rawValue), [15, 30])
        XCTAssertEqual(TelegramHeartbeatInterval.from(minutes: 15), .fifteenMinutes)
        XCTAssertEqual(TelegramHeartbeatInterval.from(minutes: 30), .thirtyMinutes)
        XCTAssertEqual(TelegramHeartbeatInterval.from(minutes: 5), .fifteenMinutes)
        XCTAssertEqual(NotificationSettings.default.heartbeatInterval, .fifteenMinutes)
    }

    func testHeartbeatThrottlingWorks() async {
        let service = MockNotificationService()
        let coordinator = NotificationCoordinator(service: service)
        let start = Date()
        await coordinator.markRunningStarted(now: start)

        let beforeInterval = await coordinator.sendHeartbeatIfDue(
            settings: enabledSettings(heartbeatInterval: .fifteenMinutes),
            token: "token",
            context: context(phase: "Copying"),
            now: start.addingTimeInterval(14 * 60)
        )
        XCTAssertNil(beforeInterval)

        let due = await coordinator.sendHeartbeatIfDue(
            settings: enabledSettings(heartbeatInterval: .fifteenMinutes),
            token: "token",
            context: context(phase: "Copying"),
            now: start.addingTimeInterval(15 * 60)
        )
        XCTAssertEqual(due?.connectionStatus, .ready)
        XCTAssertEqual(service.sentMessages().count, 1)

        let tooSoonAgain = await coordinator.sendHeartbeatIfDue(
            settings: enabledSettings(heartbeatInterval: .fifteenMinutes),
            token: "token",
            context: context(phase: "Copying"),
            now: start.addingTimeInterval(16 * 60)
        )
        XCTAssertNil(tooSoonAgain)
        XCTAssertEqual(service.sentMessages().count, 1)
    }

    func testFailedHeartbeatAttemptIsThrottledUntilNextInterval() async {
        let service = MockNotificationService(error: TelegramNotificationError.transport("offline"))
        let coordinator = NotificationCoordinator(service: service)
        let start = Date()
        await coordinator.markRunningStarted(now: start)

        let failed = await coordinator.sendHeartbeatIfDue(
            settings: enabledSettings(heartbeatInterval: .fifteenMinutes),
            token: "token",
            context: context(phase: "Copying"),
            now: start.addingTimeInterval(15 * 60)
        )
        XCTAssertEqual(failed?.connectionStatus, .error)
        XCTAssertEqual(service.sentMessages().count, 1)

        let tooSoon = await coordinator.sendHeartbeatIfDue(
            settings: enabledSettings(heartbeatInterval: .fifteenMinutes),
            token: "token",
            context: context(phase: "Copying"),
            now: start.addingTimeInterval(16 * 60)
        )
        XCTAssertNil(tooSoon)
        XCTAssertEqual(service.sentMessages().count, 1)

        let nextInterval = await coordinator.sendHeartbeatIfDue(
            settings: enabledSettings(heartbeatInterval: .fifteenMinutes),
            token: "token",
            context: context(phase: "Copying"),
            now: start.addingTimeInterval(30 * 60)
        )
        XCTAssertEqual(nextInterval?.connectionStatus, .error)
        XCTAssertEqual(service.sentMessages().count, 2)
    }

    func testFailureSendsImmediately() async {
        let service = MockNotificationService()
        let coordinator = NotificationCoordinator(service: service)

        let status = await coordinator.notifyFailure(
            settings: enabledSettings(),
            token: "token",
            context: context(phase: "Transfer Error", failureSummary: "MANUAL CHECK REQUIRED")
        )

        XCTAssertEqual(status?.connectionStatus, .ready)
        XCTAssertEqual(service.sentMessages().count, 1)
        XCTAssertTrue(service.sentMessages().first?.contains("Do NOT format source media") == true)
    }

    func testVerifiedSuccessSendsOnce() async {
        let service = MockNotificationService()
        let coordinator = NotificationCoordinator(service: service)
        let settings = enabledSettings()

        _ = await coordinator.notifyVerifiedSuccess(settings: settings, token: "token", context: context(phase: "SAFE TO EJECT"))
        _ = await coordinator.notifyVerifiedSuccess(settings: settings, token: "token", context: context(phase: "SAFE TO EJECT"))

        XCTAssertEqual(service.sentMessages().count, 1)
        XCTAssertTrue(service.sentMessages().first?.contains("SAFE TO EJECT / VERIFIED OK") == true)
    }

    func testTelegramFailureDoesNotFailTransferJobPath() async {
        let service = MockNotificationService(error: TelegramNotificationError.apiRejected("bad chat"))
        let coordinator = NotificationCoordinator(service: service)

        let status = await coordinator.notifyFailure(
            settings: enabledSettings(),
            token: "token",
            context: context(phase: "Transfer Error")
        )

        XCTAssertEqual(status?.connectionStatus, .error)
        XCTAssertTrue(status?.lastErrorSummary?.contains("bad chat") == true)
    }

    func testMessagesDoNotIncludeUnsafeFullPathsByDefault() {
        let sourceURL = URL(fileURLWithPath: "/Volumes/CARD_A/DCIM", isDirectory: true)
        let destinationURL = URL(fileURLWithPath: "/Volumes/RAID/PROJECT_A", isDirectory: true)
        let message = NotificationMessageFactory.message(
            for: .heartbeat,
            context: NotificationTransferContext(
                sourceName: sourceURL.path,
                destinationName: destinationURL.path,
                phase: "Copying",
                progressPercent: 42,
                elapsedSeconds: 60,
                etaSeconds: 90
            )
        )

        XCTAssertFalse(NotificationMessageFactory.containsUnsafePath(message, sourceURL: sourceURL, destinationURL: destinationURL))
        XCTAssertFalse(message.contains("/Volumes/"))
        XCTAssertTrue(message.contains("DCIM"))
        XCTAssertTrue(message.contains("PROJECT_A"))
    }

    func testFailureSummaryDoesNotLeakFullPath() {
        let sourceURL = URL(fileURLWithPath: "/Volumes/CARD_A/DCIM", isDirectory: true)
        let message = NotificationMessageFactory.message(
            for: .transferFailed,
            context: NotificationTransferContext(
                sourceName: sourceURL.path,
                destinationName: "RAID_A",
                phase: "Transfer Error",
                progressPercent: 12,
                elapsedSeconds: 60,
                failureSummary: "Read failed at /Volumes/CARD_A/DCIM/A001.mov"
            )
        )

        XCTAssertFalse(message.contains("/Volumes/CARD_A"))
        XCTAssertTrue(message.contains("See FST report and technical log for details."))
        XCTAssertTrue(message.contains("Do NOT format source media"))
    }

    private func enabledSettings(
        heartbeatInterval: TelegramHeartbeatInterval = .fifteenMinutes
    ) -> NotificationSettings {
        NotificationSettings(
            isTelegramEnabled: true,
            chatID: "123",
            heartbeatInterval: heartbeatInterval
        )
    }

    private func context(
        phase: String = "Copying",
        failureSummary: String? = nil
    ) -> NotificationTransferContext {
        NotificationTransferContext(
            sourceName: "CARD_A",
            destinationName: "RAID_A",
            phase: phase,
            progressPercent: 42,
            elapsedSeconds: 60,
            etaSeconds: 120,
            failureSummary: failureSummary
        )
    }
}

private final class MockNotificationService: NotificationService, @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        lock.lock()
        messages.append(message)
        lock.unlock()

        if let error {
            throw error
        }
    }

    func sentMessages() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return messages
    }
}

private final class TelegramURLProtocolMock: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var body = Data()

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private extension URLSession {
    static func fstTestSession(statusCode: Int, body: Data) -> URLSession {
        TelegramURLProtocolMock.statusCode = statusCode
        TelegramURLProtocolMock.body = body

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TelegramURLProtocolMock.self]
        return URLSession(configuration: configuration)
    }
}
