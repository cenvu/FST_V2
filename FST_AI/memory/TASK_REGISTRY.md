# FST Task Registry

## Purpose

Track meaningful AI/Codex task batches so future agents can detect repeated prompts.

## Rule

Search only the supplied task ID/name in this registry and
`FST_AI/memory/WORK_HISTORY.md`; read matching entries to detect duplicate
work. These files are history, not active state, and are not a full startup
bundle.

If the same or substantially similar task already appears complete, ask whether
to rerun it, continue it, or review its evidence:

```text
This appears to have been run before as <entry>. Do you want to rerun it, continue it, or review previous output?
```

## Entry Format

- Date:
- Task ID:
- Task name:
- Agent:
- Status: planned / implemented / blocked / superseded
- Files changed:
- Commit/tag/release:
- Safety impact:
- Checks:
- Notes:

## Recent Tasks

### 2026-10-02 - OpenDesign Visual Convergence Phase 2 — PATCH_2 Transfer Rhythm

- Task ID: OPENDESIGN_VISUAL_CONVERGENCE_P2_PATCH2_TRANSFER_RHYTHM; workstream `OPENDESIGN_VISUAL_CONVERGENCE_P2`
- Agent/model: Codex local Worker; exact model variant not independently recorded; IMPLEMENTER, not reviewer
- Branch/start: `main`; clean fetched `HEAD=origin/main=be06423712b18495bd552034d7e541f511b89b66`; no matching GitHub issue or duplicate Patch 2 record
- Status: implementation and evidence complete; BRAIN review pending, classification/accepted state unset; no visual parity self-acceptance
- Files changed: five Transfer presentation views/styles; scoped evidence under `handoffs/evidence/opendesign-visual-convergence-p2/patch2/`; expected memory and canonical handoff
- Commit/tag/release: one coherent Patch 2 commit/push/fetch verification; no tag/release
- Safety impact: presentation only. Transfer workflow/state, capacity formulas and admission, verification, rsync, telemetry derivation and SAFE TO EJECT gate are unchanged. No owner media, transfer, verification, notification, or report was used for capture.
- Checks: actual read-only OpenDesign MCP project/file calls; native five-state Dark Aqua captures at 1120×760pt/2240×1520px; Pass A plus one bounded Pass B; Debug build passed; focused166/0/0; full285/0/0; standalone TransferControlsLabelTests passed; `git diff --check` passed. Final evidence records all states and comparison classes.
- Notes: Patch 1 retained; Patch 3 Notification, Patch 4 Technical Log, and Patch 5 polish not started. CodeGraph unavailable; production source inspected directly. Single Worker proposal: return to BRAIN for Patch 2 review.

### 2026-10-02 - OpenDesign Visual Convergence Phase 2 — PATCH_1

- Task ID: OPENDESIGN_VISUAL_CONVERGENCE_PHASE_2
- Agent/model: Codex local Worker; exact model variant not independently recorded; IMPLEMENTER
- Branch/start: `main`; fetched `HEAD=origin/main=023e4d33b03a93fc65432b9afe0523c2dafc4666`; GitHub issue search returned no matching issue; local task/history records identify this in-progress Patch 1.
- Status: Patch 1 bounded review/finalization complete; BRAIN review pending, classification/accepted state unset.
- Files changed: production `ContentView.swift`; expected `WORK_HISTORY.md` and `TASK_REGISTRY.md`; durable Patch 1 evidence under `handoffs/evidence/opendesign-visual-convergence-p2/patch1/`; canonical handoff.
- Commit/tag/release: single finalization commit/push for Patch 1; no tag/release.
- Safety impact: reviewed diff is shell presentation only. Transfer/verification/rsync/notification/report/safety behavior and SAFE TO EJECT gate are unchanged. No fake production telemetry, new social link, source-media operation, or transfer was introduced.
- Checks: initial parallel-enabled Debug build succeeded, suite result 283 passed / 2 failed / 0 skipped due to `hdiutil create` returning `Device not configured` in two disposable image tests. Full serial Debug build/test retry succeeded: 285 passed / 0 failed / 0 skipped. Final `git diff --check` passed. Durable native READY/NOTIFICATION/TECHNICAL_LOG captures and exact ContentView diff are in the Patch 1 evidence directory. Live OpenDesign shell measurements matched the changed native values.
- Notes: CodeGraph unavailable; exact source diff reviewed directly. `PATCH_2_NOT_STARTED`. Worker proposal: return to BRAIN for Patch 1 review; no self-acceptance/classification/active-next.

### 2026-10-02 - OpenDesign Live Transfer Convergence Phase 1

- Task ID: OPENDESIGN_LIVE_TRANSFER_CONVERGENCE_PHASE_1; workstream OPENDESIGN_LIVE_TRANSFER_P1
- Agent/model: Codex4 local Worker / exact model UNVERIFIED; IMPLEMENTER
- Branch/start: clean main at fetched HEAD=origin/main=0c230033eaa413629459c1495c84e26d94bdf1c2; no matching issue/duplicate task
- Status: implementation and visual evidence complete; BRAIN review PENDING, classification/accepted state UNSET; no visual parity acceptance
- Change/files: seven production View/presentation files; native flat Transfer route, adaptive OpenDesign palette, shared FST/tab/footer shell, two-field setup, explicit control strip, three equal hero metrics/thin phase progress/four secondary metrics/current item. Standalone presentation tests plus scoped live-source/capture/gap evidence and canonical handoff.
- Safety: backend/capacity formulas/admission/verification/rsync/Telegram/reports/privacy and canonical success ownership unchanged. NONE remains TRANSFER COMPLETE; only safeToFormat maps SAFE TO EJECT. No fake production telemetry, WebView, JS port or owner media. Harness configuration/OpenDesign project read-only.
- Checks: actual OpenDesign MCP list_projects and three get_file calls, exact project 988fea7b-beea-4916-a10e-5368a120417e; Debug PASS; full285/0/0; focused127/0/0; full/default standalone presentation suite PASS; eight 1120x760 native before/after PNGs, 900x660/Light captures and native picker/tab QA; diff check PASS. Missing state references/backend constraints/material gaps documented; bottom-current-item minimum capture limitation and partial AX audit preserved.
- Evidence: handoffs/evidence/opendesign-live-transfer-p1/LIVE_SOURCE_MAP.md; VISUAL_GAP_REPORT.md; VERIFICATION.md and hashed PNG/MCP manifests. Test-only empty token store and canonical assessment fix prior standalone fixture defects.
- Commit/tag/release: one coherent implementation/evidence/handoff commit and push/fetch/export finalization; exact resulting SHA/sync/clean state in V2.1 packet; no tag/release.
- Single Worker proposal: RETURN_TO_BRAIN_FOR_VISUAL_ADJUDICATION; ACTIVE_NEXT=NONE; no Phase 2.


### 2026-10-01 - Destination Capacity Final Writability Freshness Repair

- Task ID: DESTINATION_CAPACITY_FINAL_WRITABILITY_FRESHNESS_REPAIR
- Agent: Codex local Worker / exact model UNVERIFIED; implementer only
- Status: bounded repair and required verification complete; BRAIN review PENDING, classification/accepted state UNSET
- Files changed: DriveService final validator and DEBUG-only access injection; one Coordinator evidence argument; canonical preflight/capacity test file; scoped evidence, required memory, one NORMAL handoff
- Safety impact: final fresh DestinationStorageMetadata.isWritable now required for admission; existing destinationUnavailable error; same final F/profile evidence; no APFS R/WARN+L policy, L/progress, UI, Privacy, Telegram, engines, verification or SAFE TO EJECT changes
- Checks: test-first red reproduced old admission (0 passed/1 failed/0 skipped); final focused64/0/0; Debug PASS; full285/0/0 including existing temporary APFS/exFAT QA; diff/cleanup PASS
- Evidence: handoffs/evidence/destination-writability-repair/REPAIR_EVIDENCE.md and exact production/tests JSON patches, verification/cleanup/new-test results
- Commit/tag/release: one coherent commit/push/fetch/export; exact final SHA and upstream/clean state in V2.1 packet; no tag/release
- Notes: deterministic writable probes true,true,false reject before copying/rsync; no writability reservation or TOCTOU guarantee. Single Worker proposal RETURN_TO_BRAIN_FOR_FINAL_REPAIR_ADJUDICATION.

### 2026-10-01 - Destination Capacity Policy Production Implementation

- Task ID: DESTINATION_CAPACITY_POLICY_PRODUCTION_IMPLEMENTATION
- Agent: Codex local Worker / exact model UNVERIFIED; implementer, not independent reviewer
- Status: implementation and required verification complete; BRAIN review pending, classification/accepted state unset
- Files changed: DriveService, StorageMetadata, TransferCoordinator, TransferViewModel, StorageAnalysisView; PrivacyInfo.xcprivacy; two canonical XCTest files; scoped evidence, memory, one canonical NORMAL handoff
- Safety impact: validated machine apfs + runtime4096 uses checked per-file R hard floor; exFAT/unvalidated/unknown WARN+L; L remains copy/observer truth; fresh Coordinator evidence; wording-only UI. Owner separately authorized redacting capacity details from Telegram failure summary for Apple reason restrictions.
- Checks: Debug PASS; focused138/138; image runtime2/2; full canonical277/277, zero failures/skips; actual APFS L<=F<R block before rsync; exFAT512 public signal WARN+L and actual ENOSPC=>TRANSFER ERROR, never SAFE TO EJECT; successful SHA256 pairs8192 APFS/512 exFAT; schema and built manifest PASS; native actual StorageAnalysisView Light/Dark nominal rendering inspected; image cleanup and diff check PASS.
- Evidence: handoffs/evidence/destination-capacity-production/IMPLEMENTATION_EVIDENCE.md; exact compressed production/test diffs plus hashes; verification/runtime/privacy/cleanup artifacts and four native screenshots
- Commit/tag/release: one coherent production/evidence commit via finalizer; exact final SHA/upstream/clean gates in V2.1 BRAIN packet; no tag/release
- Notes: snapshot/floor cannot prove fit; no raw-device production probes or arbitrary margin; unchanged engines/exclusions/verification/TransferState/report safety/OpenDesign. Single Worker proposal: RETURN_TO_BRAIN_FOR_POST_IMPLEMENT_INDEPENDENT_REVIEW.

### 2026-10-01 - Destination Capacity Policy Independent Review

- Date: 2026-10-01
- Task ID: DESTINATION_CAPACITY_POLICY_INDEPENDENT_REVIEW
- Task name: Destination Capacity Policy Independent Review
- Agent: Codex local Worker / model UNVERIFIED
- Status: blocked; existing independent review artifact/output was not recovered
- Files changed: one BLOCKED recovery handoff, CURRENT/INDEX, this registry, WORK_HISTORY
- Commit/tag/release: control-plane recovery record only; final Git/export gates in `03_FST_BRAIN.md`; no release/tag
- Safety impact: no product, Swift, tests, design system, OpenDesign, destination headroom logic, rsync, verification, or SAFE TO EJECT mutation
- Checks: repo, `/tmp`, scoped agent-output, GitHub issue, and 4,863 unreachable Git-object searches produced no independent review artifact; publisher dry-run passed; final verification in BRAIN packet
- Notes: expected claims were not promoted to findings; review was not re-executed or reconstructed; BRAIN review/classification/accepted state remain pending/unset. Single next action: RETURN_TO_BRAIN_FOR_ARTIFACT_RECOVERY_DECISION.

### 2026-10-01 - FST Brain Operator Architecture Pilot

- Date: 2026-10-01
- Task ID: FST_BRAIN_OPERATOR_ARCHITECTURE_PILOT
- Task name: FST Brain Operator Architecture Pilot
- Agent: Codex local Worker / model UNVERIFIED
- Status: control-plane pilot implemented; Worker handoff pending BRAIN adjudication
- Files changed: root/harness kernel; BRAIN compact and existing governance/role/skill references; stale current-priority pointer; handoff template/readme; existing publisher and stdlib tests; docs and this registry/history; one NORMAL CURRENT/timestamped handoff
- Commit/tag/release: one coherent control-plane commit; final Git/export gates in `03_FST_BRAIN.md`; no release/tag
- Safety impact: no Swift, Xcode, transfer, verification, rsync, report, SAFE TO EJECT, UI8, or destination headroom policy changes; product diff empty; headroom remains parked
- Checks: default context reduced from 20 files/275366 bytes/5941 lines to AGENTS plus HOT 2 files/7935 bytes/201 lines; four representative existing skills measured separately at 13063 bytes/400 lines; publisher tests 9/9; exporter tests 18/18; publisher dry-run/verify; `git diff --check`; product diff empty; pilot cases A-E and read-only independent review recorded in CURRENT
- Notes: no new skill or checker; BRAIN review/classification/accepted state/active-next remain unset/pending. Exact post-BRAIN provenance gap and proposal are in CURRENT. Single Worker proposal: RETURN_TO_BRAIN_FOR_INDEPENDENT_ADJUDICATION.

### 2026-10-01 - Brain Return V2.1 Fallback Resilience

- Date: 2026-10-01
- Task ID: BRAIN_RETURN_V2_1_FALLBACK_RESILIENCE
- Task name: Brain Return V2.1 Fallback Resilience
- Agent: Codex local Worker / exact model UNVERIFIED
- Status: implementation and 18/18 stdlib tests complete; verification handoff and final Git/export evidence are canonical
- Files changed: exporter and stdlib contract tests; BRAIN Operator compact contract; Command Center/Task Registry/Work History; finalizer skill; AGENTS, FST AI README, handoff README; CURRENT, `handoffs/20261001-110825_codex-local-worker_brain-return-v2-1-fallback-resilience.md`, and one INDEX entry
- Commit/tag/release: one coherent control-plane evidence commit; final SHA and push/fetch equality in V2.1 BRAIN packet; no release/tag
- Safety impact: control-plane transport only; no Swift, Xcode, transfer, verification, report, or UI changes. V2 metadata and fail-closed gates are preserved; exact compact operator snapshot is fallback only.
- Checks: stdlib unittest 18/18 PASS; exact operator bytes/hash and mutation change; missing/unreadable/non-UTF8/hash failure downgrades PASS; no 8 MiB operator ceiling; no handoff/raw bodies; dry-run, Desktop path, five-line CLI, FAIL export, and existing gate tests PASS. V2 prior Desktop packet 1,441 bytes; V2.1 representative packet 6,889 bytes with 5,459-byte operator snapshot.
- Notes: GitHub issue list returned empty; CodeGraph MCP unavailable, direct source inspection used. Single Next Action: RETURN_TO_BRAIN.

### 2026-10-01 - Destination Capacity FS Calibration

TASK_ID=DESTINATION_CAPACITY_FS_CALIBRATION;TASK=Destination Capacity FS Calibration
AGENT=Codex local Worker;MODEL=UNVERIFIED;STATUS=research_evidence_complete_policy_pending
START_HEAD=c74178a8c406fc134432055b51af5bd5325bf30e;SCOPE=control_plane_evidence_only;PRODUCTION_BYTES=UNCHANGED
EVIDENCE=handoffs/evidence/fs-calibration/README.md;POLICY=handoffs/evidence/fs-calibration/POLICY_SPEC_CANDIDATE.md
CHECKS=actual_bundled_rsync_187_jobs_83_hash_correct_successes_104_failures_preserved;APFS_five_runs_per_sparse_and_small_case;exFAT_cluster_verified_from_image;exact_L_R_boundary_points;source_readonly_unchanged;ten_temp_roots_removed_no_mounts
FINDING=exFAT_f_frsize_and_public_minallocation512_vs_cluster32768;receiver_AppleDouble_metadata;APFS_ENOSPC_despite_F_ge_R;no_exact_fit_or_universal_metadata_budget;OWNER_B_ACKNOWLEDGED
LIMIT=one_provenance_check_stopped_phase_preserved_and_cleaned;required_exFAT_boundaries_completed_separately;46_missed_targets_preserved;HFS_and_physical_media_and_signed_app_and_purge_tests_NOT_EXECUTED
BRAIN_CLASSIFICATION=UNSET;ACCEPTED_STATE=UNSET;ACTIVE_NEXT=NONE
NEXT=RETURN_TO_BRAIN_FOR_INDEPENDENT_POLICY_ADJUDICATION

### 2026-10-01 - Destination Capacity Headroom Decision

TASK_ID=DESTINATION_CAPACITY_HEADROOM_DECISION;TASK=Destination Capacity Headroom Decision
AGENT=Codex local Worker;MODEL=UNVERIFIED;STATUS=research_complete_policy_pending
START_HEAD=3d8d8a251533d22f57cb141a28c4bae9f6154a31;SCOPE=three_memory_files_and_one_NORMAL_handoff_only
CHECKS=primary_research_before_repro;APFS20/20_real_copy_PASS;2_idle_controls;source_unchanged_dest_data_match;91_app_project_test_paths_identical;diffcheck_and_publisher_gates
FINDING=logical_bytes_not_physical_fit_proof;importantUsage_not_reservation;no_universal_numeric_margin_justified;OWNER_DECISION_REQUIRED
NOT_EXECUTED=exFAT_HFS_near_ENOSPC_isolated_accounting_build_XCTest_rerun;NO_PRODUCTION_PATCH;NO_UI8;NO_RELEASE
NEXT=RETURN_TO_BRAIN_FOR_HEADROOM_POLICY_DECISION

### 2026-10-01 - Storage Preflight Logical Size Safety

- Task ID: STORAGE_PREFLIGHT_LOGICAL_SIZE_SAFETY
- Task name: Storage Preflight Logical Size Safety
- Agent: Codex local Worker / model UNVERIFIED
- Status: implemented safety-core repair; BRAIN review pending
- Files changed: DriveService.swift; StorageMetadata.swift (comment only); MetadataOnlySourceSafetyXCTests.swift; TransferViewModelRuntimeXCTests.swift; required memory and one NORMAL handoff
- Commit/tag/release: one coherent task/handoff commit; exact final HEAD in V2 packet; no release/tag
- Safety impact: storage/preflight use logical regular-file bytes instead of source allocation; missing logical size fails closed; exclusions/cancellation and rsync flags unchanged
- Checks: Apple docs/SDK and exact rsync v3.4.4 source before actual bundled repro; sparse/compressed undercount proven before patch; Debug PASS; focused 145 passed/0 failed/0 skipped; full 255 passed/0 failed/0 skipped; post-fix real copy hashes match and source unchanged; diff check PASS
- Notes: logical bytes are content floor, not filesystem metadata/cluster overhead or reservation. No UI8. Single Next Action: RETURN_TO_BRAIN.

### 2026-10-01 - UI-7 Final Verification Repair

- Date: 2026-10-01
- Task ID: UI7_FINAL_VERIFICATION_REPAIR
- Task name: UI-7 Final Verification Repair
- Agent: Codex local Worker / exact model UNVERIFIED
- Status: implemented; canonical verification handoff published; final Git/export evidence in BRAIN return
- Files changed: StorageAnalysisView.swift (one presentation frame); deleted noncanonical handoffs/UI-7_Final_Visual_Polish.md; Command Center, task and work records; CURRENT_HANDOFF, `handoffs/20261001-005243_codex-local-worker_ui-7-final-verification-repair.md`, and one INDEX entry
- Commit/tag/release: one coherent repair/evidence commit; SHA and push/fetch equality in BRAIN return; no tag/release
- Safety impact: physical QA proved the Storage Readiness panel was intrinsic-width at the minimum window; a View-only max-width frame aligns it with Source, Destination and Transfer. No Models, ViewModel runtime semantics, Coordinator, Engine, Service, Xcode project, transfer, verification, report or SAFE TO EJECT changes.
- Checks: standalone full/default TransferControlsLabelTests PASS; Debug BUILD SUCCEEDED; focused 80 passed/0 failed/0 skipped; full 247 passed/0 failed/0 skipped; dark native QA at 900x660, 1120x760 and 1600x900 covered READY, COPYING, VERIFYING, SAFE TO EJECT, TRANSFER COMPLETE, TRANSFER ERROR and CANCELLED. Light appearance not available without changing system settings.
- Notes: extra worker draft removed; immutable 20260930-221451 handoff preserved. Exact model UNVERIFIED. Out-of-scope observation: the pre-existing allocated-byte storage estimate displayed 16 KB for a synthetic 1 GiB sparse fixture; no core change authorized. Single Next Action: RETURN_TO_BRAIN_FOR_FINAL_REDESIGN_ACCEPTANCE.

### 2026-09-30 - M2M Brain Return V2

- Date: 2026-09-30
- Task ID: M2M_BRAIN_RETURN_V2
- Task name: M2M Brain Return V2
- Agent: Codex local Worker / exact model UNVERIFIED
- Status: implemented; NORMAL handoff published; publisher dry-run/verify PASS; BRAIN review follows return
- Files changed: AGENTS.md; FST_AI/skills/fst-brain-return-finalizer/SKILL.md; FST_AI/tools/export_brain_return.py; FST_AI/tools/test_export_brain_return.py; handoffs/README.md; BRAIN compact/Command Center policy; task/work records; one NORMAL handoff
- Commit/tag/release: one coherent control-plane commit; no tag/release
- Safety impact: metadata-only Desktop transport; repository remains canonical; no production Swift/Xcode or workflow behavior
- Checks: exporter unittest 12/12 PASS; Python compile PASS; publisher dry-run/verify PASS; pre/post-publish diff check PASS; prior Desktop V1 33,185 bytes; V2 1,239-byte target; final commit/export gates recorded in V2 packet
- Notes: default packet contains pointers, hashes, gate state and explicit handoff facts only. Single Next Action: RETURN_TO_BRAIN.

### 2026-09-30 - UI-6 Metrics Presentation Contract Repair

- Date: 2026-09-30
- Task ID: FST-UI-6-REPAIR
- Task name: UI-6 Metrics Presentation Contract Repair
- Agent: Codex local Worker / exact model UNVERIFIED
- Status: implemented repair; BRAIN review pending
- Files changed: TransferControlsView.swift; pure TransferRuntimeMetricPresentation additions in TransferViewModel.swift; TransferControlsLabelTests.swift; TransferViewModelRuntimeXCTests.swift; required memory and one NORMAL handoff
- Commit/tag/release: one coherent repair plus handoff commit; final SHA/upstream proof in BRAIN RAW; no tag/release
- Safety impact: View-only active hero/bar eligibility and exact Copy/Verify titles; separate secondary snapshot average speed. Runtime, ETA algorithms, progress2, state machine, source safety, terminal results and SAFE TO EJECT unchanged.
- Checks: full/default standalone PASS; Debug BUILD SUCCEEDED (exit 0); focused 112 passed/0 failed/0 skipped; full canonical 247 passed/0 failed/0 skipped; pre-publication diff check PASS. Publication/final Git gates recorded by publisher/finalizer evidence.
- Notes: prior UI-6 Worker PASS was classified REPAIR by BRAIN. Case-insensitive DNG suppression unchanged. Physical UI QA NOT PHYSICALLY EXECUTED; ETA warm-up/unavailable distinction not added. Single Next Action: RETURN TO BRAIN FOR UI-6 REPAIR REVIEW. UI-7 is not authorized.

### 2026-09-30 - Rsync Progress2 ETA Speed Semantics Repair

- Date: 2026-09-30
- Task ID: FST-Progress2-Semantics-1
- Task name: Separate live remaining/current telemetry from checkpoint elapsed/average
- Agent: Codex local Worker / GPT-6 (variant UNVERIFIED)
- Status: implemented production repair; Worker FAIL at mandatory publication whitespace gate; BRAIN review pending
- Files changed: ProgressParser.swift; RsyncEngine.swift parser-output/diagnostic interpretation only; three existing parser/runtime test files; required memory, one NORMAL and one required CORRECTION handoff
- Commit/tag/release: one coherent task commit; final SHA in BRAIN RAW; no tag/release
- Safety impact: operator telemetry only; checkpoint emits progress without speed/ETA; existing last live estimates and state clears preserved. Lifecycle, observer, command, source safety, verification, reports, cancellation and SAFE TO EJECT unchanged.
- Checks: official v3.4.4 progress.c/manpage + upstream issue #392 researched before mutation; pre-fix actual event characterization confirms bug; one real bundled fixture/replay; standalone PASS; Debug PASS; focused 170/170; canonical 244/244, 0 failed/0 skipped; source diff check PASS, final publication diff check FAIL
- Notes: no --no-inc-recursive or version/UI/ETA smoothing change. Native GUI QA NOT PHYSICALLY EXECUTED. Single Next Action: RETURN TO BRAIN FOR PROGRESS2 SEMANTICS REVIEW; UI-6 unauthorized.

### 2026-09-30 - UI-5 Terminal States Error Presentation

- Date: 2026-09-30
- Task ID: FST-UI-5
- Task name: Separate terminal outcomes, error/report evidence and explicit actions
- Agent: Codex local Worker / GPT-6 (variant UNVERIFIED)
- Status: implemented; PASS_WITH_ADVISORY accepted by BRAIN
- Files changed: TransferControlsView.swift; ContentView.swift callback integration; pure TransferActionPresentation contract in TransferViewModel.swift; two existing test files; safety-status.md; required memory and one NORMAL handoff
- Commit/tag/release: one coherent task commit; final SHA in BRAIN RAW; no tag/release
- Safety impact: outcome text never secretly starts/retries; Retry/restart gated by unchanged canStartTransfer. Manual-check remains .error plus real message; report truth, active UI-4, workflow/algorithms and SAFE TO EJECT unchanged.
- Checks: Debug PASS; full/default standalone labels/navigation harness PASS; focused XCTest 137/137; full canonical 237/237, 0 failed/0 skipped; diff check PASS
- Notes: native GUI QA NOT PHYSICALLY EXECUTED. Single Next Action: RETURN TO BRAIN FOR UI-5 REVIEW; do not start UI-6.

### 2026-09-30 - UI-4 Active State Control Bar

- Date: 2026-09-30
- Task ID: FST-UI-4
- Task name: Separate active phase identity from operator action in a compact Control Bar
- Agent: Codex local Worker / GPT-6 (variant UNVERIFIED)
- Status: implemented; PASS_WITH_ADVISORY accepted by BRAIN
- Files changed: TransferControlsView.swift; SwiftUI-free TransferActionPresentation in TransferViewModel.swift; TransferControlsLabelTests.swift; TransferViewModelRuntimeXCTests.swift; required memory records and one NORMAL handoff
- Commit/tag/release: one coherent task commit; final SHA in BRAIN RAW; no tag/release
- Safety impact: Ready gated by unchanged canStartTransfer; Preparing has no action; Copying/Verifying retain CANCEL and confirmed-request guard. Terminal rendering/semantics, state ownership, algorithms and SAFE TO EJECT unchanged.
- Checks: Debug PASS; FULL/default standalone TransferControlsLabelTests PASS (stale action advisory resolved); focused XCTest 136/136; canonical 236/236, 0 failed/0 skipped; diff check PASS
- Notes: native visual QA NOT PHYSICALLY EXECUTED. Single Next Action: RETURN TO BRAIN FOR UI-4 REVIEW. UI-5 not authorized.

### 2026-09-30 - UI-3 Bandwidth Verification Controls

- Date: 2026-09-30
- Task ID: FST-UI-3
- Task name: Align Transfer Setup menus and preset tests with the approved vNext contract
- Agent: Codex local Worker / GPT-6 (variant UNVERIFIED)
- Status: implemented; PASS_WITH_ADVISORY accepted by BRAIN
- Files changed: `TransferControlsView.swift`, `RsyncBandwidthLimit.swift`, `VerificationMode.swift`, wording-only `TransferEvent.swift`, seven reconciled test files, FST memory records, and one NORMAL handoff
- Commit/tag/release: one coherent task commit; final SHA in BRAIN RAW; no tag or release
- Safety impact: canonical finite presets now 50/75/100/125/150/175/200; Unlimited remains nil. Converter/20..300 defensive bounds, workflow, algorithms, technical report labels, locking, and SAFE TO EJECT unchanged.
- Checks: Debug build PASS; focused XCTest 105/105; canonical XCTest 235/235, 0 failed/0 skipped; standalone bandwidth, actual Picker bandwidth regression, and report MVP tests PASS; stale product-spec search clean; `git diff --check` PASS
- Notes: native GUI QA NOT PHYSICALLY EXECUTED. Single Next Action: RETURN TO BRAIN FOR UI-3 REVIEW; do not start UI-4.

### 2026-09-30 - UI-2 Source Destination Storage Readiness

- Date: 2026-09-30
- Task ID: FST-UI-2
- Task name: Refine Source and Destination cards and add truthful Storage Readiness presentation
- Agent: Codex local Worker / GPT-6
- Status: implemented; PASS_WITH_ADVISORY accepted by BRAIN
- Files changed: the four authorized production Views (`ContentView.swift`, `SourceCardView.swift`, `DestinationCardView.swift`, `StorageAnalysisView.swift`), FST memory records, one NORMAL canonical handoff, and one CORRECTION handoff fixing its publisher-assigned filename row
- Commit/tag/release: one coherent task commit including the handoff; no tag or release
- Safety impact: SwiftUI presentation only; selection/bookmark behavior, preflight authority, transfer settings, backend data, and runtime semantics unchanged
- Checks: Debug build PASS; relevant XCTest suites PASS 112/112; canonical full XCTest suite PASS 233/233; `git diff --check` PASS
- Notes: no unsupported device metadata was introduced; physical UI checks NOT PHYSICALLY EXECUTED. Single Next Action: RETURN TO BRAIN FOR UI-2 REVIEW; do not start UI-3.

### 2026-09-30 - UI-1A Main Window Structural Shell

- Date: 2026-09-30
- Task ID: FST-UI-1A
- Task name: Implement the responsive vertical main window shell
- Agent: Codex local Worker / GPT-6
- Status: implemented; PASS_WITH_ADVISORY accepted by BRAIN
- Files changed: `FishSockTransfer/FishSockTransfer/Views/ContentView.swift`, current priority and FST memory records, and one NORMAL canonical handoff
- Commit/tag/release: one coherent task commit including the handoff; no tag or release
- Safety impact: SwiftUI layout only; transfer, notification, technical-log, bandwidth, verification, and state semantics unchanged
- Checks: Debug build PASS; relevant XCTest suites PASS 82/82; `git diff --check` PASS
- Notes: retained 900x660 pt minimum; Transfer scrolls vertically; native UI checks NOT PHYSICALLY EXECUTED. Single Next Action: RETURN TO BRAIN FOR UI-1A REVIEW.

### 2026-09-30 - FST BRAIN Return Bridge v1

- Date: 2026-09-30
- Task ID: FST-Brain-Return-Bridge-1
- Task name: Implement the single-file `03_FST_BRAIN.md` Worker-to-BRAIN return contract
- Agent: ChatGPT Web / GPT-5.6 Sol
- Status: implemented
- Files changed: `AGENTS.md`, `CLAUDE.md`, `FST_AI/README.md`, `FST_AI/memory/BRAIN_OPERATOR_COMPACT.md`, `FST_AI/skills/fst-brain-return-finalizer/SKILL.md`, `FST_AI/tools/export_brain_return.py`, `handoffs/README.md`, `handoffs/HANDOFF_TEMPLATE.md`, plus FST memory and handoff records
- Commit/tag/release: technical commit `082a07e07f8ffce3d7cf539b8098c6f9a7224f13`; no app tag or release
- Safety impact: control-plane/tooling/docs only; no Swift, Xcode, entitlement, bundled-rsync, transfer, verify, report, notification, update-check, or SAFE TO EJECT runtime behavior changed
- Checks: exporter `py_compile` PASS; synthetic clean repo/upstream PASS dry-run; dirty worktree downgraded requested PASS to FAIL; repo-escape RAW input rejected; GitHub tree/commit contents reviewed; no Xcode suite rerun under Lean Mode because application behavior did not change
- Notes: `~/Desktop/03_FST_BRAIN.md` is the only authorized FST Desktop file and is a non-canonical transport envelope containing FULL REPORT + RAW EVIDENCE + BRAIN OPERATOR. PASS requires verified handoff, clean worktree, and local HEAD equal configured upstream. ChatGPT Web cannot physically write the Owner Mac Desktop; first local Worker use must provide that physical-path proof. Single Next Action: BRAIN verifies this publication, then the next local FST Worker must exercise the finalizer once and return the physical `03_FST_BRAIN.md` bridge evidence.

### 2026-08-02 - v1.3.5 Release Sprint

- Date: 2026-08-02
- Task ID: v1.3.5-Release-Sprint
- Task name: FST v1.3.5 Release Build, Documentation, Tag, and GitHub Release Sprint
- Agent: Antigravity IDE / Gemini 3.6 Flash
- Status: implemented
- Files changed: `CHANGELOG.md`, `README.md`, `docs/00_AI_AGENT_START_HERE.md`, `docs/01_PRD.md`, `docs/02_FST_TECHNICAL_GUIDE.md`, `docs/03_PROJECT_MASTER_GUIDELINE.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, `FishSockTransfer/FishSockTransfer.xcodeproj/project.pbxproj`, `scripts/package-local-arm64.sh`, `FishSockTransfer/FishSockTransfer/Views/ContentView.swift`
- Commit/tag/release: v1.3.5 tag and release (pending)
- Safety impact: update version metadata and documents only; no runtime logic changes
- Checks: pre-release verification tests run and confirmed
- Notes: executing bounded final release procedure

### 2026-08-01 - Consolidated pre-commit review Sprint

- Date: 2026-08-01
- Task ID: Consolidated-PreCommit-Review-1
- Task name: Review every uncommitted and untracked change, verify internal consistency and safety, and produce an exact commit-grouping plan
- Agent: Antigravity IDE / Gemini 3.6 Flash
- Status: implemented (read-only review completed, READY_TO_COMMIT)
- Files changed: `/tmp/FST_CONSOLIDATED_PRECOMMIT_REVIEW.md` (scratch report), `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, and one new VERIFICATION handoff through the publisher
- Commit/tag/release: not committed, not tagged, not released; branch `main` at HEAD `6c35cad`
- Safety impact: review only — zero production Swift, test, or Xcode project changes introduced; validated safety invariants, secret scan, script syntax, JSON configs, and handoff publisher
- Checks: JSON configs PASS; shell syntax PASS; handoff publisher verify PASS; secret scan CLEAR; 4-group atomic commit plan produced
- Notes: All 9 modified files and 24 untracked paths classified; 4 atomic commit groups established. Single Next Action: Execute the approved commit plan one group at a time, stopping after each group for verification and without pushing.

### 2026-08-01 - Cancellation and engine-ownership investigation

- Date: 2026-08-01
- Task ID: Cancel-Ownership-Investigation-1
- Task name: Determine whether shared isCancelled and RsyncEngine/VerifyEngine active-operation references create reachable cross-generation cancellation or stale-callback defects after the workflowTask fix
- Agent: Claude Code / deepseek-v4-flash
- Status: implemented (investigation completed, NO_CROSS_GENERATION_RISK)
- Files changed: `/tmp/FST_CANCELLATION_ENGINE_OWNERSHIP_INVESTIGATION.md` (scratch report), `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, and one new VERIFICATION handoff through the publisher
- Commit/tag/release: not committed, not tagged, not released; branch `main` at starting HEAD `6c35cad`
- Safety impact: investigation only — no production Swift, test, or Xcode project code modified; confirmed NO_CROSS_GENERATION_RISK: workflowTask gate + actor FIFO serialization + engine cleanup-before-return make old cancellation/engine callbacks unable to affect the next admitted job; source read-only and SAFE TO EJECT invariants preserved
- Checks: targeted suites PASS 86/86 (TransferViewModelRuntimeXCTests, MetadataOnlySourceSafetyXCTests, VerificationHashStrategyXCTests, ReportEngineXCTests, ProgressParserXCTests) at `/tmp/FST-Cancellation-Ownership-Investigation`; full suite not run per Lean Mode (86/86 consistent with 172/172 baseline); `git diff --check` PASS; CodeGraph advisory queries PARTIAL/INCORRECT/BLOCKED per known 0.19.1 Swift defects, direct source authoritative
- Notes: classifications — overall NO_CROSS_GENERATION_RISK; `isCancelled` GENERATION_SAFE (reset only in `startTransfer` after admission reservation, before task creation; reads all complete before Job-1 return; cancelTransfer inert in terminal states); RsyncEngine SAFE (drainers awaited before terminal emission, `cleanup()` nils process before `startTransfer` returns, engine-actor FIFO prevents stale overwrite/cross-job cancel targeting, single terminal event, cancel-during-natural-exit routes to cancelled); VerifyEngine SAFE (per-invocation entry reset, no detached tasks, terminal event followed by return); late-callback matrix all finish-or-drop before ownership clear (observer/Telegram post-stop fires are operator-truth-only and state-guarded); production constructs exactly one Coordinator → one engine set (ContentView.swift:14, TransferViewModel.swift:86); engine sharing is test-injection-only. Single Next Action: perform one consolidated pre-commit review of all current uncommitted changes and produce a safe commit-grouping plan without committing.

### 2026-08-01 - Terminal-tail cross-job overlap fix

- Date: 2026-08-01
- Task ID: Terminal-Tail-Overlap-2
- Task name: Add deterministic terminal-tail overlap regression and apply the smallest Coordinator-owned active-workflow ownership fix
- Agent: Codex CLI / GPT-5
- Status: implemented; independent review pending
- Files changed: `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`, `FishSockTransfer/Tests/XCTest/TransferViewModelRuntimeXCTests.swift`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, and one new NORMAL handoff through the publisher
- Commit/tag/release: not committed, not tagged, not released; branch `main` at HEAD `6c35cad`
- Safety impact: closes the terminal-state/report-tail admission window. A terminal state can remain operator-visible, but no successor can be admitted until `runWorkflow(...)` has returned after terminal reporting and callbacks; source-media and copied-data safety are preserved.
- Checks: deterministic regression failed pre-fix 1/1 with `validating` versus expected `error`, then passed post-fix 1/1; relevant suites PASS 100/100; canonical suite PASS 172/172, 0 failed/0 skipped at `/tmp/FST-TerminalTail-Fix`; `git diff --check` PASS.
- Notes: `workflowTask` is now read as the Coordinator-owned active slot and is cleared only by `workflowDidFinish()` after the detached workflow finishes. New job admission remains blocked throughout Job 1 report snapshot/write/final callback, preventing report log contamination and late report-status overwrites. No ViewModel/runtime report/notification/update/verification change. Single Next Action: perform an independent review of the terminal-tail ownership fix and determine whether the remaining write-only workflowTask risk has been fully resolved.

### 2026-08-01 - Terminal state report and log overlap investigation

- Date: 2026-08-01
- Task ID: Terminal-Tail-Overlap-1
- Task name: Investigate whether publishing terminal TransferState before terminal report/log work completes creates a real cross-job overlap defect
- Agent: Antigravity IDE / Gemini 3.6 Flash
- Status: implemented (investigation completed, DEFECT_CONFIRMED)
- Files changed: `/tmp/FST_TERMINAL_REPORT_LOG_OVERLAP_INVESTIGATION.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, and one new VERIFICATION handoff through the publisher
- Commit/tag/release: not committed, not tagged, not released; branch `main` at starting HEAD `6c35cad`
- Safety impact: investigation only — no production Swift or test code modified; confirmed cross-job report log contamination and UI report status overwrite (`DEFECT_CONFIRMED`); source read-only and copied media safety invariants preserved
- Checks: targeted tests PASS 98/98 at `/tmp/FST-TerminalTail-Investigation`; `git diff --stat` confirms zero production or test code changes by this Sprint
- Notes: publishing terminal state (`.copyComplete`, `.safeToFormat`, `.error`, `.cancelled`) prior to `saveTerminalReport(...)` completion allows `canStartTransfer` to return `true` immediately. Job #2 can start while Job #1 is in `saveTerminalReport(...)`, causing Job #1's report to capture Job #2's log lines via `onLogsSnapshot`, and Job #1's `"Report saved: <path>"` log to overwrite Job #2's `reportStatusMessage` on the UI. Single Next Action: add a deterministic regression test reproducing the overlap, then apply the smallest Coordinator-owned fix.

### 2026-08-01 - VerifyEngine verification-mode-none contract resolution

- Date: 2026-08-01
- Task ID: VerifyNone-Contract-1
- Task name: Resolve internal VerifyEngine verification-mode-none semantics (TEST_AND_DOCUMENT)
- Agent: Claude Code / deepseek-v4-flash
- Status: implemented
- Files changed: `FishSockTransfer/FishSockTransfer/Engines/VerifyEngine.swift` (one doc comment), `FishSockTransfer/Tests/XCTest/VerificationHashStrategyXCTests.swift` (one focused test), `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, and one new NORMAL handoff through the publisher
- Commit/tag/release: not committed, not tagged, not released; branch `main` at starting HEAD `6c35cad`
- Safety impact: none — production `.none` path remains `.copyComplete` only; SAFE TO EJECT remains unreachable for `.none`; doc comment and test only, no runtime behavior change; source read-only, Coordinator state ownership, rsync, report, Telegram, and update-check behavior unchanged
- Checks: focused contract test `testDirectNoneModeVerificationDoesNotHashAndEmitsZeroVerifiedPassed` PASSED 1/1 before and after the comment; relevant suites (VerificationHashStrategyXCTests, MetadataOnlySourceSafetyXCTests, ReportEngineXCTests, TransferViewModelRuntimeXCTests, LogVisibilityFilterXCTests) PASS 98/98 with 0 failed and 0 skipped at `/tmp/FST-VerifyNone-Contract`; full suite NOT run per Sprint full-suite rule (test code + source comment only); `git diff --check` passed; CodeGraph incremental reindex (2 files parsed) + impact analysis low risk
- Notes: decision TEST_AND_DOCUMENT chosen over KEEP_AS_IS (contract was undocumented and untested), ADD_EXPLICIT_SKIPPED (would require >3 production files incl. ReportEngine exhaustive switches; result already carries `verifiedFiles == 0`), and BLOCKED (contract fully provable). Direct engine `.none` semantics: inventories built, count/size compared, no hashing, exactly one `.completed(.passed)` with `verifiedFiles == 0` — a copy-only pass; production never sends `.none` to the engine (Coordinator fast-exits to `.copyComplete` at TransferCoordinator.swift:231-249). Next action: investigate the terminal-state-before-report/log-completion overlap without modifying production code.

### 2026-08-01 - Repeated-start admission race fix

- Date: 2026-08-01
- Task ID: Safety-Admission-1
- Task name: Repeated-Start Admission Race Regression and Minimal Fix
- Agent: Codex CLI / GPT-5
- Status: implemented; independent review pending
- Files changed: `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`, `FishSockTransfer/Tests/XCTest/MetadataOnlySourceSafetyXCTests.swift`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, and one new NORMAL handoff through the publisher
- Commit/tag/release: not committed, not tagged, not released; branch `main` at starting HEAD `6c35cad`
- Safety impact: closes the confirmed double-admission window by reserving `.validating` inside the Coordinator actor before asynchronous workflow scheduling; source-media behavior, rsync/verify/report/Telegram/update-check behavior, and SAFE TO EJECT rules are unchanged
- Checks: new deterministic `testRepeatedStartAdmitsExactlyOneWorkflow` failed before the fix with `[ready, ready]` versus `[validating, validating]`; passed after the fix; relevant suites 57/57; canonical suite 170/170 with 0 failed and 0 skipped; `git diff --check` passed
- Notes: no ViewModel change was required because `TransferCoordinator` remains the authoritative admission boundary. `workflowTask` is still write-only and has no completion cleanup, so this patch introduces no stale task-clear path; the previously identified broader per-job cancellation-generation concern remains a separate review/Issue candidate. Next action: perform an independent review of the repeated-start fix and then investigate VerifyEngine verification-mode-none semantics.

### 2026-08-01 - Repeated-start admission race investigation

- Date: 2026-08-01
- Task ID: Investigation-1
- Task name: Repeated-Start Admission Race Investigation (TransferCoordinator.startTransfer/runWorkflow, TransferViewModel.startTransfer)
- Agent: Claude Code
- Status: implemented (investigation only; no fix applied by design)
- Files changed: none in `FishSockTransfer/` (investigation-only Sprint); `handoffs/` (one new timestamped VERIFICATION handoff + CURRENT + INDEX), `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: none — read-only investigation; no Swift/Xcode/entitlement/rsync/test change
- Checks: direct source inspection of TransferCoordinator.swift, TransferViewModel.swift, RsyncEngine.swift, VerifyEngine.swift, TransferControlsView.swift; grep for all production call sites and existing test coverage; CodeGraph advisory queries (call-graph tools mostly BLOCKED/INCORRECT per known Swift parser defect, cross-checked against direct source); `git status --short` / `git diff --check` clean for production paths
- Notes: classification CONFIRMED_RACE — full report at `/tmp/FST_REPEATED_START_INVESTIGATION.md` (not committed; local scratch path per Sprint instructions). Root cause: `TransferCoordinator.startTransfer()` admission guard reads `state` without synchronously reserving it (transition to `.validating` is deferred into a separately-scheduled `Task.detached` running `runWorkflow`); `TransferViewModel.startTransfer()` has no `transferState`/`canStartTransfer` guard at all; `RsyncEngine.startTransfer`/`VerifyEngine.startVerification` have no re-entry guard. Secondary defect: coordinator/engine `isCancelled` flags are shared per-instance, not per-job-generation, allowing a stale cancelled task's completion to mutate a newly-started job's state. `workflowTask` property is write-only (never read). No existing test covers repeated-start admission. Next action per published handoff: implement one focused regression test demonstrating the race, then apply the smallest admission-guard fix (see report's Minimal Fix Plan).

### 2026-08-01 - Handoff System implementation

- Date: 2026-08-01
- Task ID: Tooling-2
- Task name: Permanent append-only cross-agent Handoff System
- Agent: Claude Code
- Status: implemented
- Files changed: `handoffs/README.md`, `handoffs/HANDOFF_TEMPLATE.md`, `handoffs/INDEX.md`, `handoffs/CURRENT_HANDOFF.md`, one timestamped initial handoff, `FST_AI/tools/publish_handoff.py`, `AGENTS.md`, `CLAUDE.md`, `.agents/rules/fst-codegraph.md`, `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: none — documentation/tooling/routing only; no Swift/Xcode/entitlement/rsync change; source read-only invariants untouched
- Checks: publisher `py_compile` passed; 13/13 validation checks passed in a temp repo outside FST (first/second publication, overwrite rejection, heading validation, dry-run, verify mode, correction metadata, append-only INDEX); initial handoff published and verified (`cmp` CURRENT vs timestamped, exactly one INDEX entry)
- Notes: `handoffs/CURRENT_HANDOFF.md` is the operational continuation record; timestamped handoffs are immutable; INDEX is append-only; GitHub Issues remain the task queue; Sprint Mode and Lean Mode active; CodeGraph remains advisory (Swift parsing partial)

### 2026-08-01 - CodeGraph MCP integration

- Date: 2026-08-01
- Task ID: Tooling-1
- Task name: Official CodeGraph MCP integration for all coding models
- Agent: Claude Code
- Status: implemented (one manual approval pending: Claude `/mcp`)
- Files changed: `.mcp.json`, `.agents/mcp_config.json`, `.agents/rules/fst-codegraph.md`, `FST_AI/tools/fst-codegraph-mcp.sh`, `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md`, `FST_AI/memory/CODEGRAPH_INDEX_STATUS.md`, `AGENTS.md`, `CLAUDE.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `~/.codex/config.toml` (fst-codegraph entry only)
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: none — no Swift/runtime/package change; source read-only and SAFE TO EJECT invariants untouched; no credentials added
- Checks: `xcodebuild test` 169/169 passed (`/tmp/FST-CodeGraph-DerivedData`); smoke queries run vs direct source; index rebuilt force (71 files, 628 symbols); 12 authority docs indexed
- Notes: pinned `@astudioplus/codegraph-mcp@0.19.1` (official codegraph-ai/CodeGraph); profile `all` (no narrower profile has the full pre-edit tool set); known upstream Swift parser defect documented for 4 files (TransferViewModel, RsyncEngine, 2 XCTests); unrelated pre-existing `codegraph` fork entries untouched

### 2026-07-06 - Safety Policy-2 destination existing job path hardening

- Date: 2026-07-06
- Task ID: Safety Policy-2
- Task name: Destination Existing Job Path Hardening
- Agent: Codex
- Status: implemented
- Files changed: `FishSockTransfer/FishSockTransfer/Services/DriveService.swift`, `FishSockTransfer/Tests/XCTest/MetadataOnlySourceSafetyXCTests.swift`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`
- Commit/tag/release: pending; not committed, not tagged, not released
- Safety impact: blocks ambiguous existing destination job path before rsync; prevents report pollution into existing job path; no source mutation or overwrite/merge/reuse mode
- Checks: `git diff --check` passed; targeted `MetadataOnlySourceSafetyXCTests` passed; full `xcodebuild test` passed
- Notes: auto suffix, merge/reuse, overwrite, package, tag, and push not added

### 2026-07-06 - Runtime QA-2 failure/cancel truthfulness QA template

- Date: 2026-07-06
- Task ID: Runtime QA-2
- Task name: Failure / Cancel Truthfulness QA Plan
- Agent: Codex
- Status: planned/template prepared
- Files changed: `FST_AI/templates/failure-cancel-truthfulness-qa-v1.3.4.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: QA planning only; no Swift/runtime/package behavior changed
- Checks: `git diff --check`, `git status --short`, `git diff --stat`
- Notes: does not mark failure/cancel QA as passed; user must provide cancel/failure/mismatch/copy-only/observer/report evidence

### 2026-07-06 - Runtime QA-1 second-Mac package QA template

- Date: 2026-07-06
- Task ID: Runtime QA-1
- Task name: Second-Mac Package QA Plan and Evidence Template
- Agent: Codex
- Status: planned/template prepared
- Files changed: `FST_AI/templates/second-mac-package-qa-v1.3.4.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: QA planning only; no Swift/runtime/package behavior changed
- Checks: `git diff --check`, `git status --short`, `git diff --stat`
- Notes: does not mark second-Mac QA as passed; user must provide download/checksum/launch/transfer/report evidence

### 2026-07-06 - Batch AI-3A minor fix patch after AI-3 review

- Date: 2026-07-06
- Task ID: Batch AI-3A
- Task name: Minor Fix Patch After AI-3 Review
- Agent: Codex
- Status: implemented
- Files changed: `AGENTS.md`, `docs/00_AI_AGENT_START_HERE.md`, `FST_AI/memory/agent-roles.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/roles/release-gate.md`, normalized older `FST_AI/skills/*/SKILL.md`
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: docs/skills only; no Swift/runtime logic
- Checks: `git diff --check`, `git status --short`, `git diff --stat`, targeted wording scans
- Notes: aligned AGENTS role/archive wording, normalized remaining older skills, and clarified release gate is a skill/checklist, not an agent role

### 2026-07-06 - Batch AI-2 docs, skills, memory, harness, and archive cleanup

- Date: 2026-07-06
- Task ID: Batch AI-2
- Task name: FST AI Agent Docs, Skills, Memory, Harness, and Archive Cleanup
- Agent: Codex
- Status: implemented
- Files changed: `AGENTS.md`, `FST_AI/README.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/agent-roles.md`, `FST_AI/memory/project-baseline.md`, `FST_AI/prompts/README.md`, `FST_AI/research/AI_AGENT_SKILL_REFERENCE_NOTES.md`, `FST_AI/roles/`, focused `FST_AI/skills/`, `docs/00_AI_AGENT_START_HERE.md`, `docs/03_PROJECT_MASTER_GUIDELINE.md`, `docs/releases/release-notes-v1.3.3.md`, deleted `docs/archive/**/*.md`
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: documentation workflow only; no Swift/runtime logic
- Checks: `git diff --check`, `git status --short`, `git diff --stat`, wording/link scan, Markdown path sanity
- Notes: implemented after Batch AI-1 audit; no package/tag/push

### 2026-07-06 - Batch AI-1 audit

- Date: 2026-07-06
- Task ID: Batch AI-1
- Task name: FST AI Agent System Audit and Role Hierarchy Redesign
- Agent: Codex
- Status: implemented
- Files changed: none
- Commit/tag/release: no commit, no tag, no release
- Safety impact: read-only audit; no source/runtime changes
- Checks: Markdown inventory and repo state inspection
- Notes: recommended Batch AI-2 docs-only cleanup

### 2026-07-06 - Persistent Command Center handover memory

- Date: 2026-07-06
- Task ID: AI handover memory
- Task name: Create persistent Command Center handover memory and wire it into agent-facing docs
- Agent: Codex
- Status: implemented
- Files changed: `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/WORK_HISTORY.md`, `AGENTS.md`, `FST_AI/README.md`, `docs/00_AI_AGENT_START_HERE.md`, `docs/03_PROJECT_MASTER_GUIDELINE.md`
- Commit/tag/release: `a04ba55 docs: add persistent command center handover memory`
- Safety impact: documentation workflow only; no Swift/runtime logic
- Checks: `git diff --check`
- Notes: established current handover and history files
