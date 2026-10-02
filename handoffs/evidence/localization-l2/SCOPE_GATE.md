# FST EN/VI Localization L2 — Scope Gate

TASK=FST_EN_VI_LOCALIZATION_L2_NOTIFICATION_LOGS_AUDIT
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION
AUTHORIZED_START_HEAD=e4fa800902478899930d04c85a144c6b8d9147ab
START_GATE=PASS;MAIN;CLEAN;HEAD_EQUALS_ORIGIN_MAIN

## Production files changed

- `FishSockTransfer/FishSockTransfer/Localizable.xcstrings`
- `FishSockTransfer/FishSockTransfer/Localization/TransferPresentationLocalization.swift`
- `FishSockTransfer/FishSockTransfer/Views/NotificationTabView.swift`
- `FishSockTransfer/FishSockTransfer/Views/ContentView.swift`
- `FishSockTransfer/Tests/XCTest/LocalizationPresentationXCTests.swift`

The shared lookup keeps the L1 Transfer key allowlist and lookup behavior
unchanged. `ContentView` moves the existing rsync diagnostic match order and
conditions into a testable presentation helper without changing their text,
case-insensitive matching, diagnostic input, or status result. The UI localizes
only the derived display status. No new XCTest file or project registration was
needed.

`TerminalLogsView.swift` uses String Catalog keys for its empty-state literals
without source changes. `SettingsView.swift` had no localization defect and is
unchanged.

## Protected surfaces inspected and unchanged

- `Models/NotificationSettings.swift`: enum raw values, Codable and model
  semantics.
- `NotificationMessageFactory`, `NotificationCoordinator`,
  `TelegramNotificationService`, token store/Keychain, notification settings
  store, send callback, and delivery semantics.
- `AppUpdateService.swift` and update request behavior.
- `TerminalLogTextView`, `LogEntry`, log visibility/filtering, serialized log
  content and actual diagnostics.
- `TransferCoordinator`, `TransferViewModel` workflow/safety decisions,
  transfer/verification/report engines, capacity logic, and SAFE TO EJECT.
- `PrivacyInfo.xcprivacy`.

## Capture and tooling boundary

- CodeGraph MCP was unavailable; exact source and tests were inspected directly.
- Capture fixtures are synthetic. No owner media, owner token, Telegram send,
  transfer, or update request was used.
- Catalog edits extend the existing English-source catalog only; no second
  localization mechanism or project target was added.
- No L3 task is proposed.
