// FST / CenVu | (+84) 842 841 222

import Foundation
import Security

nonisolated public struct TelegramNotificationConfiguration: Equatable, Sendable {
    public let botToken: String
    public let chatID: String

    public init(botToken: String, chatID: String) {
        self.botToken = botToken.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chatID = chatID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isComplete: Bool {
        !botToken.isEmpty && !chatID.isEmpty
    }
}

nonisolated public enum TelegramNotificationError: LocalizedError, Equatable, Sendable {
    case missingConfiguration
    case invalidEndpoint
    case cannotReachAPIHost
    case transport(String)
    case apiRejected(String)

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Telegram bot token or chat ID is missing."
        case .invalidEndpoint:
            return "Telegram endpoint could not be created."
        case .cannotReachAPIHost:
            return "Cannot reach Telegram API host. Check internet/DNS/VPN/firewall."
        case .transport(let message):
            return "Telegram request failed: \(message)"
        case .apiRejected(let message):
            return "Telegram API rejected the message: \(message)"
        }
    }
}

nonisolated public protocol NotificationService: Sendable {
    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws
}

public final class TelegramNotificationService: NotificationService, @unchecked Sendable {
    private struct TelegramSendMessageResponse: Decodable {
        let ok: Bool
        let description: String?
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        let request = try Self.makeSendMessageRequest(message: message, configuration: configuration)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TelegramNotificationError.transport("No HTTP response.")
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                throw TelegramNotificationError.apiRejected("HTTP \(httpResponse.statusCode)")
            }

            let apiResponse: TelegramSendMessageResponse
            do {
                apiResponse = try JSONDecoder().decode(TelegramSendMessageResponse.self, from: data)
            } catch {
                throw TelegramNotificationError.apiRejected("Invalid Telegram response.")
            }

            guard apiResponse.ok else {
                throw TelegramNotificationError.apiRejected(apiResponse.description ?? "Unknown Telegram API error.")
            }
        } catch let error as TelegramNotificationError {
            throw error
        } catch let error as URLError {
            throw Self.sanitizedTransportError(for: error)
        } catch {
            throw TelegramNotificationError.transport(error.localizedDescription)
        }
    }

    nonisolated static func makeSendMessageRequest(
        message: String,
        configuration: TelegramNotificationConfiguration
    ) throws -> URLRequest {
        guard configuration.isComplete else {
            throw TelegramNotificationError.missingConfiguration
        }

        var endpointComponents = URLComponents()
        endpointComponents.scheme = "https"
        endpointComponents.host = "api.telegram.org"
        endpointComponents.path = "/bot\(configuration.botToken)/sendMessage"

        guard let endpoint = endpointComponents.url else {
            throw TelegramNotificationError.invalidEndpoint
        }

        guard endpoint.scheme == "https", endpoint.host == "api.telegram.org" else {
            throw TelegramNotificationError.invalidEndpoint
        }

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "chat_id", value: configuration.chatID),
            URLQueryItem(name: "text", value: message)
        ]

        guard let body = bodyComponents.percentEncodedQuery?.data(using: .utf8) else {
            throw TelegramNotificationError.invalidEndpoint
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = body

        return request
    }

    private static func sanitizedTransportError(for error: URLError) -> TelegramNotificationError {
        switch error.code {
        case .cannotFindHost, .dnsLookupFailed:
            return .cannotReachAPIHost
        default:
            return .transport(error.localizedDescription)
        }
    }
}

nonisolated public protocol TelegramTokenStore {
    func loadToken() throws -> String
    func saveToken(_ token: String) throws
    func deleteToken() throws
}

nonisolated public final class KeychainTelegramTokenStore: TelegramTokenStore {
    private let service = "com.cen.FishSockTransfer.telegram"
    private let account = "botToken"

    public init() {}

    public func loadToken() throws -> String {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return ""
        }

        guard status == errSecSuccess else {
            throw keychainError(status)
        }

        guard let data = result as? Data else {
            return ""
        }

        return String(data: data, encoding: .utf8) ?? ""
    }

    public func saveToken(_ token: String) throws {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            try deleteToken()
            return
        }

        let data = Data(trimmed.utf8)
        var query = baseQuery()
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw keychainError(updateStatus)
        }

        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw keychainError(addStatus)
        }
    }

    public func deleteToken() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw keychainError(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func keychainError(_ status: OSStatus) -> NSError {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)"
        return NSError(domain: "FST.KeychainTelegramTokenStore", code: Int(status), userInfo: [NSLocalizedDescriptionKey: message])
    }
}

nonisolated public final class NotificationSettingsStore {
    private let userDefaults: UserDefaults
    private let tokenStore: TelegramTokenStore
    private let settingsKey = "FST.TelegramNotification.Settings.v1"

    public init(userDefaults: UserDefaults = .standard, tokenStore: TelegramTokenStore = KeychainTelegramTokenStore()) {
        self.userDefaults = userDefaults
        self.tokenStore = tokenStore
    }

    public func loadSettings() -> NotificationSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return .default
        }

        return settings
    }

    public func saveSettings(_ settings: NotificationSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }

        userDefaults.set(data, forKey: settingsKey)
    }

    public func loadBotToken() -> String {
        (try? tokenStore.loadToken()) ?? ""
    }

    public func saveBotToken(_ token: String) throws {
        try tokenStore.saveToken(token)
    }
}
