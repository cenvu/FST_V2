# Progress / ETA / Stuck Runtime Diagnosis

Date: 2026-07-02

Phase: Batch 5A diagnosis intake

Status: Diagnosis note only. No implementation patch in this pass.

## Bug Intake

Title: Real transfer appears stuck and ETA is not whole-job/operator useful

Reported behavior:

- Real source is roughly over 40 GB.
- Source contains around 7000 files and 325 folders.
- Destination appears mostly cloned.
- App UI appears stuck or stops showing meaningful progress.
- ETA appears to describe an rsync/current transfer time value, not whole project/job remaining time.
- Operator needs Project ETA / Whole Job ETA for producer/post communication.

Expected behavior:

- Copy phase should show truthful active copy progress.
- Primary operator time estimate should be whole-job/project ETA when enough data exists.
- Per-file or rsync-native time may be shown only as secondary/debug detail and must not be presented as project ETA.
- If rsync is still running but progress is not changing, UI/logs should make the slow/stalled condition inspectable.
- If copy has finished and verify is running, UI should clearly show verification phase rather than looking like copy is stuck.
- SAFE TO EJECT remains gated only by copy success plus verification success.

Safety classification:

- Risk level: Medium.
- Source mutation risk: No direct evidence.
- False SAFE TO EJECT risk: No direct evidence from this diagnosis.
- Operator trust risk: Yes. Misleading or missing whole-job ETA can cause bad on-set communication and can make a healthy long-running phase look stuck.
- Change type for next pass: Bug fix, Progress / ETA, possible UI state presentation.

Recommended route:

- Codex first for core diagnosis/fix.
- Claude review with progress/ETA, rsync engine, and state machine skills.
- Mi final safety gate after runtime QA.

## Files Inspected

- `FishSockTransfer/FishSockTransfer/Engines/RsyncEngine.swift`
- `FishSockTransfer/FishSockTransfer/Engines/ProgressParser.swift`
- `FishSockTransfer/FishSockTransfer/Engines/TransferEvent.swift`
- `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`
- `FishSockTransfer/FishSockTransfer/ViewModels/TransferViewModel.swift`
- `FishSockTransfer/FishSockTransfer/Views/TransferControlsView.swift`
- `FishSockTransfer/FishSockTransfer/Models/StorageMetadata.swift`
- `FishSockTransfer/FishSockTransfer/Services/DriveService.swift`
- `FishSockTransfer/FishSockTransfer/Engines/VerifyEngine.swift`
- `FishSockTransfer/Tests/XCTest/ProgressParserXCTests.swift`
- `FishSockTransfer/Tests/XCTest/TransferViewModelRuntimeXCTests.swift`
- `FishSockTransfer/Tests/ProgressParserTests.swift`

FST_AI guidance inspected:

- `FST_AI/README.md`
- `FST_AI/memory/current-priority.md`
- `FST_AI/memory/known-issues.md`
- `FST_AI/standards/safety-first.md`
- `FST_AI/standards/minimal-safe-change.md`
- `FST_AI/skills/fst-diagnose-bug/SKILL.md`
- `FST_AI/skills/fst-progress-eta-review/SKILL.md`
- `FST_AI/skills/fst-rsync-engine-review/SKILL.md`
- `FST_AI/skills/fst-state-machine-review/SKILL.md`
- `FST_AI/templates/bug-intake-form.md`
- `FST_AI/templates/change-risk-classification.md`

## Current Progress Data Flow

Current copy flow:

1. `RsyncEngine.startTransfer` launches bundled rsync with `-a -h --info=progress2 --outbuf=L` plus exclusion args.
2. `RsyncPipeDrainer.streamStdout` reads stdout in detached task chunks.
3. `RsyncOutputFramer` splits stdout records on carriage return/newline.
4. `RsyncStdoutRecordProcessor` parses each framed record through `ProgressParser`.
5. `ProgressParser` returns `ProgressData(progress, speedMBps, eta)` from rsync `progress2` fields.
6. `RsyncStdoutRecordProcessor` clamps active copy progress below final 100 and emits `.progress`, `.speed`, `.eta`.
7. `TransferCoordinator.executeRsync` forwards events to `onProgress`, `onSpeed`, and `onTransferTime`.
8. `TransferViewModel` stores values in `progress`, `speed`, and `eta`.
9. `TransferControlsView` renders progress percent, speed, and `RSYNC TIME`.

Important naming detail:

- `TransferEvent.eta` and `TransferViewModel.eta` currently carry the parsed rsync time field.
- The visible UI label is `RSYNC TIME`, not `PROJECT ETA`.
- No current field appears to represent whole-job/project ETA.

Current verify flow:

1. After successful rsync completion, `TransferCoordinator` transitions to `.verifying` unless verification mode is `.none`.
2. `VerifyEngine` builds source inventory, destination inventory, compares count/paths/sizes, selects sample/all files, then hashes.
3. Verification progress is emitted only during hash comparison as `passedCount / totalToVerify`.
4. During inventory/compare/sample setup, the UI can be in `.verifying` with progress at 0 and current file fallback text `Preparing verification...`.

## Evidence Found

Rsync lifecycle and parser:

- `RsyncEngine` drains stdout and stderr concurrently through detached tasks before interpreting exit status.
- `RsyncEngine` only emits final copy progress `100` after rsync exits with status `0`.
- `ProgressParser.activeCopyProgress` clamps active copy progress to 99 before successful process exit.
- `RsyncCommand` includes production progress flags `-a -h --info=progress2 --outbuf=L`.
- Existing tests cover production human-readable byte tokens, carriage-return records, parser false positives, and active 100 clamping.

Aggregate progress model:

- Source total bytes and file/folder count are known from `DriveService.sourceMetadata`.
- `SourceStorageMetadata` contains total bytes, file count, and folder count.
- `TransferCoordinator` captures source metadata during validation.
- That metadata is not currently connected to a whole-job ETA model.
- Rsync parsed byte-count token is validated but not retained as copied/transferred bytes.
- There is no app-level copied-byte accumulator or whole-job ETA calculation.

ETA semantics:

- `ProgressParser` parses the fourth rsync progress token into `eta`.
- `TransferCoordinator` logs it as `Rsync Time`.
- `TransferViewModel.applyTransferTime` stores it as `eta`.
- `TransferControlsView` displays it as `RSYNC TIME`.
- Tests assert rsync time forwarding and presentation, not whole-job ETA.
- Conclusion: the current app does not have a Project ETA / Whole Job ETA. It only surfaces rsync's progress2 time field.

UI/stuck visibility:

- Copy progress details show speed and rsync time only while state is validating/copying/verifying.
- During verification setup/inventory, progress can remain 0 until hashing begins.
- If copy reaches 99 while rsync is still finalizing, that is expected and safe; final 100 is intentionally withheld until rsync exit.
- If destination appears mostly cloned, rsync may spend time scanning/checking/updating metadata with little visible progress. Current UI does not expose a "last progress update" age or "rsync still running" indicator except technical logs.

State machine:

- Copy completion is gated on rsync `.completed`.
- Verification starts after rsync success.
- SAFE TO EJECT remains gated by verification success.
- No evidence found that stale progress alone can transition state to success.

MainActor/UI blocking:

- Coordinator workflow runs in detached tasks.
- Rsync pipe drains run in detached tasks.
- ViewModel updates are MainActor callbacks.
- Source/destination metadata refreshes are async tasks.
- No obvious MainActor blocking root cause found from static inspection.

## Suspected Root Causes

Primary suspected root cause:

- Missing whole-job ETA model. The app does not calculate Project ETA from source total bytes, copied bytes/progress, speed, and elapsed copy time. It only forwards rsync's parsed time field as `eta`/`RSYNC TIME`.

Secondary suspected root cause:

- The app does not retain parsed rsync byte count as copied bytes. Without copied bytes, ETA must rely on percent and speed, which may be less inspectable and harder to validate. `ProgressParser` validates byte-count shape but discards the actual byte-count value.

Tertiary suspected root cause:

- Verification setup has limited operator-facing progress. Inventory and path/size comparison can make the app look stuck in `.verifying` before hash progress starts, especially for thousands of files.

Possible but not confirmed:

- Rsync still running but no new parseable progress output while scanning/finalizing.
- Parser updating but UI not observing. Current diagnostics would help distinguish this via `DIAG [RSYNC TIMING]`, `DIAG [COORDINATOR]`, and `DIAG [VIEWMODEL]`.
- Destination already mostly complete causing rsync to compare quickly/slowly with sparse progress updates.

Less likely based on static inspection:

- State machine stuck after rsync completion. The copy/verify transitions are explicit and gated on engine completion.
- MainActor blocking. Long-running rsync and verification work are not obviously running on MainActor.
- Report/final state interaction. Report generation occurs after terminal state decisions and is not the likely source of active-progress stuck display.

## Unknowns

Runtime logs are needed to determine which stuck mode happened:

- Did `DIAG [RSYNC TIMING] First raw stdout chunk` appear?
- Did `DIAG [RSYNC TIMING] First parsed progress2 record` appear?
- Did `DIAG [COORDINATOR] First progress forwarded` appear?
- Did `DIAG [VIEWMODEL] First progress applied` appear?
- Was the app in `.copying` or `.verifying` when it looked stuck?
- Was progress stuck below 99, at 99, or reset to 0 after verify started?
- Did rsync exit successfully?
- Did verification inventory/build start and complete?
- Was the transfer mode `.random33`, `.full`, or `.none`?
- Was the destination already containing a partial or matching copy from a prior run?

## Classification

Likely areas:

- Aggregate progress model: confirmed gap.
- Whole-job ETA calculation: confirmed gap.
- UI binding/presentation: likely, because the UI exposes `RSYNC TIME` but not Project ETA.
- Rsync progress output: possible runtime contributor, not confirmed.
- Progress parser: possible if runtime output shape is unhandled, but current tests cover common `-h --info=progress2` records.
- State machine transition: possible only if runtime logs show rsync completed but state did not advance; not currently supported by static evidence.
- MainActor/UI blocking: low confidence from static inspection.
- Verify phase not being shown: possible operator perception issue during inventory/compare before hash progress.
- Report/final state interaction: unlikely for active stuck/ETA behavior.

## Recommended Smallest Safe Fix

Recommended next implementation should be small and phased:

1. Add an internal copy progress model that distinguishes:
   - rsync raw percent
   - displayed copy percent
   - copied bytes if parseable
   - total source bytes from `SourceStorageMetadata`
   - copy elapsed time
   - whole-job/project ETA
2. Keep rsync process lifecycle and flags unchanged.
3. Keep final copy completion gated only on rsync exit status `0`.
4. Do not fake ETA. Show Project ETA only when enough inputs exist and values are sane.
5. Preserve `RSYNC TIME` only as secondary/debug wording or rename it clearly so it cannot be mistaken for whole-job ETA.
6. Add tests for whole-job ETA calculation and UI/ViewModel presentation rules.
7. Add runtime QA steps for:
   - large many-file copy
   - already-mostly-cloned destination
   - verify inventory period visibility
   - copy at 99 before rsync exit

Minimum implementation surface likely:

- `ProgressParser.swift`: optionally parse and expose transferred byte count from the first progress2 token.
- `TransferEvent.swift`: possibly add a copy metrics event instead of overloading `.eta`.
- `TransferCoordinator.swift`: pass source total bytes / copy start time into progress handling, or forward copied bytes from engine safely.
- `TransferViewModel.swift`: own operator-facing Project ETA fields and presentation formatting.
- `TransferControlsView.swift`: display Project ETA as primary; keep rsync time secondary only if desired and approved.
- Tests: progress parser, ViewModel runtime metrics, TransferControls label/presentation tests.

Avoid in next pass:

- No rsync flag changes.
- No bundled rsync validation changes.
- No verification hash logic changes.
- No SAFE TO EJECT state machine changes.
- No broad UI redesign.
- No database/telemetry/background scheduler.

## Claude Review Skills Needed

Required:

- `fst-progress-eta-review`
- `fst-rsync-engine-review`
- `fst-state-machine-review`

Optional if UI wording changes:

- `fst-ui-state-review`
- `fst-ui-accessibility-review`

## Xcode Runtime QA Needed

Required: yes.

Suggested matrix:

- 40 GB class source, thousands of files, fresh destination.
- Same source, destination already mostly populated from a previous run.
- Verification mode `.random33`.
- Verification mode `.full` if runtime budget allows.
- Verification mode `.none` to confirm copy-only terminal state remains `TRANSFER COMPLETE`.
- Cancel during copy and cancel during verify.

Runtime evidence to capture:

- Screenshot/video during copy with Project ETA visible.
- Screenshot/video during verify inventory/setup and hash progress.
- Technical Logs lines containing rsync raw stdout, parsed progress, coordinator forwarded progress, and ViewModel applied progress.
- Final report confirming terminal state and timing remains truthful.

Pass criteria:

- UI does not show per-file/rsync time as Project ETA.
- Project ETA appears only when calculable.
- If ETA is unavailable, UI says unavailable/estimating rather than inventing time.
- Copy progress never reaches final 100 before rsync exits successfully.
- Verification phase is visibly distinct from copy.
- SAFE TO EJECT appears only after verification pass.

Fail criteria:

- UI still provides only `RSYNC TIME` for operator time estimate.
- UI shows Project ETA that is actually rsync per-file/native time.
- Copy appears stuck with no logs or visible indication that rsync/verify is still active.
- SAFE TO EJECT appears after copy-only, failed, or cancelled transfer.
