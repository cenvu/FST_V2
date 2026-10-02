# Patch 5 validation

RESULT=PASS
PRODUCTION_CHANGES=NONE
CANONICAL_DEBUG_BUILD=SUCCEEDED
FOCUSED_PRESENTATION_TEST=TransferControlsLabelTests_PASSED
FULL_CANONICAL_TESTS=285_PASSED_0_FAILED_0_SKIPPED
FULL_CANONICAL_RUNS=1
RETRY=NONE
DIFF_CHECK=PASS

## Canonical Debug build

Command:

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/fst-patch5-canonical-build-derived build
```

Result: `** BUILD SUCCEEDED **`, exit 0. Output: `CANONICAL_DEBUG_BUILD.log.gz`
(exact log bytes; extract with `gzip -dc`).

## Focused presentation/state checks

The existing full/default standalone presentation executable was compiled from
all production Swift files except `FishSockTransferApp.swift`, plus the
existing `FishSockTransfer/Tests/TransferControlsLabelTests.swift`, using
Swift 5, MainActor default isolation, and `DEBUG`. It passed with
`TransferControlsLabelTests passed`, exit 0. Compile warnings are the
pre-existing macOS `onChange(of:perform:)` deprecations in Notification and
Transfer presentation files. Exact compiler/run output:
`TRANSFER_CONTROLS_PRESENTATION_TEST.log.gz`.

No presentation source was modified. The canonical full suite below also ran
the existing TransferViewModel, notification, log-filter, update-service,
capacity, report, and verification tests.

## Full canonical suite

Exactly one serial run used a fresh DerivedData directory and fresh result
bundle:

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/fst-patch5-full-derived \
  -resultBundlePath /tmp/fst-patch5-full.xcresult \
  -parallel-testing-enabled NO test
```

Result: `** TEST SUCCEEDED **`; 285 passed, 0 failed, 0 skipped; exit 0. The
two `DestinationCapacityImageRuntimeXCTests` passed. Their expected disposable
image ENOSPC case appears in the raw test log; it did not fail the test or
indicate a host-level image creation error. No isolated retry was needed.
Output and structured result: `FULL_CANONICAL_TESTS.log.gz`,
`FULL_CANONICAL_SUMMARY.json`; result bundle: `/tmp/fst-patch5-full.xcresult`.

## Native fixture capture

`capture_native.py BEFORE ...` and `capture_native.py AFTER ...` both compiled
the current accepted production sources in a temporary app. Twenty matching
PNG pairs were captured at nominal/minimum dimensions; all pairs have matching
dimensions and SHA256. Capture records: `CAPTURE_BEFORE.log.gz`,
`CAPTURE_AFTER.log.gz`; details and hashes: `EVIDENCE_INDEX.md`.

## Scope and repository checks

`git diff --check` and the final staged whitespace check passed. Production
paths changed: none. Only Patch 5 evidence, the canonical handoff, and required
task-history bookkeeping are included in the commit.
