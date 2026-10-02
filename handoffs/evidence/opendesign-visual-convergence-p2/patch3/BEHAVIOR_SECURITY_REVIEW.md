# Patch 3 behavior / security review

REVIEW_KIND=IMPLEMENTER_DIFF_INSPECTION;NOT_INDEPENDENT_ACCEPTANCE
SOURCE=NotificationTabView.swift diff from 745022a8039cd237ced073159afbc0478898ae74
PRODUCTION_SCOPE=ONE_AUTHORIZED_FILE

| Requirement | Evidence / finding |
|---|---|
| SecureField stays secure | Exactly the original SecureField("Bot Token", text: $viewModel.telegramBotToken); original Keychain help copy retained. Input modifier is presentation only. |
| Secret protection | Capture uses injected fake store; owner Keychain never queried. Synthetic token only renders masked bullets in all configured/long-error PNGs. Logs print filenames/geometry only; no token output. |
| Enable/chat/event/option bindings | All nine original $viewModel bindings compare equal as multisets; see BEHAVIOR_SCOPE_CHECK.json. All enum allCases/tag/displayLabel sources remain. |
| Settings persistence | Both original onChange blocks byte-identical. No settings store or enum edit. |
| Token persistence | Original persistTelegramBotToken callback unchanged. No Keychain implementation edit. |
| Test action and gating | Original testTelegramNotification() callback and .disabled(viewModel.isSendingTelegramTestMessage) retained exactly. No additional enable-state gate added. |
| Status truth | All four fields still read notificationStatus; connection displayText and '-' fallback retained. Styling is the only nil/value check. No fake connection state or view-level delivery logic. |
| Error inspectability | Values now wrap without a two-line ceiling, support selection and help. Semantic warning color preserves warm Error emphasis and extends it to nonnil last-error summaries. |
| Preview truth | Original NotificationMessageFactory.preview call and source/destination fallbacks retained; selection remains enabled; only mono size/spacing/container changed. |
| No fixture send | NoSendService injection rejects delivery; harness never clicks Test Message. No transfer state start or folder selection occurs. Native captures all completed without reaching send rejection. |
| Safety separation | Full original optional/best-effort safety footnote retained. TransferCoordinator has no notification admission dependency; no Coordinator/ViewModel/model/service/engine/report code changed. Notification cannot alter SAFE TO EJECT admission. |
| View ownership | Helpers only measure/present views. No ViewModel/service/business logic moved into the View. |
| Accepted patches | ContentView, PanelStyle and all Transfer presentation bytes unchanged. Patch 4 Technical Log and Patch 5 polish not started. |
| Prototype semantics | Forbidden prototype literal/validation scan passes; no hard-coded No messages sent in view (production runtime may supply it). |

Existing tests: NotificationCoordinatorXCTests covers disabled/missing configuration, send success/failure/dedup, request security, interval, heartbeat, best-effort independence and safe message paths. TransferViewModelRuntimeXCTests covers in-flight Test Message gating and warning status/rate limiting. No separate NotificationSettingsXCTests, NotificationMessageFactoryXCTests or notification persistence-specific suite exists; no new suites were invented. Existing settings/message checks live inside NotificationCoordinatorXCTests. Persistence callbacks were inspected against exact pre-edit source and actual isolated fixture settings were persisted for configured captures.
