// FST / CenVu | (+84) 842 841 222

import XCTest

final class AppUpdateServiceXCTests: XCTestCase {
    func testEmptyRepositoryFailsGracefullyWithoutNetworkRequest() async {
        let service = AppUpdateService(
            repositoryOwner: "",
            repositoryName: "",
            session: URLSession.fstUpdateTestSession(statusCode: 200, body: Data()),
            currentVersionProvider: { "1.3.0" }
        )

        let state = await service.checkForUpdates()

        XCTAssertEqual(state, .failed(message: "GitHub update repository is not configured."))
        XCTAssertEqual(AppUpdateURLProtocolMock.requestCount, 0)
    }

    func testUpdateAvailableSelectsPreferredDownloadAsset() async throws {
        let releaseJSON = """
        {
          "tag_name": "v1.4.0",
          "name": "FishSock Transfer v1.4.0",
          "html_url": "https://github.com/example/FishSockTransfer/releases/tag/v1.4.0",
          "published_at": "2026-07-05T00:00:00Z",
          "prerelease": false,
          "draft": false,
          "assets": [
            {
              "name": "FishSockTransfer-v1.4.0.zip",
              "browser_download_url": "https://github.com/example/FishSockTransfer/releases/download/v1.4.0/app.zip"
            },
            {
              "name": "FishSockTransfer-v1.4.0.dmg",
              "browser_download_url": "https://github.com/example/FishSockTransfer/releases/download/v1.4.0/app.dmg"
            }
          ]
        }
        """

        let service = AppUpdateService(
            repositoryOwner: "example",
            repositoryName: "FishSockTransfer",
            session: URLSession.fstUpdateTestSession(statusCode: 200, body: Data(releaseJSON.utf8)),
            currentVersionProvider: { "1.3.0" }
        )

        let state = await service.checkForUpdates()

        XCTAssertEqual(
            state,
            .updateAvailable(
                currentVersion: "1.3.0",
                latestVersion: "1.4.0",
                releaseURL: try XCTUnwrap(URL(string: "https://github.com/example/FishSockTransfer/releases/tag/v1.4.0")),
                downloadURL: try XCTUnwrap(URL(string: "https://github.com/example/FishSockTransfer/releases/download/v1.4.0/app.dmg"))
            )
        )
    }

    func testUpToDateWhenLatestIsNotNewer() async throws {
        let releaseJSON = """
        {
          "tag_name": "1.3",
          "name": "FishSock Transfer v1.3",
          "html_url": "https://github.com/example/FishSockTransfer/releases/tag/v1.3",
          "published_at": "2026-07-05T00:00:00Z",
          "prerelease": false,
          "draft": false,
          "assets": []
        }
        """

        let service = AppUpdateService(
            repositoryOwner: "example",
            repositoryName: "FishSockTransfer",
            session: URLSession.fstUpdateTestSession(statusCode: 200, body: Data(releaseJSON.utf8)),
            currentVersionProvider: { "1.3.0" }
        )

        let state = await service.checkForUpdates()

        XCTAssertEqual(
            state,
            .upToDate(
                currentVersion: "1.3.0",
                latestVersion: "1.3.0",
                releaseURL: try XCTUnwrap(URL(string: "https://github.com/example/FishSockTransfer/releases/tag/v1.3"))
            )
        )
    }

    func testInvalidJSONFails() async {
        let service = AppUpdateService(
            repositoryOwner: "example",
            repositoryName: "FishSockTransfer",
            session: URLSession.fstUpdateTestSession(statusCode: 200, body: Data("not-json".utf8)),
            currentVersionProvider: { "1.3.0" }
        )

        let state = await service.checkForUpdates()

        XCTAssertEqual(state, .failed(message: "GitHub release response could not be decoded."))
    }

    func testMalformedLatestVersionFails() async {
        let releaseJSON = """
        {
          "tag_name": "release-candidate",
          "name": "FishSock Transfer",
          "html_url": "https://github.com/example/FishSockTransfer/releases/tag/release-candidate",
          "published_at": "2026-07-05T00:00:00Z",
          "prerelease": false,
          "draft": false,
          "assets": []
        }
        """

        let service = AppUpdateService(
            repositoryOwner: "example",
            repositoryName: "FishSockTransfer",
            session: URLSession.fstUpdateTestSession(statusCode: 200, body: Data(releaseJSON.utf8)),
            currentVersionProvider: { "1.3.0" }
        )

        let state = await service.checkForUpdates()

        XCTAssertEqual(state, .failed(message: "Latest release version is malformed."))
    }
}

private final class AppUpdateURLProtocolMock: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requestCount += 1

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
    static func fstUpdateTestSession(statusCode: Int, body: Data) -> URLSession {
        AppUpdateURLProtocolMock.statusCode = statusCode
        AppUpdateURLProtocolMock.body = body
        AppUpdateURLProtocolMock.requestCount = 0

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AppUpdateURLProtocolMock.self]
        return URLSession(configuration: configuration)
    }
}
