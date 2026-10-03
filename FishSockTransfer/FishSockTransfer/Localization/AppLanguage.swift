// FST / CenVu | (+84) 842 841 222

import Combine
import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case vietnamese = "vi"

    public var id: String { rawValue }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// Endonyms are intentionally stable and are not translated in Settings.
    public var endonym: String {
        switch self {
        case .english: "English"
        case .vietnamese: "Tiếng Việt"
        }
    }
}

@MainActor
public final class AppLanguagePreference: ObservableObject {
    public static let storageKey = "fst.app.language"

    @Published public private(set) var language: AppLanguage

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let storedValue = userDefaults.string(forKey: Self.storageKey)
        self.language = storedValue.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }

    public func select(_ language: AppLanguage) {
        self.language = language
        userDefaults.set(language.rawValue, forKey: Self.storageKey)
    }

    public func toggleLanguage() {
        select(language == .english ? .vietnamese : .english)
    }
}
