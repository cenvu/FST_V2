# Transfer Card Readability Typography Retune

TASK_ID=TRANSFER_CARD_READABILITY_TYPOGRAPHY_RETUNE
WORKSTREAM_ID=OPENDESIGN_VISUAL_CONVERGENCE_P2_FOLLOWUP
CLASS=BOUNDED_PRESENTATION_REPAIR
ROLE=IMPLEMENTER
START_HEAD=523a38b8243612afc6d0c525961fef4f55b6a3c2
START_BRANCH=main
START_CLEAN=YES
START_FETCHED_HEAD_EQUALS_ORIGIN_MAIN=YES
MATCHING_GITHUB_ISSUE=NONE_FOUND
DUPLICATE_TASK=NONE_FOUND
CODEGRAPH=MCP_UNAVAILABLE;DIRECT_SOURCE_INSPECTION
BRAIN_REVIEW_STATUS=PENDING
BRAIN_CLASSIFICATION=UNSET
ACCEPTED_STATE=UNSET
ACTIVE_NEXT=NONE

## Exact local typography

| Text | Original pre-bump native pt | 523a38b pt | Final pt | Reduction |
|---|---:|---:|---:|---:|
| Source / Destination role | 14 | 19 | 16 | 15.8% |
| Selected volume/folder name | 18 | 24 | 20 | 16.7% |
| Empty selection title | 16 | 21 | 18 | 14.3% |
| Path / metadata / target preview | 10 | 14 | 12 | 14.3% |
| Capacity sentence / metric label and value | 10 | 14 | 12 | 14.3% |
| Capacity headline / analyzing / drop prompt | 11 | 15 | 13 | 13.3% |

Explicit owner targets used with no one-point deviation and no runtime font
multiplication. The native original sizes are measured in the previous bump
capture logs/validation. Final sizes are 1.11–1.20× that native implementation;
exact 1.1× of every OpenDesign element is not asserted. Implementer inspection
finds the final hierarchy closer to the owner's proportional target. Subjective
visual acceptance remains BRAIN-owned.

Names and empty titles retain semibold; role retains medium/muted; metadata
labels regular/muted, values semibold/primary/monospaced; paths muted and
monospaced. Capacity headline semibold13, explanation regular12, metric
values medium12/primary/monospaced, metric labels regular12/secondary.

Role column 116→104pt; card vertical padding 10→8pt; content vertical spacing
6→4pt; capacity vertical padding 8→6pt; capacity inner spacing 6→4pt.
Reviewed and retained: metadata group gap12pt, capacity metric gap16pt,
label/value gap2pt, horizontal card padding16pt. These gaps remain appropriate
for readable grouping at the reduced type. Metadata grouping/truncation
structure from the previous bump remains unchanged.

## Dark Aqua native visual evidence

Existing capture harness reused byte-for-byte from the previous bump. Only
fixture initialization of a temporary ContentView compilation unit is
injected; production view bodies compile from actual source. All scratch,
fixtures, PNGs, and build artifacts are under this repository evidence folder.
Both BEFORE and AFTER runs exited0, eight PNGs each. BEFORE compiled from
523a38b before any production mutation; AFTER compiled from final source.
No UI buttons clicked, transfers/verification/notification sends/update
requests initiated by the capture; synthetic folders only. Captures probe
existing bundled rsync3.4.4 availability. Isolated settings/empty token store
and no-send service are reused. The fixture removes only its own created
fixture directory. Canonical tests below separately exercise controlled media
fixtures, including their own disposable images.

```sh
python3 handoffs/evidence/transfer-card-readability-retune/capture_native.py BEFORE handoffs/evidence/transfer-card-readability-retune
python3 handoffs/evidence/transfer-card-readability-retune/capture_native.py AFTER handoffs/evidence/transfer-card-readability-retune
```

Inspected: AFTER_READY1120×760; AFTER_READY_MINIMUM900×660; scrolled minimum;
long names/paths with1,234,567files/12,345folders and full MS-DOS(FAT32);
locked Copying; insufficient capacity with full model warning; non-writable
destination; empty selections. Compared against fresh523a38b BEFORE minimum
and historical original pre-bump BEFORE minimum. No top-section clipping,
overlap, button/metadata collision, or broken wraps observed. Paths retain
existing middle truncation, full help/accessibility text. Choose/Change/Clear/
lock styles/sizes/actions/disablement/drop/accessibility are byte-unchanged.
Capacity literal wording, uncertainty help, and all four bindings unchanged.

| State/window | Before scroll pt | After scroll pt |
|---|---:|---:|
| Ready1120×760 | 35 | 0 |
| Ready900×660 | 152 | 101 |
| Locked Copying900×660 | 174 | 123 |
| Long names900×660 | 152 | 101 |
| Insufficient900×660 | 213 | 147 |
| Non-writable900×660 | 152 | 101 |
| Empty900×660 | 33 | 0 |

Minimum Ready document717→666pt, viewport565pt; tail scroll improves51pt
(33.6%). Historical original pre-bump tail37pt. Retune recovers compactness
without claiming restoration of the original inline metadata layout or full
37pt extent. Scrolled screenshot confirms lower job metrics remain reachable.
Non-writable direct-state fixture retains the pre-existing Ready/start UI
mapping; this capture does not certify backend preflight behavior. No product
logic is repaired or bypassed. Every visual fixture is synthetic.

## Canonical build and tests

Debug build exit0, BUILD SUCCEEDED. Existing TransferControlsLabelTests
compiled from all productionSwift except FishSockTransferApp.swift, plus the
existing standalone test, with Swift5/default isolationMainActor/DEBUG/
parse-as-library; executed exit0, TransferControlsLabelTests passed.
Focused canonical runtime82 + capacity policy23 =105passed,0failed,0skipped;
exit0, TEST SUCCEEDED, actual xcresult summary retained.

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath handoffs/evidence/transfer-card-readability-retune/DerivedData build
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath handoffs/evidence/transfer-card-readability-retune/DerivedData -resultBundlePath handoffs/evidence/transfer-card-readability-retune/FOCUSED_TESTS.xcresult -parallel-testing-enabled NO -only-testing:FishSockTransferTests/TransferViewModelRuntimeXCTests -only-testing:FishSockTransferTests/DestinationCapacityPolicyXCTests test
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath handoffs/evidence/transfer-card-readability-retune/.build/FullFreshDerivedData -resultBundlePath handoffs/evidence/transfer-card-readability-retune/FULL_TESTS.xcresult -parallel-testing-enabled NO test
```

RESULT=PASS
FULL_CANONICAL_TESTS=285_PASSED_0_FAILED_0_SKIPPED
FULL_CANONICAL_RUNS=1
FULL_CANONICAL_EXIT=0
FULL_CANONICAL_DERIVED_DATA=FRESH
APFS_HOST_FAILURE=NONE
ISOLATED_APFS_RETRY=NOT_NEEDED;NOT_RUN

Exact first full result preserved in FULL_TESTS.log.gz and
FULL_TEST_SUMMARY.json. Full suite exit0, TEST SUCCEEDED; all285tests passed.
Disposable APFS admission/verified copy passed11.590seconds; exFAT image
case also passed; fixture cleanup PASS and OWNER_MEDIA_TOUCHED=NONE.
No product/test/system modifications to make tests pass. Raw console logs
are gzip copies preserving exact bytes; xcresult bundles/DerivedData are
repository-local ignored artifacts. Capture logs contain host framework
symbol diagnostics and pre-existing compiler deprecation warnings; both
capture processes completed successfully with all expectedPNGoutputs.

DIFF_CHECK=PASS

## Scope gate and limits

Production changes exactly SourceCardView.swift, DestinationCardView.swift,
StorageAnalysisView.swift. SCOPE_CHECK.json stores baseline/final hashes and
requires exact source bytes to match after normalizing only changed numerical
font/frame-width/vertical-padding/VStack-spacing arguments. String literal
sequences agree exactly. No weight/color/string/action/condition/binding/
formatter/control/drop/accessibility change. No engine/coordinator/service/
ViewModel/rsync/verification/capacity/report/notification/test/project/config/
localization/Settings/global typography change. BRAIN Operator bytes unchanged.
PRODUCTION_REVIEWED.diff is a whitespace-normalized reading copy; Git source
diff remains authoritative.

STRING_LITERALS_UNCHANGED=YES
BEHAVIOR_BINDINGS_UNCHANGED=YES
SAFETY_SEMANTICS_UNCHANGED=YES
GLOBAL_TYPOGRAPHY_UNCHANGED=YES

Implementer visual/source review only; no independent reviewer, physical
owner-media transfer, all-locale/device guarantee, or BRAIN acceptance.

WORKER_PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_TYPOGRAPHY_RETUNE_REVIEW
