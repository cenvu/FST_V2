# FST Command Center Handover

## Current Control Plane — M2M Brain Return V2 (2026-09-30)

- Status: implementation and NORMAL handoff complete; exporter suite 12/12 PASS; publisher dry-run and post-publish verify PASS; BRAIN review pending.
- Published handoff: handoffs/20260930-215015_codex-local-worker_m2m-brain-return-v2.md; CURRENT matches; INDEX added exactly one row.
- Contract source: BRAIN_OPERATOR_COMPACT.md and BRAIN ↔ WORKER Transport Policy below.
- Packet sizing: V1 prior packet 33,185 bytes; V2 target 1,239 bytes; no default verbatim bodies or handoff interpretation.
- PASS remains fail-closed on handoff verification, worktree, upstream equality, and Git observation. FAIL remains exportable.
- Size gate: previous V1 Desktop packet 33,185 bytes; V2 packet target 1,239 bytes; final export confirms packet length.
- No production Swift/Xcode changes and no historical handoff edits in this M2M batch; UI-7 was unauthorized at that point.
- Canonical continuation: handoffs/CURRENT_HANDOFF.md. Single Next Action: RETURN_TO_BRAIN.

## Current Sprint Status — UI-7 Final Verification Repair (2026-10-01)

- Owner explicitly routed the bounded UI-7 final verification repair from clean `main` at `ba4e7ec8cc1280c5b2535f2156bd6cc9bbfb6f8f`, equal to fetched `origin/main`.
- Physical macOS dark-mode QA at 900x660, 1120x760 and 1600x900 confirmed one Storage Readiness panel width defect. `StorageAnalysisView` now expands to the shared content width before `.standardPanel()`; no other UI changes were made.
- Full/default standalone PASS; Debug BUILD SUCCEEDED; focused XCTest 80/80; full XCTest 247/247, 0 failed/0 skipped. Native states observed: READY, COPYING, VERIFYING, SAFE TO EJECT, TRANSFER COMPLETE, TRANSFER ERROR and CANCELLED. Notification and Technical Log layouts were inspected at minimum width. Light mode remains unverified because the host was in dark appearance and a QA-only override did not produce a visible native window; no system appearance setting was changed.
- No Models, ViewModel runtime semantics, Coordinator, Engine, Service, Xcode project, state machine, copy/verify/report, cancellation or SAFE TO EJECT gate changes. Immutable prior UI-7 handoff preserved; the noncanonical worker draft was deleted; `handoffs/20261001-005243_codex-local-worker_ui-7-final-verification-repair.md` records exact evidence.
- Out-of-scope core observation for BRAIN triage: `DriveService.scanFolder` prefers allocated bytes; a synthetic 1 GiB logical sparse file allocated 16 KB and Storage Readiness displayed 16 KB. No core change was authorized or made.
- Exact model UNVERIFIED. CodeGraph MCP unavailable; GitHub issue search returned UNAUTHORIZED and required reauthentication. Direct source, tests and Git remain authoritative.
- Current handoff: `handoffs/CURRENT_HANDOFF.md`. Single Next Action: RETURN_TO_BRAIN_FOR_FINAL_REDESIGN_ACCEPTANCE. UI-8 is not authorized.

## Current Sprint Status — UI-6 Metrics Presentation Contract Repair (2026-09-30)

- BRAIN classified prior UI-6 PASS as REPAIR and explicitly routed this bounded presentation repair. UI-7 remains unauthorized.
- Initial clean main 07beddd fast-forwarded safely to 7fc804af050a09f602cb1907b697eb573116373e == origin/main. Control-plane Vietnamese language rule preserved.
- View consumes pure active-phase hero titles: COPY PROGRESS / COPY ETA / CURRENT COPY SPEED and VERIFY PROGRESS / VERIFY ETA / VERIFY ELAPSED. Hero and linear bar render only for copying/verifying; ready/terminal no longer look like active Copy, validating retains truthful preparation details.
- Secondary Copy grid restores AVERAGE COPY SPEED from copyRuntimeSnapshot.averageSpeedBytesPerSecond via the existing speed formatter. Current and average remain distinct; unknown average is '-'; Verify has neither Copy speed metric.
- Case-insensitive .dng suppression unchanged; no filename/log/rsync event or broad media taxonomy changes. Runtime, progress2 Timing/live/checkpoint suppression, 99% active clamp/100% final completion, freshness/fallback and ETA algorithms are unchanged from starting HEAD.
- Full/default standalone PASS; Debug BUILD SUCCEEDED (exit 0); focused 112 passed/0 failed/0 skipped; full canonical 247 passed/0 failed/0 skipped. Diff gate passed before handoff; publisher/final Git verification evidence follows finalization.
- Physical UI QA NOT PHYSICALLY EXECUTED; no native macOS GUI interaction harness was exposed. ETA warm-up versus long-term unavailable remains indistinguishable without a new heuristic, so existing no-value presentation is preserved.
- CodeGraph tools unavailable; direct View/helper/runtime/test inspection used. GitHub issue list returned no matching task. No issue mutation, release or UI-7 work.
- Canonical handoff: handoffs/CURRENT_HANDOFF.md; coherent repair/handoff commit and upstream/clean proof in final BRAIN RAW.
- Single Next Action: RETURN TO BRAIN FOR UI-6 REPAIR REVIEW.

## Current Sprint Status — Rsync Progress2 ETA Speed Semantics Repair (2026-09-30)

- UI-5 accepted PASS_WITH_ADVISORY by BRAIN; native visual QA advisory remains. This repair is authorized before UI-6; UI-6 remains unauthorized.
- Initial main ee73d92 clean; fetch/FF-only synchronized to 0cfcff39567c3bf0f4ab8ee10b1140a8ce7acc0f == origin/main before production mutation.
- Official v3.4.4 progress.c, exact tagged manpage and upstream issue #392 inspected before any experiment/patch. Exact upstream behavior matches BRAIN: live recent rate/remaining time; xfr#/to-chk or ir-chk checkpoint average rate/elapsed time.
- ProgressData.Timing has explicit liveEstimate and checkpoint payloads. Processor emits progress for both but speed/ETA only for live; checkpoint cannot clear/overwrite last live estimates. First-record diagnostics label average/elapsed distinctly. Existing progress clamp/completion, command, observer and core safety unchanged.
- Production scope exactly ProgressParser.swift + bounded RsyncEngine.swift interpretation. ViewModel/UI/Coordinator/Verify/report/models/services/project/bundled binary untouched; no traversal flag/version/smoothing change.
- Baseline characterization confirms previous incorrect events for both checkpoint markers. Real bundled 3.4.4 temporary fixture captured 15 live + 4 checkpoints in one run; source hashes unchanged and destination hashes equal. ir-chk not observed locally; exact upstream fixtures test it deterministically.
- Standalone PASS; Debug PASS; focused 170/170; full canonical 244/244, 0 failed/0 skipped; source diff check PASS but final publication diff check FAIL (raw sample trailing spaces). Native physical GUI QA NOT PHYSICALLY EXECUTED.
- CodeGraph tools unavailable; direct source/test impact fallback. Relevant GitHub issue search found NONE in FST; upstream #392 inspected. Final Git/transport evidence follows normal commit/push/fetch.
- Worker RESULT=FAIL at mandatory publication whitespace gate. Original NORMAL retained unchanged; full CORRECTION is canonical CURRENT. No whitespace override or historical edit.
- Canonical handoff: handoffs/CURRENT_HANDOFF.md. Single Next Action: RETURN TO BRAIN FOR PROGRESS2 SEMANTICS REVIEW.

## Current Sprint Status — UI-5 Terminal States Error Presentation (2026-09-30)

- BRAIN authorized UI-5 after accepting UI-4 as PASS_WITH_ADVISORY. Clean main start e096581023e29acfa9f61861788f9cb489caa5b8 equals fetched origin/main.
- Terminal Control Bar: TRANSFER COMPLETE is explicitly copy-only (blue), SAFE TO EJECT is verified-success (green), MANUAL CHECK REQUIRED is warning, TRANSFER ERROR is error/red, CANCELLED is non-success. Outcome surfaces are not Buttons. Admissible RETRY/START NEW TRANSFER are distinct native buttons; canStartTransfer remains authoritative.
- Existing .error + MANUAL CHECK REQUIRED message contract retained. Real error first line and remaining technical lines are shown without inferred recovery advice. View-only callback opens ContentView's Technical Log tab; deterministic callback and structural binding checks passed. Report status/path remains separate and inspectable; redundant CANCELLED/error rows removed.
- Only safety-status.md reconciled stale active SAFE TO EJECT: NO guidance. Active Control Bar/settings/metrics and ViewModel instance logic unchanged; no engine/service/coordinator/model/state/algorithm/report/notification/bookmark/project changes.
- Debug PASS; full/default standalone PASS; focused 137/137; canonical 237/237 (0 failures/skips). Native visual QA remains NOT PHYSICALLY EXECUTED; no screenshot or physical navigation claim.
- CodeGraph tools unavailable; direct source used. Matching UI-5 GitHub issue search found NONE. Final upstream/clean evidence and mandatory transport are generated after commit/push/fetch.
- Canonical handoff: handoffs/CURRENT_HANDOFF.md. Single Next Action: RETURN TO BRAIN FOR UI-5 REVIEW. Do not start UI-6.

## Current Sprint Status — UI-4 Active State Control Bar (2026-09-30)

- BRAIN authorized UI-4 after accepting UI-3 as PASS_WITH_ADVISORY. Clean main start: 562a889df1ce0e2e9bcd2d5b4ed7e9271851f199, equal to fetched origin/main.
- Active Control Bar separates state and action: READY / START TRANSFER; blocked setup / disabled START TRANSFER; PREPARING / no action; COPYING / CANCEL; VERIFYING / CANCEL. State uses text plus neutral/blue/orange presentation, never success-green or SAFE TO EJECT.
- Existing terminal action button rendering/wording preserved. ViewModel file changes are confined to SwiftUI-free TransferActionPresentation (START TRANSFER plus the existing enablement switch extracted for tests); no workflow change. Confirmation and TransferCancelRequestGuard behavior unchanged; settings remain locked during active workflow.
- Debug PASS; focused 136/136; canonical 236/236 (0 failed/skipped); full/default standalone TransferControlsLabelTests PASS, resolving the stale action expectation advisory. Native visual checks remain NOT PHYSICALLY EXECUTED.
- No Source/Destination/Storage, bandwidth/verification, metrics/ETA, engine/service/coordinator/report/notification/bookmark/state-machine/project changes. CodeGraph unavailable; direct source authoritative. Matching UI-4 issue search found NONE.
- Canonical handoff: handoffs/CURRENT_HANDOFF.md; final Git/upstream evidence and mandatory fallback packet in ~/Desktop/03_FST_BRAIN.md after finalization.
- Single Next Action: RETURN TO BRAIN FOR UI-4 REVIEW. Do not start UI-5.

## Current Sprint Status — UI-3 Bandwidth Verification Controls (2026-09-30)

- BRAIN authorized UI-3 after accepting UI-2 as PASS_WITH_ADVISORY. Starting synchronized main: `7625e6996d7606ffed590ea67111b34cc69e702f`; unknown local state was preserved (initial worktree clean).
- `RsyncBandwidthLimit.presetMegabytesPerSecond` is the sole finite preset source: `[50, 75, 100, 125, 150, 175, 200]`. The View derives its choices and appends nil Unlimited; no Custom UI. The converter and defensive 20..300 range are unchanged.
- VerificationMode.selectionLabel supplies friendly menu labels; operatorLabel/reportLabel, raw modes, hash mapping, and technical report identity remain unchanged. TransferError invalid-bandwidth change is wording-only.
- Debug build PASS; focused XCTest 105/105; canonical XCTest 235/235 with 0 failures/skips. Standalone bandwidth, actual Picker bandwidth regression, and report MVP tests PASS. Full native GUI checks NOT PHYSICALLY EXECUTED.
- No UI-2 card/storage changes, action/status redesign, progress/ETA, workflow, algorithm, source-safety, report semantics, notification, bookmark, state-machine, or Xcode-project changes. CodeGraph unavailable; direct source used. GitHub issue search found no matching UI-3 issue.
- Canonical continuation: handoffs/CURRENT_HANDOFF.md. Final commit/upstream evidence and refreshed transport: ~/Desktop/03_FST_BRAIN.md.
- Single Next Action: RETURN TO BRAIN FOR UI-3 REVIEW. Do not start UI-4.

## Current Sprint Status — UI-2 Source Destination Storage Readiness (2026-09-30)

- BRAIN authorized UI-2 after independently accepting UI-1A as PASS_WITH_ADVISORY; task began from clean `main@d634fdba12f9d20181e97b285937d4952d76ad1a`, equal to fetched `origin/main`.
- Production scope is exactly four SwiftUI Views: `ContentView.swift`, `SourceCardView.swift`, `DestinationCardView.swift`, and `StorageAnalysisView.swift`.
- Source/Destination fixed card heights were removed. Current source fields (identity/path/size/file/folder counts) and destination fields (path/filesystem/free space/writable/target preview) are displayed from existing metadata. Storage Readiness follows Destination and uses existing ViewModel metadata, insufficiency flag, and warning message; transfer preflight remains authoritative.
- No unsupported device metadata, ViewModel, Coordinator, Engine, Service, model, bookmark, transfer, report, notification, bandwidth, verification, or state semantics changed.
- Debug build PASS; targeted suites PASS 112/112; full XCTest PASS 233/233, 0 failed/0 skipped; `git diff --check` PASS. Native physical UI checks NOT PHYSICALLY EXECUTED because no native macOS GUI interaction harness was available.
- CodeGraph MCP was unavailable; direct source inspection was used. GitHub issue search found no UI-2 issue.
- Canonical evidence: `handoffs/CURRENT_HANDOFF.md`; final repository/upstream snapshot is in `~/Desktop/03_FST_BRAIN.md` after finalization.
- Single Next Action: RETURN TO BRAIN FOR UI-2 REVIEW. Do not start UI-3.

## Current Sprint Status — UI-1A Main Window Structural Shell (2026-09-30)

- BRAIN and Owner approved this bounded UI-1A implementation plan; the local task began from `main@24259dde198ae1d17114ed14e2f709b3a559df96`, equal to fetched `origin/main`.
- Production change is limited to `FishSockTransfer/FishSockTransfer/Views/ContentView.swift`: Transfer is Source -> Destination -> TransferControls in a vertical ScrollView; rigid 600 pt tab content and fixed header widths are removed; the 900x660 pt minimum remains.
- Existing top-level tabs and their actions remain; child views and all backend/runtime behavior remain unchanged. Bandwidth options, verification modes/labels, and state semantics remain unchanged.
- Debug build PASS; relevant XCTest suites PASS 82/82; `git diff --check` PASS. Native macOS window checks were NOT PHYSICALLY EXECUTED because no native GUI interaction harness was available.
- CodeGraph MCP was unavailable; direct source inspection was used. GitHub issue search found no UI-1A issue.
- Canonical evidence: `handoffs/CURRENT_HANDOFF.md`; final repository/upstream snapshot is in `~/Desktop/03_FST_BRAIN.md` after finalization.
- Single Next Action: RETURN TO BRAIN FOR UI-1A REVIEW. No later UI phase is authorized here.

## Project Identity

FST / FishSock Transfer is a native macOS SwiftUI app for DIT / Data Wrangler media offload workflows.

Primary workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT DESTINATION
```

FST helps operators collect copy and verification evidence for destination handoff. It does not format, erase, reuse, or eject source media.

Primary users:
- DIT
- Data Wrangler
- Assistant DIT
- Assistant Editor / small production teams

## Superseded Record — FST BRAIN Return Bridge v1 (2026-09-30)

- V1 established the single Desktop path and fail-closed PASS gates.
- V1 embedded handoff, RAW, and BRAIN Operator bodies verbatim. M2M Brain Return V2 above supersedes that payload contract with repository pointers and hashes.
- Desktop remains transport-only; GitHub remains canonical. The path stays ~/Desktop/03_FST_BRAIN.md.
- V1 did not change Swift/runtime/Xcode/entitlement/rsync/transfer/verify/report/SAFE TO EJECT behavior.
## Current Baseline After v1.3.4

## Current Sprint Status — consolidated pre-commit review Sprint (2026-08-01)

- CONFIRMED readiness classification: READY_TO_COMMIT.
- CONFIRMED all 9 modified tracked files and 24 untracked paths across repository reviewed and classified.
- CONFIRMED secret scan CLEAR; script and JSON configuration validations PASS; Handoff System `--verify` PASS.
- Established 4-group atomic commit plan without staging or committing any code.
- Next action: Execute the approved commit plan one group at a time, stopping after each group for verification and without pushing.

## Current Sprint Status — terminal-tail ownership fix (2026-08-01)

- CONFIRMED `TransferCoordinator.workflowTask` is now the active-workflow ownership gate. `startTransfer(...)` requires both an admissible terminal/ready state and `workflowTask == nil`.
- CONFIRMED the detached task clears ownership only after `runWorkflow(...)` returns, which is after each success, failure, and cancellation path completes `saveTerminalReport(...)` and its final log callback.
- CONFIRMED regression: `TransferViewModelRuntimeXCTests.testTerminalTailBlocksSecondCoordinatorStartUntilReportCallbacksFinish` paused Job 1 at `saveTerminalReport(...)`; pre-fix the second Coordinator request observed `.validating`, post-fix it remains `.error` and is not admitted.
- CONFIRMED test-only tail hook is `#if DEBUG`; release behavior and operator-facing terminal-state timing are unchanged.
- CONFIRMED validation: focused 1/1, relevant 100/100, and canonical 172/172 tests passed at `/tmp/FST-TerminalTail-Fix`; no failed or skipped tests.
- Remaining risk: the wider shared `isCancelled`/engine-process generation issue is not changed in this Sprint. Perform independent review of terminal-tail ownership and determine whether the remaining write-only workflowTask risk has been fully resolved.

Current repository baseline:
- Version: v1.3.4 build 20260706
- Tag: v1.3.4-b20260706
- HEAD on main: f0d0cbf
- GitHub Release: published with zip + checksum assets
- Release theme: Detailed TXT Report V1 hardening and safety wording cleanup

v1.3.4 is not a transfer/verify/hash/rsync/Telegram/update-check logic release.

v1.3.3 remains the packaged build network permission / sandbox outbound entitlement hotfix for manual GitHub update-check and Telegram HTTPS workflows.

Package state:
- `dist/FishSockTransfer-v1.3.4-b20260706-local-macOS13_5plus-arm64.zip`
- SHA256: `a8487b89d4f3545f6cdd6f3e2aabe132c81657b108768924fde0923c9dda7826`
- Local owner-side ad-hoc package
- Not Developer ID signed
- Not notarized
- macOS 13.5+
- Apple Silicon arm64 only

## Core Workflow

Current MVP workflow:

```text
one source -> one destination -> one active job -> copy -> verify -> report -> SAFE TO EJECT DESTINATION when verified
```

Verification `none` is copy-only and must end as transfer complete, not verified SAFE TO EJECT.

## Safety Philosophy

Priority:

```text
Data Safety > Reliability > Repeatability > Maintainability > Performance > Convenience
```

Rules:
- Source media is read-only.
- FST must never mutate source media.
- Copy success alone is not verified success.
- UI estimates must never decide safety.
- Final wording must not imply permission to erase, format, or reuse source media.

Approved operator wording:
- SAFE TO EJECT
- SAFE TO EJECT DESTINATION

Forbidden unless explicitly requested and policy-reviewed:
- SAFE TO FORMAT
- Source Format Authorization

## Current MVP Scope

In scope:
- Single source
- Single destination
- Single active job
- Folder transfer
- Bundled rsync 3.4.4 only
- Bandwidth limiting
- Runtime progress/log visibility
- Destination observer fallback metrics
- Verification modes: none, random33, full
- Detailed TXT Report V1
- Telegram best-effort notifications
- Manual GitHub release update-check
- Local Apple Silicon package workflow

Deferred:
- Multi-destination
- Queue / multi-job engine
- Database/history engine
- Cloud sync
- LTO/MHL/NAS/RAID workflow
- PDF report
- Report viewer
- Full manifest unless explicitly approved
- Major UI redesign
- Intel/universal package support

## Latest Release State

Version metadata:
- `MARKETING_VERSION = 1.3.5`
- `CURRENT_PROJECT_VERSION = 20260802`
- Package script `APP_VERSION = 1.3.5`
- Package script `BUILD_NUMBER = 20260802`
- Technical Logs footer badge: `v1.3.5`

GitHub Release:
- Tag: `v1.3.5-b20260802`
- Name: `FST v1.3.5 build 20260802`
- Assets:
  - `FishSockTransfer-v1.3.5-b20260802-local-macOS13_5plus-arm64.zip`
  - `SHA256SUMS-v1.3.5.txt`

Release rule:
- A git tag alone is not a downloadable release.
- Release is complete only when GitHub Release has zip + checksum assets and those assets are verified.

## Architecture Overview

Allowed flow:

```text
SwiftUI Views -> TransferViewModel -> TransferCoordinator -> Engines -> Services
```

Key ViewModels:
- `TransferViewModel`: UI state, bindings, progress presentation, Telegram settings/status, log presentation
- `TechnicalLogsUpdateViewModel`: manual GitHub update-check state

Key Coordinators:
- `TransferCoordinator`: workflow/state transitions, validation, copy/verify/report orchestration
- `NotificationCoordinator`: Telegram notification policy/throttling/delivery status

Key Engines:
- `RsyncEngine`: bundled rsync execution, process lifecycle, stdout/stderr streaming, cancellation, progress events
- `ProgressParser`: rsync output framing and progress/speed/ETA/current-file parsing
- `VerifyEngine`: inventory, sample/full verification, SHA256/xxHash64 hashing, verification events
- `ReportEngine`: Detailed TXT Report V1 generation and saving

Key Services:
- `BundledRsyncService`: bundled rsync path/version/executable validation
- `DriveService`: source/destination validation and storage metadata
- `BookmarkService`: security-scoped bookmarks
- `LoggerService`: logging wrapper
- `TelegramNotificationService`: Telegram HTTP API and Keychain token storage
- `AppUpdateService`: manual GitHub release check

## Transfer Flow

Transfer starts from `TransferViewModel.startTransfer()` and enters `TransferCoordinator.startTransfer(...)`.

Coordinator flow:
1. Validate source/destination/preflight.
2. Resolve and validate bundled rsync 3.4.4.
3. Run copy through `RsyncEngine`.
4. Stream stdout/stderr and structured transfer events.
5. Transition to verify or copy-complete depending on verification mode.
6. Generate terminal report.

Rsync rules:
- Use bundled rsync 3.4.4 only.
- No Apple `/usr/bin/rsync` fallback.
- No Homebrew/MacPorts fallback.
- No destructive source-mutation flags.
- Optional bandwidth limit must use converted rsync values.

Progress:
- Rsync progress is parsed from streamed output.
- Parser handles carriage return, newline, and CRLF records.
- Destination observer metrics can provide UI feedback when rsync output is delayed.

Safety boundary:
- Rsync lifecycle/exit status decides copy truth.
- Destination observer metrics never decide copy success.

## Verify Flow

Verification modes:
- `none`: copy-only; not verified SAFE TO EJECT
- `random33`: sample verification with SHA256
- `full`: full verification with xxHash64

Verification checks:
- Build source/destination inventory.
- Compare relative paths and file sizes.
- Hash selected/all eligible files according to mode.
- Emit verification progress/log events.
- Support cancellation.

Verify ETA:
- Approximate UI feedback only.
- Must never decide verification success or final safety.

## Report System

Detailed TXT Report V1 is current MVP evidence output.

v1.3.4 hardening:
- Clearer report sections
- Bilingual disclaimer near top
- Active report output avoids obsolete format-safety wording
- Verified success wording clarified as SAFE TO EJECT DESTINATION
- Report filenames/job IDs no longer use source name
- Operator-facing rsync detail reduced to rsync 3.4.4
- Technical log sharing note included
- Report wording safety tests updated

Report policy:
- FST reports copy and verification results only.
- Decisions to erase, format, or reuse source media remain the user's responsibility.
- Report generation must not contradict UI terminal state.
- Report logic is safety-relevant.

## UI / Operator Runtime Feedback

Runtime feedback includes:
- Source/destination cards
- Storage analysis
- Transfer controls
- Copy progress
- Verify progress
- Current item
- Speed
- Elapsed time
- ETA
- Technical logs
- App version / bundled rsync / license footer
- Manual update-check status
- Telegram notification status

Truth separation:
- Safety truth = copy success + verify result + report/final state.
- Transfer truth = bundled rsync lifecycle/exit/stderr/cancel/failure.
- Operator truth = UI progress, destination observer, speed, ETA, current item, verify ETA, logs, Telegram/update-check visibility.

Operator truth must never affect safety truth.

## Packaging and Release Pipeline

Correct release pipeline:

```text
commit -> build/test -> package -> validate package -> runtime QA -> checksum -> tag -> push main/tag -> GitHub Release -> upload zip/checksum -> verify assets
```

Standard package script:

```bash
bash scripts/package-local-arm64.sh
```

Package validation includes:
- Info.plist version/build
- macOS minimum
- app/rsync executability
- bundled rsync 3.4.4
- arm64 architecture
- dylib presence/architecture/loader paths
- ad-hoc codesign structure
- zip AppleDouble safety
- required zip entries

## Source-of-Truth Docs

Read first:
- `AGENTS.md`: root agent rules, current release state, architecture/safety law
- `FST_AI/memory/TASK_REGISTRY.md`: task repetition guard
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`: current Command Center baseline
- `FST_AI/memory/WORK_HISTORY.md`: append-only compact work history
- `docs/00_AI_AGENT_START_HERE.md`: active entry point
- `docs/01_PRD.md`: product mission and MVP scope
- `docs/02_FST_TECHNICAL_GUIDE.md`: technical architecture and safety rules
- `docs/03_PROJECT_MASTER_GUIDELINE.md`: doctrine and boundaries
- `README.md`: user-facing overview
- `CHANGELOG.md`: release summary
- `docs/releases/README.md`: release-note index
- `docs/releases/release-notes-v1.3.4.md`: latest release note
- `FST_AI/README.md`: AI engineering system

Historical material:
- Do not treat deleted, archived, old React/Vite, or web prototype files as production SwiftUI app code.

## AI Agent Workflow

Roles:
- Mi / ChatGPT Command Center: Technical Lead, Safety Gate, Prompt Architect, workflow router
- Codex: core engineering, release engineering, repo audits, small safe changes
- Antigravity: main SwiftUI/UI implementation
- Gemini Pro: small UI/ViewModel experiments when routed
- Claude: QA/safety review and second opinion

Roo/RooCode is dropped unless explicitly reintroduced.

Role source of truth:
- `FST_AI/roles/` is the only active role-doc home.
- Do not create `FST_AI/agents/` unless Mi explicitly changes the structure.

Routing:
- Core logic: Codex implements, Claude reviews, Mi gates.
- UI: Antigravity/Gemini implements, Claude or Mi reviews, Mi gates.
- Safety-critical: smallest safe Codex change, Claude review, Mi final decision.

## Standard Checks

```bash
git diff --check
```

```bash
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' build
```

```bash
xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS'
```

```bash
bash scripts/package-local-arm64.sh
```

## Known Risks / Gaps

MVP-critical:
- Do not regress bundled rsync-only execution.
- Do not allow copy-only success to appear verified.
- Do not let UI observer metrics influence safety.
- Do not reintroduce obsolete format-safety wording.
- Runtime QA still needed for real media/failure/cancel cases.

High priority:
- Maintain GitHub Release asset + checksum discipline.
- Preserve v1.3.3 entitlement behavior for networked update/Telegram flows.
- Keep Detailed TXT Report V1 truthful and consistent with terminal state.
- Verify packaged app behavior on another Apple Silicon Mac.
- Continue destination existing-folder policy review.

Medium priority:
- Improve runtime QA matrix and evidence capture.
- Tighten docs around release asset workflow.
- Review source/destination permission UX.
- Continue UI clarity polish without touching safety logic.

Deferred:
- Multi-destination
- Queue system
- Advanced manifest
- Major UI redesign
- Performance tuning unless blocking reliability
- Developer ID signing/notarization until user decides distribution path

## Recommended Next Batches

1. Release QA Evidence Batch: verify v1.3.4 GitHub zip/checksum download, unzip, launch on second Apple Silicon Mac, and document results.
2. Runtime Failure/Cancel QA Batch: test copy fail, verify fail, cancellation during copy, cancellation during verify.
3. Destination Existing-Folder Policy Batch: define no-unsafe-merge/overwrite rules.
4. Report V1 Evidence Review Batch: review report contents for operator sufficiency and final decision wording.
5. Permission UX Batch: review bookmark/access failures and operator messaging.
6. Packaging Automation Batch: make checksum/release asset verification harder to skip.
7. Docs Cleanup Batch: inventory old/prototype folders before archiving.
8. UI Clarity Batch: polish operator state/warnings without touching core safety logic.
9. Signing/Notarization Decision Batch: decide whether to add Developer ID signing and notarization.
10. Performance Observation Batch: measure many-small-files and slow-device behavior before optimizing.

## Rules for Future Assistants

- Never mutate source media.
- Never reintroduce SAFE TO FORMAT or Source Format Authorization wording unless explicitly requested and policy-reviewed.
- Use SAFE TO EJECT / SAFE TO EJECT DESTINATION for operator-facing output.
- Never let UI estimates, destination observer metrics, speed, ETA, current item, or Verify ETA affect copy success, verify success, report truth, or SAFE TO EJECT.
- Never use Apple/System/Homebrew rsync fallback.
- Git tag alone is not a downloadable release.
- Release is complete only after GitHub Release has zip + checksum assets.
- Do not delete ambiguous repo folders without inventory and user approval.
- Always separate safety truth, transfer truth, and operator truth.
- Always prioritize data safety over convenience/speed.
- For release tasks, include checksum and GitHub Release asset upload.

## Required Agent Startup

Before making changes, every AI agent must read:
- `FST_AI/memory/TASK_REGISTRY.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/WORK_HISTORY.md`
- `AGENTS.md`
- `docs/00_AI_AGENT_START_HERE.md`

If docs conflict, use this priority:
1. `AGENTS.md`
2. `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
3. `docs/00_AI_AGENT_START_HERE.md`
4. `FST_AI/memory/TASK_REGISTRY.md`
5. `FST_AI/memory/WORK_HISTORY.md`

Before executing a task, check:
- `FST_AI/memory/TASK_REGISTRY.md`
- `FST_AI/memory/WORK_HISTORY.md`

If a substantially similar task already exists, ask whether to rerun it, continue it, or review previous output.

After meaningful work, agents must propose an update to:
- `FST_AI/memory/WORK_HISTORY.md`
- `FST_AI/memory/TASK_REGISTRY.md`

If baseline changes, agents must also propose an update to:
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`

Meaningful work includes:
- source code changes
- safety policy changes
- report wording/schema changes
- release/package/tag/GitHub Release changes
- architecture changes
- workflow/AI-agent routing changes
- docs cleanup that changes source-of-truth status

## CodeGraph MCP Integration (2026-08-01)

- Official CodeGraph MCP runtime pinned: `@astudioplus/codegraph-mcp@0.19.1` (codegraph-ai/CodeGraph), server name `fst-codegraph`.
- Clients: Claude Code (project `.mcp.json`; one-time `/mcp` approval pending), Antigravity/Gemini (workspace `.agents/mcp_config.json` + rule `.agents/rules/fst-codegraph.md`), Codex CLI (global `~/.codex/config.toml`, wrapper scoped to FST).
- Wrapper: `FST_AI/tools/fst-codegraph-mcp.sh`; shared rules: `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md`; index status: `FST_AI/memory/CODEGRAPH_INDEX_STATUS.md`.
- Index: 71 files, 628 symbols, 12 authority docs, storage `~/.codegraph/` (project fst-v2-c035).
- Known limitation: codegraph-server 0.19.1 Swift parser fails on `TransferViewModel.swift`, `RsyncEngine.swift`, `AppUpdateServiceXCTests.swift`, `NotificationCoordinatorXCTests.swift` in multi-file workspaces; Swift call edges partial. Direct source inspection remains mandatory for safety-critical code (CodeGraph is an index, not the source of truth).
- No production code, tests, Xcode settings, entitlements, rsync, or safety behavior changed. Validation: `xcodebuild test` 169/169 passed.

## Handoff System (2026-08-01)

- `handoffs/CURRENT_HANDOFF.md` is the latest operational continuation record for all agents (Gemini, GPT, Claude, DeepSeek, future agents). Read it before and during work.
- Timestamped handoffs under `handoffs/` are immutable evidence; `handoffs/INDEX.md` is append-only history — never edit or reorder entries; publish a CORRECTION or VERIFICATION handoff instead of editing history.
- GitHub Issues remain the task queue. Git, tests, commits, pull requests, and actual source are the final confirmation sources; a handoff is never proof when repository evidence disagrees.
- Sprint Mode and Lean Mode are active.
- Publish completed work with `FST_AI/tools/publish_handoff.py`; full rules in `handoffs/README.md`.
- CodeGraph remains advisory (0.19.1; Swift parsing partial — four files fail to parse; direct source inspection mandatory).

## Repeated-Start Admission Baseline (2026-08-01)

- The confirmed repeated-start admission race is fixed in the current uncommitted worktree at `main` / `6c35cad`.
- `TransferCoordinator.startTransfer(...)` now reserves Coordinator-owned state as `.validating` immediately after its admissible-state guard and before scheduling `Task.detached`; a second immediate request therefore cannot create a second `runWorkflow`.
- Deterministic canonical regression: `MetadataOnlySourceSafetyXCTests.testRepeatedStartAdmitsExactlyOneWorkflow` calls Start twice without suspension in one isolated Coordinator region. Pre-fix evidence was `[ready, ready]`; post-fix evidence is `[validating, validating]`.
- Verification: focused 1/1 passed after fix; relevant Coordinator/ViewModel/report suites 57/57 passed; canonical full suite 170/170 passed with 0 failed and 0 skipped using `/tmp/FST-RepeatedStart-Fix`.
- No ViewModel, engine, report, notification, update-check, Xcode, entitlement, dependency, version, bundled-rsync, or release change was required.
- CodeGraph 0.19.1 remained advisory: Coordinator source context matched, but callers/impact/related-tests undercounted and `TransferViewModel.swift`, `RsyncEngine.swift`, plus the updated isolated-parameter test file failed Swift parsing.
- Next action: perform an independent review of the repeated-start fix and then investigate VerifyEngine verification-mode-none semantics.

## Verification-None Contract Baseline (2026-08-01)

- The internal VerifyEngine verification-mode-none semantics Sprint selected TEST_AND_DOCUMENT (uncommitted, `main` / `6c35cad`).
- Production contract: `TransferCoordinator` fast-exits on `mode == .none` after copy success (TransferCoordinator.swift:231-249) — `.copyComplete`, "TRANSFER COMPLETE. Verification disabled.", report with `verificationResult: nil`. `VerifyEngine.startVerification` is production-unreachable for `.none`; SAFE TO EJECT is unreachable.
- Direct engine contract (now documented in `VerifyEngine.startVerification`'s doc comment and pinned by `VerificationHashStrategyXCTests.testDirectNoneModeVerificationDoesNotHashAndEmitsZeroVerifiedPassed`): inventory build, file-count and size comparison still run; `.none` never hashes; `sampleFiles(.none)` returns `[]`; exactly one `.completed(.passed)` with `verifiedFiles == 0` / `passedFiles == 0` — a copy-only pass, not verified-safety evidence. Deterministic, no failure/cancel events.
- ADD_EXPLICIT_SKIPPED was rejected: it would require >3 production files (ReportEngine exhaustive `VerificationStatus` switches and UI/ViewModel mappings) and change report/UI behavior; the result object already carries the machine-readable `verifiedFiles == 0` distinction.
- Verification: focused contract test 1/1 before and after the comment; relevant suites (VerificationHashStrategyXCTests, MetadataOnlySourceSafetyXCTests, ReportEngineXCTests, TransferViewModelRuntimeXCTests, LogVisibilityFilterXCTests) 98/98 passed, 0 failed, 0 skipped (`/tmp/FST-VerifyNone-Contract`); full suite NOT run (test + comment only; no runtime behavior change); `git diff --check` passed.
- No production runtime behavior, rsync, report, Telegram, update-check, UI, state machine, or repeated-start changes were made.
- Next action: investigate the terminal-state-before-report/log-completion overlap without modifying production code.

## Compact Memory Version

FST / FishSock Transfer is a native macOS SwiftUI DIT/Data Wrangler app for one-source, one-destination, one-job media offload. Core workflow: SOURCE -> COPY -> VERIFY -> SAFE TO EJECT DESTINATION. Priority is Data Safety > Reliability > Repeatability > Maintainability > Performance > Convenience. FST does not format, erase, reuse, or eject source media; it reports copy and verification evidence for operator judgment.

Current baseline after v1.3.5: branch `main`, tag `v1.3.5`, GitHub Release has zip + checksum. Version metadata: `MARKETING_VERSION=1.3.5`, `CURRENT_PROJECT_VERSION=20260802`, package script `APP_VERSION=1.3.5`, `BUILD_NUMBER=20260802`. Package is local owner-side ad-hoc signed, not Developer ID signed, not notarized, Apple Silicon arm64 only, macOS 13.5+. v1.3.5 packages the Clear Folder controls, safe Start-to-Cancel behavior, full-workflow Retry, persistent security-scoped folder access, and fixes misleading external-volume free space reporting. v1.3.4 remains the Detailed TXT Report V1 hardening update.

Architecture: SwiftUI Views -> TransferViewModel -> TransferCoordinator -> Engines -> Services. `TransferCoordinator` owns workflow/state transitions. `RsyncEngine` owns bundled rsync execution/streaming/cancel. `ProgressParser` handles rsync output framing. `VerifyEngine` owns inventory/hash verification. `ReportEngine` owns TXT report generation. `BundledRsyncService` must validate bundled rsync 3.4.4; Apple/System/Homebrew fallback is forbidden. Telegram and update-check are visibility-only.

Safety model: safety truth is copy success + verification result + report/final state. Transfer truth is bundled rsync lifecycle, exit status, stderr, cancellation/failure. Operator truth is UI progress, destination observer metrics, speed, ETA, current item, verify ETA, logs, Telegram/update-check visibility. Destination observer and verify ETA are UI-only and must never decide copy success, verify success, report result, or SAFE TO EJECT. Verification modes: `none` copy-only; `random33` sample SHA256; `full` xxHash64 full verification.

AI roles: Mi/Command Center is technical lead/safety gate/prompt architect. Codex handles core engineering, release engineering, repo audits. Antigravity handles SwiftUI/UI. Gemini Pro can do small UI/ViewModel experiments if routed. Claude reviews QA/safety. Roo/RooCode is dropped unless reintroduced. `FST_AI/roles/` is the only active role-doc home. Agents check `TASK_REGISTRY.md` and `WORK_HISTORY.md` before repeated tasks. Standard checks: `git diff --check`; Xcode Debug build; full `xcodebuild test`; `bash scripts/package-local-arm64.sh`. Next priorities: second-Mac package QA, failure/cancel QA, destination existing-folder policy, report evidence review, permission UX, release automation, docs cleanup, UI clarity, signing/notarization decision.

## BRAIN ↔ WORKER Transport Policy

OWNER_VISIBLE=BRAIN_VI_REVIEW_ONLY
WORKER_PROMPT=M2M_DENSE
03_FST_BRAIN=M2M_DENSE_FALLBACK;TRANSPORT_ONLY
REPO_CANONICAL=GITHUB
PACKET=FST_BRAIN_RETURN_V2;POINTERS+SHA256+GATES+RAW_MANIFEST+EXPLICIT_HANDOFF_FACTS
DEFAULT_PAYLOAD=NO_VERBATIM;NO_SUMMARY_OR_INFERENCE
NEXT_ACTION_COUNT=1
