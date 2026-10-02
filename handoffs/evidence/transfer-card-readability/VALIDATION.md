# Transfer card readability typography bump

TASK=Visual Convergence Follow-up — Transfer Card Readability Typography Bump
RESULT=PASS
ROLE=IMPLEMENTER
BRAIN_REVIEW=PENDING
START_HEAD=21d7e3512fbe487bd1489890b3c27caf40602e8d
START_BRANCH=main
START_CLEAN=YES
START_FETCHED_HEAD_EQUALS_UPSTREAM=YES
MATCHING_GITHUB_ISSUE=NONE_FOUND
DUPLICATE_TASK=NONE_FOUND
CODEGRAPH=MCP_UNAVAILABLE;DIRECT_SOURCE_INSPECTION

## Production patch

Only `SourceCardView.swift`, `DestinationCardView.swift`, and
`StorageAnalysisView.swift` change. Fonts remain local to those views.

| Text | Before, pt | After, pt | Ratio |
|---|---:|---:|---:|
| Source / Destination | 14 | 19 | 1.36 |
| Selected volume/folder name | 18 | 24 | 1.33 |
| Empty selection title | 16 | 21 | 1.31 |
| Path, metadata label/value, target preview | 10 | 14 | 1.40 |
| Capacity sentence and metric label/value | 10 | 14 | 1.40 |
| Capacity headline, analyzing/drop prompt | 11 | 15 | 1.36 |

Native AppKit preferred-font measurements confirm caption/footnote 10pt and
subheadline 11pt on this host; recorded in the capture logs. Volume titles
retain semibold weight; labels remain regular/muted and values retain stronger
weight/contrast. Capacity values use medium monospaced text.

Source/Destination label columns grow from 88 to 116pt. Metadata labels sit
above their values with 2pt spacing, and the three-field metadata group keeps
its natural width so long volume names yield through existing truncation.
Card vertical padding grows from 8 to 10pt; internal vertical spacing from
4 to 6pt. Capacity vertical padding grows from 6 to 8pt, and internal spacing
from 4 to 6pt. Supporting capacity text/headlines may wrap vertically.

Button actions, style, control size, disabled conditions, accessibility text,
drop behavior, formatting, data bindings, conditions, and all literal wording
are unchanged. No global typography or shared helper changes.

## Build and tests

Canonical final Debug build:

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath handoffs/evidence/transfer-card-readability/DerivedData build
```

Exit 0, `BUILD SUCCEEDED`. Final output: `FINAL_BUILD.log.gz`; initial build
also passed (`BUILD.log.gz`).

Focused canonical test commands use the same project/scheme/configuration/
destination/DerivedData arguments, `-parallel-testing-enabled NO`, and:

```sh
-resultBundlePath handoffs/evidence/transfer-card-readability/FOCUSED_TESTS.xcresult \
-only-testing:FishSockTransferTests/TransferViewModelRuntimeXCTests \
-only-testing:FishSockTransferTests/DestinationCapacityAssessmentXCTests test

-resultBundlePath handoffs/evidence/transfer-card-readability/CAPACITY_TESTS.xcresult \
-only-testing:FishSockTransferTests/DestinationCapacityPolicyXCTests test
```

Both exit 0 with `TEST SUCCEEDED`. First run: **82 passed, 0 failed, 0 skipped**,
all in `TransferViewModelRuntimeXCTests`. The first capacity filter used a
nonexistent class and selected no capacity tests. The corrected second run
executed **23 passed, 0 failed, 0 skipped** in the actual
`DestinationCapacityPolicyXCTests`. Results: `FOCUSED_TEST_SUMMARY.json`,
`CAPACITY_TEST_SUMMARY.json`, and exact corresponding gzip logs. Total
canonical tests actually executed: **105**, with no failures or skips.

The existing standalone `TransferControlsLabelTests.swift` was compiled with
all production Swift files except `FishSockTransferApp.swift` using
`xcrun swiftc -swift-version 5 -default-isolation MainActor -D DEBUG
-parse-as-library`, then executed. Final source compilation and execution
both exit 0: `TransferControlsLabelTests passed` in
`FINAL_PRESENTATION_TEST.log.gz`. Its existing assertions cover control/state
labels, terminal distinction, selection lock, and start eligibility.

The final build and presentation executable were rerun after the last metadata
width adjustment. Canonical model/policy sources did not change between the
focused test runs and the final presentation patch.

## Native visual inspection

Reused the Patch 5 native capture harness, adapted only inside this evidence
directory: repository-relative root, repository-local scratch/app/fixtures,
Transfer-only fixture list, HDD/TEMP names, and bounded metadata variants.
Temporary ContentView construction injects the fixture; production view
bodies are compiled unchanged. No browser or image manipulation is used.

Fixtures use isolated UserDefaults, a fake empty token store, a notification
service that traps on send, and synthetic directories. No transfer,
verification, notification send, update request, or owner media is involved
in visual capture. Existing bundled rsync 3.4.4 availability/version is probed.
Canonical tests separately exercise their existing controlled fixtures.

```sh
python3 handoffs/evidence/transfer-card-readability/capture_native.py AFTER \
  handoffs/evidence/transfer-card-readability
```

Four BEFORE PNGs and eight final AFTER PNGs are indexed in `EVIDENCE_INDEX.md`.
BEFORE was captured prior to production mutation with the initial three-state
fixture list; AFTER adds long names, insufficient capacity, non-writable
destination, and empty selections. Both capture invocations exit 0.

Visual inspection covers 1120×760pt nominal Ready, 900×660pt Ready, locked
Copying, long names/paths and 1,234,567 files/12,345 folders, localized
filesystem `MS-DOS (FAT32)`, insufficient space with its full existing
explanatory message, non-writable warning, empty selections, and minimum
scrolled content. No top-block clipping, overlap, broken label/value groups,
or button collisions were observed. Long names retain existing ellipsis;
paths and target preview retain middle truncation and complete tooltip/
accessibility content. Capacity sentences wrap cleanly. All four capacity
metrics remain visible in a single row when present.

The minimum Ready document grows from 602 to 717pt in a 565pt viewport,
increasing tail scroll from 37 to 152pt. Nominal Ready has 35pt tail scroll.
The scrolled minimum capture confirms remaining job information is reachable
and the fixed footer remains visible. Insufficient-capacity explanation adds
further natural vertical scroll (213pt); this is the existing scroll container.

## Scope / behavior review and limits

`git diff --check` passes. `SCOPE_CHECK.json` and `PRODUCTION_REVIEWED.diff`
record the exact three-file production scope, original/current SHA256 values,
unchanged string literals, and equal source tokens after removing only the
authorized presentation modifiers/stack constructor arguments. All model,
engine, coordinator, service, capacity policy, state/safety admission, source
handling, rsync, notification, log, report, tests, project settings, and
`BRAIN_OPERATOR_COMPACT.md` remain byte-identical to baseline.

This is an implementer source/visual review, not independent safety
certification or BRAIN acceptance. CodeGraph MCP is unavailable. A full
canonical suite and physical-media transfers were not run for this bounded
presentation patch. Captures use synthetic direct state injection and do
not certify a backend preflight workflow or every possible locale/device.
BRAIN review, classification, accepted state, and active-next remain unset.

WORKER_PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_TRANSFER_CARD_TYPOGRAPHY_REVIEW
