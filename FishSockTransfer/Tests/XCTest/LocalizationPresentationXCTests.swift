// FST / CenVu | (+84) 842 841 222

import Foundation
import AppKit
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

    func testNotificationStaticAndKnownDynamicPresentationENVI() throws {
        let bundle = try localizationAppBundle()
        let english = AppLanguage.english.locale
        let vietnamese = AppLanguage.vietnamese.locale
        let notifications: [(String, String)] = [
            ("Notifications", "Thông báo"),
            ("Optional · best-effort · separate from job safety", "Tùy chọn · cố gắng tối đa · độc lập với an toàn tác vụ"),
            ("Telegram Setup", "Thiết lập Telegram"),
            ("Notification delivery never changes transfer or verification results.", "Việc gửi thông báo không làm thay đổi kết quả sao chép hoặc xác minh."),
            ("Enable Telegram Notification", "Bật thông báo Telegram"),
            ("Bot Token", "Bot Token"),
            ("Chat ID", "Chat ID"),
            ("Test Message", "Gửi thử"),
            ("Notify Events", "Sự kiện thông báo"),
            ("Job starts", "Bắt đầu tác vụ"),
            ("Heartbeat while running", "Trạng thái định kỳ khi đang chạy"),
            ("Transfer fails", "Sao chép thất bại"),
            ("Copy completed", "Sao chép hoàn tất"),
            ("Verify completed / Safe to eject", "Xác minh hoàn tất / Có thể tháo ổ an toàn"),
            ("Heartbeat Interval", "Chu kỳ trạng thái"),
            ("Message Detail", "Mức chi tiết"),
            ("Notification Status", "Trạng thái thông báo"),
            ("Telegram status", "Trạng thái Telegram"),
            ("Connection status", "Trạng thái kết nối"),
            ("Last message", "Tin nhắn gần nhất"),
            ("Last error", "Lỗi gần nhất"),
            ("Message Preview", "Xem trước tin nhắn"),
            ("Stored in Keychain. The token is not shown in plain text.", "Được lưu trong Keychain. Token không hiển thị ở dạng văn bản thông thường."),
            ("Telegram notification is optional and best-effort. It never changes transfer, verify, report, or SAFE TO EJECT results.", "Thông báo Telegram là tùy chọn và sẽ cố gắng gửi tối đa. Thông báo không làm thay đổi kết quả sao chép, xác minh, báo cáo hoặc trạng thái CÓ THỂ THÁO Ổ AN TOÀN.")
        ]
        for (source, translated) in notifications {
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: english, bundle: bundle), source)
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: vietnamese, bundle: bundle), translated)
        }

        let dynamicValues: [(String, String)] = [
            ("15 minutes", "15 phút"),
            ("30 minutes", "30 phút"),
            ("Compact", "Gọn"),
            ("Standard", "Tiêu chuẩn"),
            ("Disabled", "Đã tắt"),
            ("Not Configured", "Chưa cấu hình"),
            ("Enabled", "Đã bật"),
            ("Not Tested", "Chưa kiểm tra"),
            ("Ready", "Sẵn sàng"),
            ("Error", "Lỗi"),
            ("No messages sent", "Chưa gửi tin nhắn")
        ]
        for (source, translated) in dynamicValues {
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: english, bundle: bundle), source)
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: vietnamese, bundle: bundle), translated)
        }

        XCTAssertEqual(TelegramHeartbeatInterval.fifteenMinutes.rawValue, 15)
        XCTAssertEqual(TelegramHeartbeatInterval.thirtyMinutes.rawValue, 30)
        XCTAssertEqual(TelegramMessageDetail.compact.rawValue, "Compact")
        XCTAssertEqual(TelegramMessageDetail.standard.rawValue, "Standard")

        let runtimeError = "synthetic Telegram transport error: HTTP 503 / request-id 42"
        let runtimeStatus = "Skipped duplicate heartbeat event"
        XCTAssertEqual(L2PresentationLocalization.text(runtimeError, locale: vietnamese, bundle: bundle), runtimeError)
        XCTAssertEqual(L2PresentationLocalization.text(runtimeStatus, locale: vietnamese, bundle: bundle), runtimeStatus)
    }

    func testNotificationPreviewIsExactFactoryOutputAndLocaleIndependent() throws {
        let bundle = try localizationAppBundle()
        let settings = NotificationSettings(messageDetail: .standard)
        let source = "CARD_A"
        let destination = "RAID_A"
        let preview = NotificationMessageFactory.preview(
            settings: settings,
            sourceName: source,
            destinationName: destination
        )
        let factoryOutput = NotificationMessageFactory.message(
            for: .heartbeat,
            context: NotificationTransferContext(
                sourceName: source,
                destinationName: destination,
                phase: "Copying",
                progressPercent: 42,
                elapsedSeconds: 12 * 60,
                etaSeconds: 18 * 60
            ),
            detail: .standard
        )
        let expected = "FST heartbeat\nSource: CARD_A\nDestination: RAID_A\nPhase: Copying\nProgress: 42%\nElapsed: 12:00\nETA: 18:00"

        XCTAssertEqual(preview, factoryOutput)
        XCTAssertEqual(preview, expected)
        XCTAssertEqual(L2PresentationLocalization.text("Message Preview", locale: AppLanguage.english.locale, bundle: bundle), "Message Preview")
        XCTAssertEqual(L2PresentationLocalization.text("Message Preview", locale: AppLanguage.vietnamese.locale, bundle: bundle), "Xem trước tin nhắn")
        XCTAssertEqual(
            NotificationMessageFactory.preview(settings: settings, sourceName: source, destinationName: destination),
            preview
        )
    }

    func testTechnicalLogShellLocalizesWithoutChangingRawEntries() throws {
        let bundle = try localizationAppBundle()
        let english = AppLanguage.english.locale
        let vietnamese = AppLanguage.vietnamese.locale
        let shell: [(String, String)] = [
            ("Technical Log", "Nhật ký kỹ thuật"),
            ("Operational runtime log · Diagnostics optional", "Nhật ký vận hành · Có thể bật chẩn đoán"),
            ("Show Diagnostics", "Hiện chẩn đoán"),
            ("Auto-scroll active", "Tự cuộn đang bật"),
            ("Filtering does not change the complete log.", "Bộ lọc không thay đổi nhật ký đầy đủ."),
            ("No log entries yet", "Chưa có mục nhật ký"),
            ("Select source and destination, then start a job.", "Chọn nguồn và đích, sau đó bắt đầu tác vụ.")
        ]
        for (source, translated) in shell {
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: english, bundle: bundle), source)
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: vietnamese, bundle: bundle), translated)
        }
        XCTAssertEqual(L2PresentationLocalization.logEntrySummary(visible: 3, total: 7, locale: english, bundle: bundle), "3 visible / 7 total entries")
        XCTAssertEqual(L2PresentationLocalization.logEntrySummary(visible: 3, total: 7, locale: vietnamese, bundle: bundle), "3 mục đang hiển thị / tổng số 7 mục")

        let rawMessage = "rsync: synthetic stderr /Volumes/SYNTHETIC/CARD_A\npermission denied"
        let entry = LogEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            timestamp: Date(timeIntervalSince1970: 123),
            category: .stderr,
            message: rawMessage
        )
        XCTAssertEqual(entry.level, "ERROR")
        XCTAssertEqual(entry.message, rawMessage)
        XCTAssertEqual(entry.timestamp, Date(timeIntervalSince1970: 123))
        XCTAssertEqual(L2PresentationLocalization.text(entry.message, locale: vietnamese, bundle: bundle), rawMessage)
    }

    func testTechnicalLogActionsAndClipboardFeedbackLocalizeENVI() throws {
        let bundle = try localizationAppBundle()
        let strings: [(String, String)] = [
            ("Auto-scroll", "Tự cuộn"),
            ("Show or hide diagnostic entries in the log view.", "Hiện hoặc ẩn các mục chẩn đoán trong nhật ký."),
            ("Automatically scroll to the newest log entries.", "Tự cuộn đến mục nhật ký mới nhất."),
            ("Copy All Logs", "Sao chép toàn bộ nhật ký"),
            ("Copies the complete retained log history, including diagnostic entries.", "Sao chép toàn bộ lịch sử nhật ký hiện có, bao gồm cả các mục chẩn đoán."),
            ("Log details", "Chi tiết nhật ký"),
            ("Open a selectable view of the complete log history.", "Mở chế độ xem có thể chọn văn bản của toàn bộ lịch sử nhật ký."),
            ("Check for Update", "Kiểm tra bản cập nhật"),
            ("All log entries copied to the clipboard, including diagnostics.", "Đã sao chép toàn bộ mục nhật ký vào bộ nhớ tạm, bao gồm cả thông tin chẩn đoán."),
            ("Could not copy logs to the clipboard. Please try again.", "Không thể sao chép nhật ký vào bộ nhớ tạm. Vui lòng thử lại."),
            ("Full log history", "Lịch sử nhật ký đầy đủ"),
            ("All currently retained runtime log entries are shown here, including diagnostics.", "Tại đây hiển thị toàn bộ mục nhật ký vận hành hiện có, bao gồm cả thông tin chẩn đoán."),
            ("Close", "Đóng")
        ]

        for (englishText, vietnameseText) in strings {
            XCTAssertEqual(L2PresentationLocalization.text(englishText, locale: AppLanguage.english.locale, bundle: bundle), englishText)
            XCTAssertEqual(L2PresentationLocalization.text(englishText, locale: AppLanguage.vietnamese.locale, bundle: bundle), vietnameseText)
        }
    }

    @MainActor
    func testCopyAllLogsWritesCompleteUnfilteredHistoryToClipboard() {
        let rawDiagnostic = "DIAG [VERIFY] source=/Volumes/SYNTHETIC/CARD_A · Permission denied"
        let logs = [
            LogEntry(timestamp: Date(timeIntervalSince1970: 1_790_920_000), category: .info, message: "Synthetic visible entry."),
            LogEntry(timestamp: Date(timeIntervalSince1970: 1_790_920_004), category: .verify, message: rawDiagnostic)
        ]
        let visibleLogs = LogVisibilityFilter.operatorVisible(from: logs)
        XCTAssertEqual(visibleLogs.count, 1)
        XCTAssertEqual(logs.count, 2)

        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.clearContents() }

        XCTAssertTrue(TechnicalLogClipboard.copyAll(logs: logs, to: pasteboard))

        let clipboardText = try! XCTUnwrap(pasteboard.string(forType: .string))
        XCTAssertEqual(clipboardText, TechnicalLogClipboard.formattedHistory(logs))
        XCTAssertTrue(clipboardText.contains("Synthetic visible entry."))
        XCTAssertTrue(clipboardText.contains(rawDiagnostic))
        XCTAssertFalse(TechnicalLogClipboard.copyAll(logs: [], to: pasteboard))
    }

    func testMetadataUpdateAndRsyncPresentationENVI() throws {
        let bundle = try localizationAppBundle()
        let english = AppLanguage.english.locale
        let vietnamese = AppLanguage.vietnamese.locale
        let metadata: [(String, String)] = [
            ("version", "phiên bản"),
            ("bundled rsync", "rsync đi kèm"),
            ("license", "giấy phép"),
            ("App version from README.md", "Phiên bản ứng dụng theo README.md"),
            ("Bundled rsync version used by FST", "Phiên bản rsync đi kèm được FST sử dụng"),
            ("Project license from README.md", "Giấy phép dự án theo README.md"),
            ("Checking...", "Đang kiểm tra..."),
            ("Up to date", "Đã cập nhật"),
            ("Update available: v%@", "Có bản cập nhật: v%@"),
            ("View Release", "Xem bản phát hành"),
            ("Download", "Tải xuống"),
            ("Update check failed", "Kiểm tra cập nhật thất bại"),
            ("Check for Updates", "Kiểm tra cập nhật"),
            ("Update checks are disabled while transfer or verification is running.", "Không thể kiểm tra cập nhật khi đang sao chép hoặc xác minh."),
            ("Check GitHub for the latest release", "Kiểm tra bản phát hành mới nhất trên GitHub"),
            ("missing", "không tìm thấy"),
            ("not executable", "không thể thực thi"),
            ("wrong version %@", "sai phiên bản %@"),
            ("timeout", "hết thời gian chờ"),
            ("invalid", "không hợp lệ"),
            ("unavailable", "không khả dụng")
        ]
        for (source, translated) in metadata {
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: english, bundle: bundle), source)
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: vietnamese, bundle: bundle), translated)
        }
        XCTAssertEqual(L2PresentationLocalization.updateAvailable(version: "1.3.6", locale: english, bundle: bundle), "Update available: v1.3.6")
        XCTAssertEqual(L2PresentationLocalization.updateAvailable(version: "1.3.6", locale: vietnamese, bundle: bundle), "Có bản cập nhật: v1.3.6")

        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue("Bundled rsync 3.4.4", isAvailable: true, locale: vietnamese, bundle: bundle), "3.4.4")
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue("Bundled rsync missing", isAvailable: false, locale: english, bundle: bundle), "missing")
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue("Bundled rsync missing", isAvailable: false, locale: vietnamese, bundle: bundle), "không tìm thấy")
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue("Bundled rsync not executable", isAvailable: false, locale: vietnamese, bundle: bundle), "không thể thực thi")
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue("Bundled rsync wrong version 3.3.0", isAvailable: false, locale: vietnamese, bundle: bundle), "sai phiên bản 3.3.0")
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue("Bundled rsync timeout", isAvailable: false, locale: vietnamese, bundle: bundle), "hết thời gian chờ")
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue("Bundled rsync invalid", isAvailable: false, locale: vietnamese, bundle: bundle), "không hợp lệ")
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue("Bundled rsync unavailable", isAvailable: false, locale: vietnamese, bundle: bundle), "không khả dụng")
        let unknownStatus = "Bundled rsync unexpected diagnostic"
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue(unknownStatus, isAvailable: false, locale: vietnamese, bundle: bundle), unknownStatus)

        let classificationCases: [(String, String)] = [
            ("DIAG: NOT EXECUTABLE; missing fallback", "Bundled rsync not executable"),
            ("Bundled file is missing", "Bundled rsync missing"),
            ("version mismatch: found 3.3.0", "Bundled rsync wrong version 3.3.0"),
            ("version command timed out", "Bundled rsync timeout"),
            ("unrecognized rsync output", "Bundled rsync invalid"),
            ("permission denied", "Bundled rsync unavailable")
        ]
        for (diagnostic, expectedStatus) in classificationCases {
            let originalDiagnostic = diagnostic
            let status = L2PresentationLocalization.bundledRsyncStatus(
                isAvailable: false,
                version: "3.3.0",
                firstDiagnostic: diagnostic
            )
            XCTAssertEqual(status, expectedStatus)
            XCTAssertEqual(diagnostic, originalDiagnostic)
            let translatedStatus = L2PresentationLocalization.rsyncStatusValue(
                status,
                isAvailable: false,
                locale: vietnamese,
                bundle: bundle
            )
            XCTAssertNotEqual(translatedStatus, status)
        }
        let availableStatus = L2PresentationLocalization.bundledRsyncStatus(
            isAvailable: true,
            version: "3.4.4",
            firstDiagnostic: "ignored diagnostic"
        )
        XCTAssertEqual(availableStatus, "Bundled rsync 3.4.4")
        XCTAssertEqual(L2PresentationLocalization.rsyncStatusValue(availableStatus, isAvailable: true, locale: vietnamese, bundle: bundle), "3.4.4")

        let socialLabels: [(String, String)] = [
            ("Open CenVu Facebook", "Mở Facebook của CenVu"),
            ("Open CenVu Instagram", "Mở Instagram của CenVu"),
            ("Message CenVu on WhatsApp", "Nhắn tin cho CenVu qua WhatsApp"),
            ("Message CenVu on Telegram", "Nhắn tin cho CenVu qua Telegram")
        ]
        for (source, translated) in socialLabels {
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: english, bundle: bundle), source)
            XCTAssertEqual(L2PresentationLocalization.text(source, locale: vietnamese, bundle: bundle), translated)
        }
    }

    func testSettingsCatalogStringsSwitchAndEndonymsRemainStable() throws {
        let bundle = try localizationAppBundle()
        let settings: [(String, String)] = [
            ("General", "Chung"),
            ("Language", "Ngôn ngữ"),
            ("Application Language", "Ngôn ngữ ứng dụng"),
            ("Changes apply immediately.", "Thay đổi được áp dụng ngay.")
        ]
        for (source, translated) in settings {
            XCTAssertEqual(catalogText(source, locale: AppLanguage.english.locale, bundle: bundle), source)
            XCTAssertEqual(catalogText(source, locale: AppLanguage.vietnamese.locale, bundle: bundle), translated)
        }
        XCTAssertEqual(AppLanguage.english.endonym, "English")
        XCTAssertEqual(AppLanguage.vietnamese.endonym, "Tiếng Việt")
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

    private func catalogText(_ english: String, locale: Locale, bundle: Bundle) -> String {
        let languageCode = locale.identifier
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init) ?? locale.identifier
        guard languageCode == "vi",
              let localizationPath = bundle.path(forResource: languageCode, ofType: "lproj"),
              let localizationBundle = Bundle(path: localizationPath) else {
            return english
        }
        return String(
            localized: String.LocalizationValue(stringLiteral: english),
            table: "Localizable",
            bundle: localizationBundle,
            locale: locale
        )
    }
}
