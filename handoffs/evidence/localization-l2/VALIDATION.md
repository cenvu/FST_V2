# FST EN/VI Localization L2 — Validation

TASK=FST_EN_VI_LOCALIZATION_L2_NOTIFICATION_LOGS_AUDIT
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION
START_HEAD=e4fa800902478899930d04c85a144c6b8d9147ab
START_BRANCH=main
START_WORKTREE=CLEAN
START_HEAD_EQUALS_ORIGIN_MAIN=YES
START_GITHUB_ISSUE_MATCH=NONE_FOUND
CODEGRAPH=UNAVAILABLE;DIRECT_SOURCE_INSPECTION

## Build and test commands

- Canonical Debug build: `xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath .build/FSTLocalizationL2-Debug-20261002-212006 -quiet build` — PASS.
- Focused localization XCTest: `LocalizationPresentationXCTests` — 11 passed, 0 failed, 0 skipped. Result: `.build/FSTLocalizationL2-FocusedFinal-20261002-213702.xcresult`.
- Relevant regression XCTest: `NotificationCoordinatorXCTests`, `LogVisibilityFilterXCTests`, `AppUpdateServiceXCTests`, `TransferViewModelRuntimeXCTests`, `DestinationCapacityPolicyXCTests`, and `DestinationCapacityImageRuntimeXCTests` — 167 passed, 0 failed, 0 skipped. Result: `.build/FSTLocalizationL2-Regression-20261002-212333.xcresult`.
- Standalone `TransferControlsLabelTests` — PASS. It was compiled with the repository production sources and executed from `.build/FSTLocalizationL2-TransferControlsLabelTests`.
- Full canonical XCTest suite from fresh DerivedData — 296 passed, 0 failed, 0 skipped. Result: `.build/FSTLocalizationL2-FinalCanonical-20261002-215506.xcresult`; DerivedData: `.build/FSTLocalizationL2-FinalFreshDerivedData-20261002-215506`.
- `git diff --check` — PASS.

The full run used the `FishSockTransfer` scheme on arm64 macOS 15.7.7 with
parallel testing disabled. `xcresulttool get test-results summary` reports
`result=Passed`, `passedTests=296`, `failedTests=0`, and `skippedTests=0`.

## String Catalog and app resource

- `Localizable.xcstrings`: source `en`, total 195 keys, Vietnamese translated
  keys 195, missing Vietnamese keys 0.
- L2 dynamic presentation allowlist: 68 keys, all present with Vietnamese
  translations.
- The fresh Debug app contains
  `Contents/Resources/vi.lproj/Localizable.strings`; `plutil -lint` returned
  `OK`.
- Settings endonym and catalog switching tests passed. Existing L1 localization
  and runtime-switch tests passed in the full suite.

## Visual and safety validation

- Dark Aqua synthetic captures: 18 PNGs covering all requested screens and
  sizes; see `VISUAL_QA.md` and `EVIDENCE_INDEX.md`.
- No owner media or token was used. The capture harness uses an isolated empty
  token store and a service that traps if called. No notification was sent,
  no transfer started, and no update request was made.
- `NotificationMessageFactory`, notification coordination/service, update
  service, raw `LogEntry` renderer/serialization, transfer engines, and safety
  logic were not changed.

## Compiler/environment notes

Build and standalone compile emitted existing macOS 14 `onChange` deprecation
warnings in the Notification and Transfer views, plus XCTest linking warnings
because the installed XCTest libraries were built for macOS 14 while the app
deployment target is macOS 13.5. These warnings did not fail the Debug build,
focused tests, regression tests, or full suite.
