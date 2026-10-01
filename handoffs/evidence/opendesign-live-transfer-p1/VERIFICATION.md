# Phase 1 implementation verification

TASK=OPENDESIGN_LIVE_TRANSFER_CONVERGENCE_PHASE_1
WORKSTREAM_ID=OPENDESIGN_LIVE_TRANSFER_P1
ROLE=IMPLEMENTER
START_HEAD=0c230033eaa413629459c1495c84e26d94bdf1c2
PREFLIGHT=MAIN;FETCHED_ORIGIN;HEAD_EQUALS_ORIGIN_MAIN_EQUALS_START_HEAD;CLEAN
ACTUAL_CODEX_HOME=/Users/cenvu/.antigravity_cockpit/instances/codex/cli-69dff02cc1f2
HARNESS_CONFIGURATION_MUTATION=NONE
ISSUE_SEARCH=gh issue list --state all --search OPENDESIGN_LIVE_TRANSFER --json number,title,state,url
ISSUE_RESULT=EMPTY
DUPLICATE_TASK_SEARCH=NONE_FOUND_IN_TASK_REGISTRY_OR_WORK_HISTORY
CODEGRAPH=UNAVAILABLE;SOURCE_AND_TEST_INSPECTION_USED

Tool logs are gzip-compressed without changing their bytes; inspect with `gzip -dc <log.gz>`.

## Validation commands and actual results

Canonical final Debug build and full suite (exit 0, BUILD SUCCEEDED, TEST SUCCEEDED):

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/fst-p1-derived build test
```

`BUILD_AND_FULL_TEST.log.gz` preserves the command output. `FULL_TEST_SUMMARY.json` is xcresulttool's summary: 285 passed, 0 failed, 0 skipped, including disposable APFS/exFAT capacity image runtime tests.

Final focused state/runtime/capacity/bandwidth (exit 0, TEST SUCCEEDED):

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/fst-p1-derived \
  -resultBundlePath /tmp/fst-p1-focused-final.xcresult \
  -only-testing:FishSockTransferTests/TransferViewModelRuntimeXCTests \
  -only-testing:FishSockTransferTests/MetadataOnlySourceSafetyXCTests \
  -only-testing:FishSockTransferTests/RsyncBandwidthLimitXCTests test
```

`FOCUSED_TEST.log.gz` / `FOCUSED_TEST_SUMMARY.json`: 127 passed, 0 failed, 0 skipped. Capacity model wording checks assert CAPACITY PRECHECK PASSED and APFS/unknown-allocation uncertainty; UI diff preserves Payload/Admission Floor/Available/Margin Above Floor and complete supporting text. Existing tests also cover NONE/copyComplete vs safeToFormat and cancellation/observer safety boundaries.

Full/default standalone presentation suite compiles every production Swift file except the App entry point plus `Tests/TransferControlsLabelTests.swift`:

```text
xcrun swiftc -swift-version 5 -default-isolation MainActor -D DEBUG
  -parse-as-library <all production Swift files except FishSockTransferApp.swift>
  FishSockTransfer/Tests/TransferControlsLabelTests.swift -o /tmp/fst-p1-labels-final
/tmp/fst-p1-labels-final
```

`PRESENTATION_TEST.log.gz`: exit 0, TransferControlsLabelTests passed. It checks actual Picker option values/conversion contract, copy/verify phase presentation, terminal outcomes/retry, cancel guard, technical-log callback and configuration lock. New checks normalize verify fraction, preserve terminal completion distinction, reject nonfinite telemetry and leave cancelled/error phase progress unknown. Test-only dependency/assessment repairs eliminate Keychain access and align the old fixture with accepted capacity-floor policy.

## Native capture and UI checks

```sh
python3 handoffs/evidence/opendesign-live-transfer-p1/capture_native.py \
  BEFORE handoffs/evidence/opendesign-live-transfer-p1
python3 handoffs/evidence/opendesign-live-transfer-p1/capture_native.py \
  AFTER handoffs/evidence/opendesign-live-transfer-p1
python3 handoffs/evidence/opendesign-live-transfer-p1/capture_native.py \
  MIN_DARK handoffs/evidence/opendesign-live-transfer-p1 900 660 dark
```

BEFORE capture completed before production mutation at START_HEAD. AFTER compiles final native View bodies; harness-only ContentView initializer injects the synthetic model in a temporary file. BEFORE/AFTER native content rectangles are 1120×760 points, 2240×1520 PNGs. `PRIMARY_SCREENSHOT_MANIFEST.json` verifies all eight dimensions/bytes/SHA256. `BEFORE_CAPTURE.log.gz`, `AFTER_CAPTURE.log.gz`, `MINIMUM_CAPTURE.log.gz` preserve successful capture output. Additional `MIN_DARK_*`, `LIGHT_*`, QA tab PNGs and scoped fixture code make constraints inspectable.

Both native picker buttons opened directory-only NSOpenPanel and were cancelled. Local native tab clicks produced QA_NOTIFICATION/QA_TECHNICAL_LOG screenshots, inspected manually. Minimum window has visible control/hero metrics and a scrollable lower region; the bottom-current-item capture limitation is disclosed in the gap report. Light tokens preserve explicit readable state labels and native light surfaces. In-process AX traversal is partial, not a VoiceOver acceptance claim.

## Production/manual diff audit

Only ContentView, SourceCardView, DestinationCardView, StorageAnalysisView, TransferControlsView, PanelStyle and Color+State changed in production. Views contain presentation/formatting only; no source access, copy, verify, filesystem, capacity or safety decision moved into them. TransferJobStatusPresentation formats canonical state and observed percentages; it does not select or mutate runtime outcomes. Footer reuses the canonical state-title helper and owns no success gate.

No changes to DriveService, StorageMetadata, DestinationCapacityAssessment, TransferCoordinator, RsyncEngine, VerifyEngine, DestinationActivitySnapshotter, privacy manifest, verification algorithms, bandwidth conversion, Telegram, reports or SAFE TO EJECT criteria. NotificationTabView, TerminalLogsView, FolderPicker and technical-log implementation/content remain unchanged. All fixture telemetry is confined to evidence code/images. No WebView, HTML runtime or JavaScript state-machine port.

`git diff --check` PASS. Git changed-path scope inspected manually and programmatically. Live MCP evidence and exact source snapshots are indexed by `MCP_SOURCE_EVIDENCE.json` and `LIVE_SOURCE_MAP.md`.

BRAIN review remains PENDING, classification/accepted state UNSET; one proposal only: RETURN_TO_BRAIN_FOR_VISUAL_ADJUDICATION. Publication/commit/push/fetch/export final state is captured by canonical handoff and V2.1 packet; no Phase 2 created.
