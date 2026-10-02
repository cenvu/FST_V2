# Patch 3 validation record

RESULT=FAIL
BLOCKER=FULL_CANONICAL_TEST_INFRA_FAILURE
BUILD=SUCCEEDED
FOCUSED_TESTS=SUCCEEDED;102_PASSED;0_FAILED;0_SKIPPED
FULL_TEST_FIRST=FAILED;284_PASSED;1_FAILED;0_SKIPPED
FULL_TEST_SERIAL_RETRY=FAILED;284_PASSED;1_FAILED;0_SKIPPED
RETRY_COUNT=1
FULL_TEST_SUCCEEDED_REQUIREMENT=NOT_MET
DIFF_CHECK=PASS
PRODUCTION_SCOPE=PASS
BEHAVIOR_SECURITY_INSPECTION=PASS
VISUAL_ACCEPTANCE=PENDING_BRAIN

Canonical Debug build (exit 0; BUILD.log preserves BUILD SUCCEEDED):

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/fst-patch3-derived build
```

Focused existing notification/runtime tests (exit 0; TEST_FOCUSED.log and TEST_FOCUSED_SUMMARY.json):

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/fst-patch3-derived -resultBundlePath /tmp/fst-patch3-focused.xcresult -parallel-testing-enabled NO -only-testing:FishSockTransferTests/NotificationCoordinatorXCTests -only-testing:FishSockTransferTests/TransferViewModelRuntimeXCTests test
```

102 passed / 0 failed / 0 skipped. Settings interval/message path checks are contained in the existing NotificationCoordinator suite; there are no separate settings/message-factory/notification persistence test suites to select. Existing runtime tests exercise in-flight send gating/status/warning behavior. No new suite invented.

Full canonical suite, first run (exit 65; original TEST FAILED preserved):

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/fst-patch3-derived -resultBundlePath /tmp/fst-patch3-full.xcresult -parallel-testing-enabled NO test
```

284 passed / 1 failed / 0 skipped. `DestinationCapacityImageRuntimeXCTests/testDisposableAPFSAdmissionAndVerifiedCopy()` failed in hdiutil create before production test assertions with `Device not configured`. Disposable exFAT image test passed; cleanup reports PASS, owner media touched NONE. Original log and structured summary: TEST_FULL_FIRST.log, TEST_FULL_FIRST_SUMMARY.json.

One justified serial retry (exit 65; no third run): same command with result bundle `/tmp/fst-patch3-full-serial-retry.xcresult`. Result 284 passed / 1 failed / 0 skipped, same APFS image creation infrastructure failure. TEST_FULL_RETRY.log and TEST_FULL_RETRY_SUMMARY.json preserve the retry; TEST_RETRY_REASON.md documents why one repeat was justified. No production/test/system/tooling change was made to bypass this failure. Overall Worker RESULT=FAIL because required full-suite success is unproven.

Structured summaries were extracted via `xcrun xcresulttool get test-results summary --path <result bundle> --format json`. Result bundles remain at the exact /tmp paths above; logs and summaries are committed durable evidence.

`git diff --check` passes. Exact source/diff inspection plus binding/callback comparison is preserved in BEHAVIOR_SCOPE_CHECK.json, BEHAVIOR_SECURITY_REVIEW.md and PATCH3_PRODUCTION_REVIEWED.diff. Only NotificationTabView.swift changes in production. Patch 1 and Patch 2 retained; no Patch 4/5 work. No service/model/ViewModel/global style/entitlement/config edits. CodeGraph unavailable; inspected direct source/tests.

Before, Pass A, independent final, minimum scrolled and supplemental long-error captures completed with no sends/Keychain access/transfer. All three primary final PNGs are byte-identical to Pass A. Minimum scrolled capture shows every event and both menu controls; long error remains wrapped/selectable. Visual parity remains a BRAIN decision.
