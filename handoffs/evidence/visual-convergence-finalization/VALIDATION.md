# Validation — Technical Log finalization

TASK=Visual Convergence Finalization — Technical Log Canonical Match + Copy All Logs
START_HEAD=3c6b449948b415fcc8c9273d5dd396f17d408c69
BRANCH=main
UPSTREAM_AT_START=origin/main;EQUAL_TO_HEAD
WORKTREE_AT_START=DIRTY;PREEXISTING_LOCALIZABLE_XCSTRINGS_REFRESH_PRESERVED
DESTINATION=macOS arm64; macOS 15.7.7
TASK_ISSUE_SEARCH=NO_MATCH_RETURNED
OPENDESIGN_MCP=UNAVAILABLE;TRANSPORT_CLOSED;REPO_SCREENSHOTS_AND_FROZEN_SOURCE_USED
CODEGRAPH_MCP=UNAVAILABLE;DIRECT_SOURCE_INSPECTION_USED

## Implementation evidence

- Copy All Logs uses `TransferViewModel.logs`, the complete currently retained
  runtime log array, not the filtered/visible array or visible text viewport.
  It includes diagnostic entries and writes `[HH:mm:ss] LEVEL message` rows
  matching the Technical Log feed. The entry messages and underlying log
  values are not translated or mutated.
- `testCopyAllLogsWritesCompleteUnfilteredHistoryToClipboard` passed using a
  unique isolated `NSPasteboard`; it asserts visible and filtered diagnostic
  entries both appear, checks exact formatted contents, and covers empty input.
- The production button maps clipboard success/failure to a localized inline
  feedback label. EN/VI String Catalog lookups for all new buttons, help, sheet,
  and success/failure messages are covered by
  `testTechnicalLogActionsAndClipboardFeedbackLocalizeENVI`.
- Existing filtering behavior remains unchanged. The log-detail sheet and
  clipboard action deliberately show/copy the complete retained array.
- Update-check action and transfer/verifying disable behavior are retained.
  No update request was triggered by test or capture fixtures.

## Checks

- Canonical command:
  `xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -derivedDataPath handoffs/evidence/visual-convergence-finalization/FinalDerivedData -resultBundlePath handoffs/evidence/visual-convergence-finalization/CANONICAL_SCHEME_TESTS.xcresult`
- Result: **298 passed, 0 failed, 0 skipped**. The test log is
  `CANONICAL_SCHEME_TESTS.log`; the `.xcresult` is retained.
- The first full run of the final feedback-timing change had 297 passed and
  one failure in `testDisposableExfatLogicalWarningAndVerifiedCopy`: its first
  `hdiutil detach` returned Resource busy after the fixture's expected ENOSPC
  transfer proof. The fixture retried detach, emitted `CLEANUP=PASS`, and
  removed its UUID temp root. Read-only `hdiutil info` and `diskutil list`
  checks showed no attached test image. A second full run used a new DerivedData
  directory and passed 298/0/0. The first attempt is retained locally as
  `CANONICAL_SCHEME_TESTS_ATTEMPT1.log` and `.xcresult`.
- Focused clipboard test: **1 passed, 0 failed, 0 skipped** using an isolated
  pasteboard (`COPY_CLIPBOARD_TEST_RETRY.xcresult`).
- Focused localization group: **13 passed, 0 failed, 0 skipped**
  (`LOCALIZATION_TESTS.xcresult`). This includes catalog language switching,
  existing EN/VI terminal semantics, and new action/feedback translations.
- Built app contains `vi.lproj/Localizable.strings`; `plutil -lint` passed for
  that resource and the Xcode project file.
- EN/VI native SwiftUI captures completed at 1120×760pt and 900×660pt; see
  `CAPTURE_METHOD.md` and `VISUAL_COMPARISON.md`.
- `git diff --check` passed before handoff publication; final publication
  recheck is recorded by the handoff/export gate.

The repository ignores `*.log` and `*.xcresult`; these command/result files are
retained in the local evidence directory. The committed validation summary,
test source, screenshots, and capture harness remain under this evidence path.

No source media, real transfer, verification operation, Telegram send, or
update request was used.
