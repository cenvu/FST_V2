# FST EN/VI Localization L2 Inventory

TASK=FST_EN_VI_LOCALIZATION_L2_NOTIFICATION_LOGS_AUDIT
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION
PHASE=LOCALIZATION_L2_FINAL
BASE=e4fa800902478899930d04c85a144c6b8d9147ab
AUDIT=BEFORE_PRODUCTION_MUTATION
DEFAULT_LANGUAGE=ENGLISH
AVAILABLE_LANGUAGES=EN;VI
CODEGRAPH=UNAVAILABLE;DIRECT_SOURCE_INSPECTION

This inventory was created after reading the L1 inventory, L2 queue, and L1
validation, and before production localization edits. Classification is based
on the current source at `BASE`. String Catalog remains the only localization
system. Static view literals use the app locale; computed presentation is
limited to known English keys and passes unknown runtime text through.

## Candidate classification

| Source | Candidate / observed behavior | Classification | Planned L2 handling |
|---|---|---|---|
| `Views/NotificationTabView.swift` | `Notifications`; `Optional · best-effort · separate from job safety`; `Telegram Setup`; notification safety explanations; enable toggle; `Test Message`; `Notify Events`; five event toggles; `Heartbeat Interval`; `Message Detail`; `Notification Status`; status row labels; `Message Preview`; token Keychain help | `LOCALIZE_STATIC_UI` / `LOCALIZE_ACCESSIBILITY_HELP` | Add English source keys and Vietnamese text to the existing catalog. Preserve the explanatory safety meaning and existing action callback. |
| `Views/NotificationTabView.swift` | `Bot Token`; `Chat ID`; brand name `Telegram` in UI strings | `PRESERVE_TECHNICAL_IDENTIFIER`; `BRAND` | Keep these values unchanged in both languages, with explicit identical Vietnamese catalog entries for the two field identifiers. |
| `Models/NotificationSettings.swift` → `TelegramHeartbeatInterval.displayLabel` | `15 minutes`; `30 minutes` | `LOCALIZE_KNOWN_DYNAMIC_PRESENTATION` | Map the two known model-derived labels in the View/presentation layer. Keep enum integer raw values and Codable behavior unchanged. |
| `Models/NotificationSettings.swift` → `TelegramMessageDetail.displayLabel` | `Compact`; `Standard` | `LOCALIZE_KNOWN_DYNAMIC_PRESENTATION` | Map only the two known picker labels. Keep persisted raw values `Compact` and `Standard`. |
| `Models/NotificationSettings.swift` / `NotificationTabView.swift` | Telegram status `Disabled`, `Not Configured`, `Enabled`; connection `Not Tested`, `Ready`, `Error`; `No messages sent` | `LOCALIZE_KNOWN_DYNAMIC_PRESENTATION` | Translate only these exact known values for display. Retain classification and severity checks against canonical values. |
| `NotificationTabView.swift` / notification services | `Skipped: Telegram notification disabled`, `Telegram not configured`, duplicate-event details, `Sent … at …`, `Telegram send failed`, `Unable to save Telegram token`; any unrecognized status or error | `PRESERVE_RAW_RUNTIME` | Display raw status/error text unchanged unless it is one of the exact allowlisted status keys above. Never translate arbitrary `lastErrorSummary`. |
| `NotificationTabView.swift` → preview | `NotificationMessageFactory.preview(...)`, source/destination names and factory body | `PRESERVE_OUTBOUND_MESSAGE`; `PRESERVE_PATH_FILENAME_URL` | Keep preview body identical to the production factory output. It may remain English. Do not localize names, paths, or payload. |
| `Models/NotificationSettings.swift` | Persisted `Compact` / `Standard`, heartbeat integer raw values, event/settings fields and Codable representation | `PRESERVE_PERSISTED_RAW_VALUE` | No model or persistence edits planned. |
| `Views/ContentView.swift` | `Technical Log`; `Operational runtime log · Diagnostics optional`; `Show Diagnostics`; `Auto-scroll active`; visible/total entry summary; `Filtering does not change the complete log.` | `LOCALIZE_STATIC_UI` / `LOCALIZE_KNOWN_DYNAMIC_PRESENTATION` | Localize static shell copy and the count wrapper while preserving numeric counts and filtering behavior. |
| `Views/TerminalLogsView.swift` | `No log entries yet`; `Select source and destination, then start a job.` | `LOCALIZE_STATIC_UI` | Localize only the empty-state presentation. |
| `Views/TerminalLogsView.swift` → `TerminalLogTextView` | Timestamp, `log.level`, `log.message`, category/color classification, raw stderr/stdout, paths and diagnostic text | `PRESERVE_RAW_RUNTIME`; `PRESERVE_TECHNICAL_IDENTIFIER`; `PRESERVE_PATH_FILENAME_URL` | Keep attributed line construction and source `LogEntry` values unchanged. No catalog lookup is applied to log content. |
| `Views/ContentView.swift` → `TechnicalLogsMetadataFooter` | `version`, `bundled rsync`, `license`; badge help strings; `Checking...`; `Up to date`; `Update available: v%@`; `View Release`; `Download`; `Update check failed`; `Check for Updates`; update-check help | `LOCALIZE_STATIC_UI` / `LOCALIZE_ACCESSIBILITY_HELP` | Localize labels, known updater presentation states, actions, and help. Do not trigger checks except the existing explicit action. |
| `Views/ContentView.swift` → metadata values | `v1.3.5`, bundled rsync version, license text `Source Available / Non-Commercial`, GitHub release/download URLs | `PRESERVE_TECHNICAL_IDENTIFIER`; `PRESERVE_PATH_FILENAME_URL`; `INTENTIONALLY_ENGLISH_LEGAL_VALUE` | Keep versions, URLs, and legal/product value byte-for-byte. |
| `Models/AppUpdateState.swift`, `ViewModels/TechnicalLogsUpdateViewModel.swift` | Typed updater state consumed by the view | `PRESERVE_RAW_RUNTIME` | No state/network behavior edits planned; localize only known view presentation. |
| `Services/AppUpdateService.swift` | Update-service log lines, response/error messages, network request and URLs | `PRESERVE_RAW_RUNTIME`; `PRESERVE_TECHNICAL_IDENTIFIER`; `PRESERVE_PATH_FILENAME_URL` | Preserve exact log/error content and network behavior. No production service edits planned. |
| `Views/ContentView.swift` → `rsyncHeaderBadgeText` | `Bundled rsync missing`, `not executable`, `wrong version …`, `timeout`, `invalid`, `unavailable`, and available version wrapper | `LOCALIZE_KNOWN_DYNAMIC_PRESENTATION` | Preserve each existing diagnostic classification condition and raw diagnostic. Localize the derived visible wrapper only; preserve the version suffix. |
| `Views/ContentView.swift` → `HeaderSocialLinksView` | `Open CenVu Facebook`, `Open CenVu Instagram`, `Message CenVu on WhatsApp`, `Message CenVu on Telegram` | `LOCALIZE_ACCESSIBILITY_HELP` | Localize spoken descriptions; preserve `CenVu`, service names, URLs, and brand-only tooltips. |
| `Views/ContentView.swift` → social links | `FST`; `CenVu`; `Facebook`; `Instagram`; `WhatsApp`; `Telegram`; brand-only tooltips | `PRESERVE_TECHNICAL_IDENTIFIER` | Preserve brand names inside translated accessibility labels and keep tooltips as the unchanged brand name. |
| `Views/ContentView.swift` | Product name `CenVu D.I.T Tools`, social URLs | `PRESERVE_TECHNICAL_IDENTIFIER`; `PRESERVE_PATH_FILENAME_URL` | Keep the product identity and URLs unchanged. |
| `Views/SettingsView.swift` | `General`, `Language`, `Application Language`, `Changes apply immediately.` | `ALREADY_LOCALIZED_L1` | Verify EN/VI catalog switching; do not change settings semantics. |
| `Views/SettingsView.swift` / `Localization/AppLanguage.swift` | Endonyms `English`, `Tiếng Việt` | `ALREADY_LOCALIZED_L1` | L1 intentionally keeps language endonyms stable via `Text(verbatim:)`; they do not change with the selected locale. |
| `Views/ContentView.swift` | `NOTIFICATION` tab label and L1 Transfer/footer presentation | `ALREADY_LOCALIZED_L1` | Preserve the accepted L1 strings and presentation behavior; use regression captures/tests. |
| `Localizable.xcstrings` | Existing L1 entries, English source, Vietnamese translations | `ALREADY_LOCALIZED_L1` | Extend this catalog only. New L2 UI entries require Vietnamese translations. |

## Boundaries confirmed before editing

- Notification UI changes are presentation-only. No token, Chat ID, Keychain,
  settings persistence, test-send callback, coordinator, or service behavior is
  changed.
- The notification factory preview is outbound Telegram content and stays
  exactly as generated by `NotificationMessageFactory.preview(...)`.
- Technical Log localization applies only to its shell and empty state.
  `TerminalLogTextView` keeps exact underlying runtime line content.
- The existing rsync diagnostic checks remain the classification authority;
  only their visible derived wrapper is eligible for translation.
- Existing L1 Transfer lookup and Settings endonyms are regression-protected.
- `AppUpdateService` request behavior and service log strings remain unchanged.

## Direct authorities read

- `AGENTS.md`
- HOT header of `handoffs/CURRENT_HANDOFF.md`
- `FST_AI/memory/BRAIN_OPERATOR_COMPACT.md`
- L1 `LOCALIZATION_INVENTORY.md`, `LOCALIZATION_L2_QUEUE.md`, and `VALIDATION.md`
- `docs/01_PRD.md` FR-010/FR-011 and report boundary
- `docs/02_FST_TECHNICAL_GUIDE.md` architecture, Technical Logs UI rules, and logging rules
- Current target views, models, update service/view model, localization helper,
  String Catalog, and focused notification/log/update/localization tests
