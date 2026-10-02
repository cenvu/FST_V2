# FST EN/VI Localization L1 — Validation

TASK=FST EN/VI Localization L1 — Settings + Transfer
TASK_ID=FST_EN_VI_LOCALIZATION_L1_TRANSFER_AND_SETTINGS
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION
PHASE=LOCALIZATION_L1
WORKER_STATUS=LOCALIZATION_L1_IMPLEMENTATION_COMPLETE
BRAIN_REVIEW_STATUS=PENDING
BRAIN_CLASSIFICATION=UNSET
ACCEPTED_STATE=UNSET
ACTIVE_NEXT=NONE
WORKER_PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_LOCALIZATION_L1_REVIEW
DEFAULT_LANGUAGE=ENGLISH
AVAILABLE_LANGUAGES=EN;VI
SETTINGS_SCENE=YES
RUNTIME_LANGUAGE_SWITCH=VERIFIED;MAIN_WINDOW_AND_SETTINGS_OBSERVE_ONE_PERSISTED_PREFERENCE
PERSISTENCE=VERIFIED;ISOLATED_USERDEFAULTS_SUITE_TESTS
TRANSFER_LOCALIZATION=127_CATALOG_ENTRIES_TRANSLATED;TRANSFER_AND_ACCESSIBILITY_COVERAGE_REVIEWED
NOTIFICATION_CONTENT_LOCALIZED=NO
TECH_LOG_CONTENT_LOCALIZED=NO
L2_QUEUE=handoffs/evidence/localization-l1/LOCALIZATION_L2_QUEUE.md

## Implementation

- Uses the app String Catalog at
  `FishSockTransfer/FishSockTransfer/Localizable.xcstrings`, with English source
  language (`en`) and Vietnamese (`vi`). All 127 catalog entries have Vietnamese
  translations.
- `AppLanguage` uses stable raw values `en` and `vi`. The app-level
  `AppLanguagePreference` persists selection under `fst.app.language`, defaults
  safely to English for missing or invalid values, and is observed by both the
  main `WindowGroup` and native `Settings` scene.
- Settings offers the stable endonyms `English` and `Tiếng Việt`. Its single
  General / Language section contains the requested language label, picker
  description, and immediate-application note.
- Main-window and Settings presentation receive the selected SwiftUI
  `Locale`. Computed presentation strings use the bounded String Catalog lookup
  in `Localization/TransferPresentationLocalization.swift`; unknown runtime text
  is returned unchanged and English is the safe fallback.
- The app resource is included through its existing
  `PBXFileSystemSynchronizedRootGroup`; no project metadata was needed for the
  String Catalog resource. The project file adds the explicit localization
  XCTest and its test-support source files because this target uses explicit
  source lists.
- No language state was added to `TransferViewModel` or backend services.
  Manual-check classification still uses the canonical backend marker before
  its visible title is localized. No transfer-state, capacity, report,
  verification, or notification behavior changed.
- `VerificationMode.none` presents `TRANSFER COMPLETE` / `SAO CHÉP HOÀN TẤT`.
  Only the existing canonical safe-to-eject state presents
  `SAFE TO EJECT` / `CÓ THỂ THÁO Ổ AN TOÀN`.

## Runtime state and persistence proof

`LocalizationPresentationXCTests` use isolated `UserDefaults` suites. They
verify fresh English default, persisted `vi`, reconstructed-reader persistence,
persisted `en`, and invalid-value English fallback. The language-switch fixture
keeps one `TransferViewModel` identity, source and destination selections,
verification mode, bandwidth, notification settings, logs, and canonical
`TransferState` unchanged while its visible status changes from English to
Vietnamese. The fixture starts no transfer and its notification service traps
if asked to send.

## String Catalog and app resource

- Catalog JSON validation: PASS.
- Catalog audit: `sourceLanguage=en`; 127 entries; 127 have a Vietnamese
  translation.
- Canonical Debug build: PASS.
- The built app under `.build/FinalFreshDerivedData` contains
  `Contents/Resources/vi.lproj/Localizable.strings`; `plutil -lint` passes.
  Runtime tests load that resource from the built app bundle and verify English,
  Vietnamese, terminal labels, and computed Transfer/capacity labels.
- The supported macOS 13.5 target compiled the locale-aware Foundation lookup.

## Tests

- Debug build: PASS.
- Focused localization + runtime + capacity XCTest run:
  `FOCUSED_TRANSFER_RUNTIME_CAPACITY.xcresult` — 111 passed, 0 failed,
  0 skipped.
- Localization XCTest class covers preference default/persistence/fallback,
  EN/VI catalog lookup, all ten safety terminal translations, copy-complete vs
  safe-to-eject separation in both languages, raw-message/path preservation,
  and state preservation during a language switch.
- Existing standalone `TransferControlsLabelTests`: PASS.
- Full canonical suite from fresh DerivedData:
  `.build/FinalFreshDerivedData` + `FINAL_CANONICAL_TESTS.xcresult` — 291 passed,
  0 failed, 0 skipped. This is the 285 existing tests plus 6 focused
  localization tests.
- `git diff --cached --check`: PASS for the staged implementation and visual
  evidence immediately before handoff publication. A final staged-diff check is
  run after publication and before the single commit.

## Visual evidence

Dark Aqua captures use synthetic fixture data, with FST content geometry at
1120×760 or 900×660 points (the PNGs are 2× backing resolution). The capture
harness records that no transfer started, no notification was sent, and no
update request was made. It uses no owner media and deletes its temporary
fixture folders after capture.

- English: `EN_READY.png`, `EN_SAFE_TO_EJECT.png`, `EN_TRANSFER_COMPLETE.png`,
  `EN_ERROR.png`, `EN_SETTINGS.png`, `EN_READY_MINIMUM.png`.
- Vietnamese: `VI_READY.png`, `VI_SAFE_TO_EJECT.png`,
  `VI_TRANSFER_COMPLETE.png`, `VI_ERROR.png`, `VI_SETTINGS.png`,
  `VI_READY_MINIMUM.png`.
- Additional terminal evidence: `EN_MANUAL_CHECK_REQUIRED.png`,
  `VI_MANUAL_CHECK_REQUIRED.png`, `EN_CANCELLED.png`, `VI_CANCELLED.png`.
- Minimum-width terminal evidence: `EN_SAFE_TO_EJECT_MINIMUM.png`,
  `VI_SAFE_TO_EJECT_MINIMUM.png`, `EN_MANUAL_CHECK_REQUIRED_MINIMUM.png`, and
  `VI_MANUAL_CHECK_REQUIRED_MINIMUM.png`.
- Minimum-window scroll evidence: `EN_READY_MINIMUM_SCROLLED.png` and
  `VI_READY_MINIMUM_SCROLLED.png`.
- Vietnamese diacritics render correctly. At the 900×660 point fixture size,
  tabs, source/destination, capacity metrics, setup controls, terminal status and
  action, and fixed footer remain legible and reachable. The longest safety
  terminal title and manual-check two-action card also fit without truncating
  their status/actions. Lower job metrics can be reached by scrolling; the safety
  status and action remain visible.
- `TRANSFER COMPLETE` and `SAFE TO EJECT` remain visibly distinct. The
  copy-only completion fixture shows only the transfer-complete wording.

## Scope and limitations

- Notification screen contents and Technical Log screen contents remain
  English in L1; their navigation tab labels are localized.
- Unknown backend/runtime errors, raw diagnostics, technical details,
  filesystem/algorithm identifiers, paths, filenames, and numeric values remain
  unchanged.
- CodeGraph MCP was unavailable for this task; production source and tests were
  inspected directly.
- No Telegram send or update request was made.

## Changed production paths

- `FishSockTransfer/FishSockTransfer/FishSockTransferApp.swift`
- `FishSockTransfer/FishSockTransfer/Localization/AppLanguage.swift`
- `FishSockTransfer/FishSockTransfer/Localization/TransferPresentationLocalization.swift`
- `FishSockTransfer/FishSockTransfer/Localizable.xcstrings`
- `FishSockTransfer/FishSockTransfer/Views/SettingsView.swift`
- `FishSockTransfer/FishSockTransfer/Views/ContentView.swift`
- `FishSockTransfer/FishSockTransfer/Views/SourceCardView.swift`
- `FishSockTransfer/FishSockTransfer/Views/DestinationCardView.swift`
- `FishSockTransfer/FishSockTransfer/Views/StorageAnalysisView.swift`
- `FishSockTransfer/FishSockTransfer/Views/TransferControlsView.swift`
- `FishSockTransfer/FishSockTransfer.xcodeproj/project.pbxproj` (explicit XCTest
  source registration only)
- `FishSockTransfer/Tests/XCTest/LocalizationPresentationXCTests.swift`

## Handoff fields

FINAL_SHA=RECORDED_IN_BRAIN_RETURN
REMOTE_SYNC=RECORDED_IN_BRAIN_RETURN
WORKTREE_STATE=RECORDED_IN_BRAIN_RETURN
