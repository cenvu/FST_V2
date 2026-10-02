// FST / CenVu | (+84) 842 841 222

import Foundation
import XCTest

private struct LocalizationTestTokenStore: TelegramTokenStore {
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}

private struct LocalizationNoSendService: NotificationService {
    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        preconditionFailure("Localization state-switch fixture must never send a notification")
    }
}

final class LocalizationPresentationXCTests: XCTestCase {
    @MainActor
    func testLanguagePreferenceDefaultsPersistsAndFallsBackSafely() {
        let suiteName = "FSTLanguagePreferenceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertNil(defaults.object(forKey: AppLanguagePreference.storageKey))
        XCTAssertEqual(AppLanguagePreference(userDefaults: defaults).language, .english)

        let preference = AppLanguagePreference(userDefaults: defaults)
        preference.select(.vietnamese)
        XCTAssertEqual(defaults.string(forKey: AppLanguagePreference.storageKey), "vi")
        XCTAssertEqual(AppLanguagePreference(userDefaults: defaults).language, .vietnamese)

        preference.select(.english)
        XCTAssertEqual(defaults.string(forKey: AppLanguagePreference.storageKey), "en")
        XCTAssertEqual(AppLanguagePreference(userDefaults: defaults).language, .english)

        defaults.set("xx-invalid-language", forKey: AppLanguagePreference.storageKey)
        XCTAssertEqual(AppLanguagePreference(userDefaults: defaults).language, .english)
        XCTAssertEqual(AppLanguage.english.endonym, "English")
        XCTAssertEqual(AppLanguage.vietnamese.endonym, "Tiếng Việt")
    }

    func testEnglishAndVietnameseStringCatalogLookup() throws {
        let bundle = try localizationAppBundle()
        XCTAssertEqual(
            TransferPresentationLocalization.text("READY", locale: AppLanguage.english.locale, bundle: bundle),
            "READY"
        )
        XCTAssertEqual(
            TransferPresentationLocalization.text("READY", locale: AppLanguage.vietnamese.locale, bundle: bundle),
            "SẴN SÀNG"
        )
        XCTAssertEqual(
            TransferPresentationLocalization.text("SAFE TO EJECT", locale: AppLanguage.vietnamese.locale, bundle: bundle),
            "CÓ THỂ THÁO Ổ AN TOÀN"
        )

        let dynamicLabels: [(String, String)] = [
            ("TOTAL SIZE", "TỔNG DUNG LƯỢNG"),
            ("FILES", "TỆP"),
            ("FOLDERS", "THƯ MỤC"),
            ("FILESYSTEM", "HỆ TỆP"),
            ("FREE SPACE", "DUNG LƯỢNG TRỐNG"),
            ("WRITABLE", "CÓ THỂ GHI"),
            ("YES", "CÓ"),
            ("NO", "KHÔNG"),
            ("Payload", "Dữ liệu"),
            ("Admission Floor", "Mức tối thiểu cần có"),
            ("Available", "Khả dụng"),
            ("Margin Above Floor", "Phần dư trên mức tối thiểu")
        ]
        for (english, vietnamese) in dynamicLabels {
            XCTAssertEqual(TransferPresentationLocalization.text(english, locale: AppLanguage.english.locale, bundle: bundle), english)
            XCTAssertEqual(TransferPresentationLocalization.text(english, locale: AppLanguage.vietnamese.locale, bundle: bundle), vietnamese)
        }
    }

    func testAllSafetyTerminalPresentationTranslations() throws {
        let bundle = try localizationAppBundle()
        let terminalLabels: [(String, String)] = [
            ("READY", "SẴN SÀNG"),
            ("SETUP REQUIRED", "CẦN THIẾT LẬP"),
            ("PREPARING", "ĐANG CHUẨN BỊ"),
            ("COPYING", "ĐANG SAO CHÉP"),
            ("VERIFYING", "ĐANG XÁC MINH"),
            ("TRANSFER COMPLETE", "SAO CHÉP HOÀN TẤT"),
            ("SAFE TO EJECT", "CÓ THỂ THÁO Ổ AN TOÀN"),
            ("MANUAL CHECK REQUIRED", "CẦN KIỂM TRA THỦ CÔNG"),
            ("TRANSFER ERROR", "LỖI SAO CHÉP"),
            ("CANCELLED", "ĐÃ HỦY")
        ]

        for (english, vietnamese) in terminalLabels {
            XCTAssertEqual(TransferPresentationLocalization.text(english, locale: AppLanguage.english.locale, bundle: bundle), english)
            XCTAssertEqual(TransferPresentationLocalization.text(english, locale: AppLanguage.vietnamese.locale, bundle: bundle), vietnamese)
        }
    }

    func testCopyCompleteAndSafeToEjectRemainDistinctInBothLanguages() throws {
        let bundle = try localizationAppBundle()
        let copyCompleteKey = TransferActionPresentation.title(for: .copyComplete)
        let safeToEjectKey = TransferActionPresentation.title(for: .safeToFormat)

        XCTAssertEqual(copyCompleteKey, "TRANSFER COMPLETE")
        XCTAssertEqual(safeToEjectKey, "SAFE TO EJECT")
        XCTAssertNotEqual(copyCompleteKey, safeToEjectKey)

        let english = AppLanguage.english.locale
        let vietnamese = AppLanguage.vietnamese.locale
        let copyCompleteEN = TransferPresentationLocalization.text(copyCompleteKey, locale: english, bundle: bundle)
        let safeToEjectEN = TransferPresentationLocalization.text(safeToEjectKey, locale: english, bundle: bundle)
        let copyCompleteVI = TransferPresentationLocalization.text(copyCompleteKey, locale: vietnamese, bundle: bundle)
        let safeToEjectVI = TransferPresentationLocalization.text(safeToEjectKey, locale: vietnamese, bundle: bundle)

        XCTAssertEqual(copyCompleteEN, "TRANSFER COMPLETE")
        XCTAssertEqual(safeToEjectEN, "SAFE TO EJECT")
        XCTAssertEqual(copyCompleteVI, "SAO CHÉP HOÀN TẤT")
        XCTAssertEqual(safeToEjectVI, "CÓ THỂ THÁO Ổ AN TOÀN")
        XCTAssertNotEqual(copyCompleteVI, safeToEjectVI)
    }

    func testUnknownRuntimeTextAndPreviewPathArePreserved() throws {
        let bundle = try localizationAppBundle()
        let unknown = "rsync: synthetic backend detail /Volumes/CARD_A"
        XCTAssertEqual(
            TransferPresentationLocalization.text(unknown, locale: AppLanguage.vietnamese.locale, bundle: bundle),
            unknown
        )

        let preview = "Will create: BACKUP_01/CARD_A"
        XCTAssertEqual(
            TransferPresentationLocalization.destinationTargetPreview(preview, locale: AppLanguage.vietnamese.locale, bundle: bundle),
            "Sẽ tạo: BACKUP_01/CARD_A"
        )
    }

    @MainActor
    func testLanguageSwitchChangesPresentationWithoutResettingTransferFixture() throws {
        let languageSuite = "FSTLanguageSwitchTests-\(UUID().uuidString)"
        let notificationSuite = "FSTLanguageSwitchNotifications-\(UUID().uuidString)"
        let languageDefaults = UserDefaults(suiteName: languageSuite)!
        let notificationDefaults = UserDefaults(suiteName: notificationSuite)!
        defer {
            languageDefaults.removePersistentDomain(forName: languageSuite)
            notificationDefaults.removePersistentDomain(forName: notificationSuite)
        }

        let viewModel = TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil),
            notificationCoordinator: NotificationCoordinator(service: LocalizationNoSendService()),
            notificationSettingsStore: NotificationSettingsStore(
                userDefaults: notificationDefaults,
                tokenStore: LocalizationTestTokenStore()
            )
        )
        viewModel.sourceURL = URL(fileURLWithPath: "/synthetic/source-card", isDirectory: true)
        viewModel.destinationURL = URL(fileURLWithPath: "/synthetic/destination-card", isDirectory: true)
        viewModel.verificationMode = .full
        viewModel.bandwidthLimit = 125
        viewModel.notificationSettings = NotificationSettings(isTelegramEnabled: true, chatID: "fixture-chat")
        viewModel.logs = [LogEntry(timestamp: Date(timeIntervalSince1970: 100), category: .info, message: "fixture log line")]
        viewModel.transferState = .safeToFormat
        viewModel.progress = 100

        let originalIdentity = ObjectIdentifier(viewModel)
        let originalSource = viewModel.sourceURL
        let originalDestination = viewModel.destinationURL
        let originalMode = viewModel.verificationMode
        let originalBandwidth = viewModel.bandwidthLimit
        let originalNotificationSettings = viewModel.notificationSettings
        let originalLogs = viewModel.logs
        let originalState = viewModel.transferState
        let preference = AppLanguagePreference(userDefaults: languageDefaults)
        let bundle = try localizationAppBundle()
        let englishPresentation = TransferPresentationLocalization.text(
            TransferActionPresentation.title(for: viewModel.transferState),
            locale: preference.language.locale,
            bundle: bundle
        )

        preference.select(.vietnamese)

        XCTAssertEqual(preference.language, .vietnamese)
        XCTAssertEqual(TransferPresentationLocalization.text(
            TransferActionPresentation.title(for: viewModel.transferState),
            locale: preference.language.locale,
            bundle: bundle
        ), "CÓ THỂ THÁO Ổ AN TOÀN")
        XCTAssertNotEqual(englishPresentation, "CÓ THỂ THÁO Ổ AN TOÀN")
        XCTAssertEqual(ObjectIdentifier(viewModel), originalIdentity)
        XCTAssertEqual(viewModel.sourceURL, originalSource)
        XCTAssertEqual(viewModel.destinationURL, originalDestination)
        XCTAssertEqual(viewModel.verificationMode, originalMode)
        XCTAssertEqual(viewModel.bandwidthLimit, originalBandwidth)
        XCTAssertEqual(viewModel.notificationSettings, originalNotificationSettings)
        XCTAssertEqual(viewModel.logs, originalLogs)
        XCTAssertEqual(viewModel.transferState, originalState)
        XCTAssertEqual(viewModel.transferState, .safeToFormat)
        XCTAssertFalse(viewModel.isTransferConfigurationLocked)
    }

    private func localizationAppBundle() throws -> Bundle {
        var candidates: [URL] = []
        if let configuredPath = ProcessInfo.processInfo.environment["FST_LOCALIZATION_APP_BUNDLE"] {
            candidates.append(URL(fileURLWithPath: configuredPath, isDirectory: true))
        }
        let testBundleURL = Bundle(for: type(of: self)).bundleURL
        candidates.append(testBundleURL.deletingLastPathComponent().appendingPathComponent("FishSockTransfer.app", isDirectory: true))
        candidates.append(Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("FishSockTransfer.app", isDirectory: true))

        for candidate in candidates where FileManager.default.fileExists(atPath: candidate.path) {
            if let bundle = Bundle(url: candidate) { return bundle }
        }

        throw NSError(
            domain: "FST.LocalizationTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Could not locate the built FishSockTransfer.app String Catalog resources."]
        )
    }
}
