# Claude Code Session Context

Generated for a repository-understanding and project-setup task (2026-08-01).
No production code was modified. This file is maintained by Claude Code sessions.

## Generated Snapshot

- generation date: 2026-08-01
- repository root: /Users/cenvu/DEV/FST_V2
- branch: main
- HEAD: 6c35cad12a20e664bbcaf972bf03f52589792dd0 (`fix: block existing destination job paths before transfer`)
- nearest tag: v1.3.4-b20260706 (HEAD is 5 commits past the tag)
- worktree status: clean before setup; only `CLAUDE.md` and this file added by setup
- Claude Code version: 2.1.220
- machine: macOS 15.7.7 (arm64, MacBook Pro), Xcode with macOS 26.2 SDK

## Authority Files Read

- AGENTS.md — present
- FST_AI/memory/COMMAND_CENTER_HANDOVER.md — present
- docs/00_AI_AGENT_START_HERE.md — present
- FST_AI/memory/TASK_REGISTRY.md — present
- FST_AI/memory/WORK_HISTORY.md — present
- docs/01_PRD.md, docs/02_FST_TECHNICAL_GUIDE.md, docs/03_PROJECT_MASTER_GUIDELINE.md — present
- CHANGELOG.md, README.md — present
- ~/Desktop/FST_AI_PROJECT_HANDOVER.md — present (orientation material only; its "HEAD matches v1.3.4-b20260706" statement is stale — actual HEAD is 6c35cad)
- FST_AI/memory/CODEX_SESSION_CONTEXT.md — missing; nothing to preserve (no concurrent Codex context file exists)

Conflicts found between authority docs and repository state are listed under
"Documentation and Code Conflicts".

## Product Mission

FST / FishSock Transfer is a native macOS SwiftUI DIT/Data Wrangler media
offload app. It answers: "Can the source media be safely ejected and handed
off?" It provides copy and verification evidence only; it never formats,
erases, reuses, or ejects source media. Workflow:
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT / OPERATOR HANDOFF.
Priority: Data Safety -> Reliability -> Truthful Operator Feedback -> Speed -> Convenience.

## Non-Negotiable Safety Invariants

- Source media is read-only; no mutation, delete, rename, move, metadata write, or cleanup on source.
- Copy success alone is not verified success.
- SAFE TO EJECT = authoritative copy success AND authoritative verification success.
- Verification mode `none` ends at `copyComplete`; never `safeToFormat`, never SAFE TO EJECT.
- Production transfer uses bundled rsync 3.4.4 only; silent fallback to /usr/bin/rsync, Homebrew, MacPorts, or any other rsync is forbidden.
- Destination-observer metrics, UI progress, Telegram notifications, and update-check results never authorize copy success, verification success, or SAFE TO EJECT.
- Operator-facing output uses SAFE TO EJECT / SAFE TO EJECT DESTINATION; `safeToFormat` is a legacy internal state name.
- Only `TransferCoordinator` may change `TransferState`.

## Verified Architecture

CONFIRMED — dependency flow is strictly: SwiftUI View -> TransferViewModel ->
TransferCoordinator -> Engines -> Services.

- `TransferCoordinator` — `public actor` (Coordinators/TransferCoordinator.swift). Owns validation, workflow orchestration, state transitions, SAFE TO EJECT gate, terminal report trigger.
- `TransferViewModel` — `@MainActor` (ViewModels/TransferViewModel.swift). Mirrors coordinator state via callbacks (`applyTransferState`); owns progress/speed/ETA/current-file presentation, destination-observer fallback metrics, Telegram notification side-effects, report-status messages. Its `logs` array is the report's FULL TECHNICAL LOG source of truth.
- Engines: `RsyncEngine` (actor, includes `DestinationActivityObserver`, `RsyncCommand`, pipe drainers, timing diagnostics), `ProgressParser` (nonisolated, includes `RsyncOutputFramer`), `VerifyEngine` (actor, includes custom `XXHash64`), `ReportEngine` (actor).
- Services: `BundledRsyncService` (actor), `DriveService` (actor, includes `TransferPreflightValidator`/`TransferPreflightError`), `BookmarkService` (actor), `LoggerService` (actor), `TelegramNotificationService` (+ `KeychainTelegramTokenStore`, `NotificationSettingsStore`), `AppUpdateService`.
- Additional coordinator: `NotificationCoordinator` (actor) — Telegram policy/throttling/dedupe; cannot reach `TransferState`.
- Additional ViewModels: `TechnicalLogsUpdateViewModel` (manual update check).
- `TransferState` is an enum of: ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled.

## Actual Runtime Flow

CONFIRMED (TransferCoordinator.swift):

1. `TransferViewModel.startTransfer()` guards bundled rsync availability, source/destination selected, destination space, bandwidth validity, then calls `coordinator.startTransfer(source:destination:bandwidthLimit:mode:)`.
2. Coordinator guards restartable states, spawns `Task.detached` running `runWorkflow`:
   - `.validating`: `DriveService.validateSource` -> `sourceMetadata` scan -> `validateDestination` -> `calculateReliableFreeSpace` -> `TransferPreflightValidator.validate` (blocks same source/destination, destination-inside-source, source-inside-destination, existing destination job path, no transferable files, insufficient space). Failure -> `.error` + terminal report.
   - `.copying`: builds `TransferRequest`; `executeRsync` streams `TransferEvent`s from `RsyncEngine.startTransfer` (progress/speed/eta/currentFile/log; terminal completed/cancelled/failed). `DestinationActivityObserver` snapshots destination-side growth every 5 s for UI fallback only.
   - Mode `none` -> `.copyComplete` + report (TRANSFER COMPLETE; verification disabled). Never verifies.
   - `.verifying`: `VerifyEngine.startVerification` against `destination/<sourceName>` with mode from `VerificationRequest`; pass -> `.safeToFormat` + report (SAFE TO EJECT DESTINATION); fail -> `.error` + report (MANUAL CHECK REQUIRED); cancel -> `.cancelled` + report.
   - Terminal reports written by `saveTerminalReport` -> `ReportEngine.saveReport` -> `FST_Report_<jobID>.txt` in destination root (jobID = `FST-yyyyMMdd-HHmmss-XXXXXXXX`, never uses source name). Full log snapshot from ViewModel (fallback: LoggerService).
3. `cancelTransfer()`: only while state is `.copying`/`.verifying`; sets `isCancelled`, stops observer, calls `rsyncEngine.cancel()` (terminate) or `verifyEngine.cancel()`; engine emits `.cancelled`; coordinator ends at `.cancelled` (never SAFE TO EJECT).

## TransferState Mutation Map

CONFIRMED — sole writer is `TransferCoordinator.updateState` (TransferCoordinator.swift:71-74); all call sites inside the actor:

- `.validating` — line 124
- `.error` — lines 143 (validation), 210 (copy fail), 286 (verify fail)
- `.cancelled` — lines 160 (validation cancel), 184 (copy cancel), 258 (verify cancel)
- `.copying` — line 177
- `.copyComplete` — line 230 (mode `.none` fast exit)
- `.verifying` — line 250
- `.safeToFormat` — line 307 (only after verify pass)

Grep confirms no other file assigns coordinator state. `TransferViewModel.transferState` and `TechnicalLogsUpdateViewModel.state` are UI-side mirrors/unrelated (AppUpdateState).

## SAFE TO EJECT Proof

CONFIRMED:

- The only transition to `.safeToFormat` is TransferCoordinator.swift:307, reached only when `executeVerify` returns `(true, result, nil)`.
- `VerifyEngine` emits `.completed(result)` with `result.status == .passed` only after: source/destination inventory counts match, every relative path present, every size equal, and all sampled file hashes equal (VerifyEngine.swift:59-163). `random33` uses SHA256 (min 1 file, ~33% size-weighted random sample); `full` hashes all files with the bundled custom XXHash64.
- `ReportEngine.finalStatusDescription` renders "SAFE TO EJECT DESTINATION" only when state is `.safeToFormat` AND mode != `.none` AND `verificationResult == .passed`; otherwise "MANUAL CHECK REQUIRED" (ReportEngine.swift:170-179). `safeToEjectDestinationDescription` mirrors that.
- UI title "SAFE TO EJECT" for `.safeToFormat` (TransferControlsView.swift:476-478); copy-only success is "TRANSFER COMPLETE" with "Verification was disabled".
- Verification mode `.none` never reaches `VerifyEngine` in production (coordinator fast-exits at line 229).

## Bundled Rsync Resolution

CONFIRMED:

- Binary: `FishSockTransfer/FishSockTransfer/rsync` — `rsync version 3.4.4 protocol version 32`, Mach-O arm64, executable. Included in the app via `PBXFileSystemSynchronizedRootGroup`; dylibs (libpopt/liblz4/libzstd/libxxhash/libcrypto) copied by "Copy Bundled Rsync Dylibs" run-script phase; package script stages it to `Contents/Resources/rsync`.
- `BundledRsyncService` (Services/BundledRsyncService.swift): `Bundle.main.url(forResource: "rsync")` -> exists -> executable -> `rsync --version` (2 s timeout, SIGKILL fallback) -> canonical parse "rsync version X.Y.Z protocol version N" -> exact match "3.4.4"; any failure returns `.unavailable` with diagnostics. No fallback path anywhere (grep of all Swift sources for /usr/bin/rsync, Homebrew, MacPorts: zero hits).
- `RsyncCommand` args: `-a -h --info=name1,progress2 --outbuf=N` + optional `--bwlimit=<KiB>` + exclusions + `source dest/` (RsyncEngine.swift:744-791).
- Exit-code mapping: 0 -> completed (progress forced to 100.0 first); 20/9 or engine-cancelled -> cancelled; else `.rsyncExit(code)` (24 -> sourceUnavailable, 30 -> timeout) -> failed -> error. Docs table also lists 11 (I/O) and 23 (partial transfer) -> mapped to generic `.rsyncExit` raw-code message (see Suspected Risk Areas).

## Verification Modes and Algorithms

CONFIRMED:

- `none` — no hashing; coordinator ends at `copyComplete`; report says "Verification Result: OFF - NOT VERIFIED BY FST" and never SAFE TO EJECT.
- `random33` — SHA256 (CryptoKit), target = max(1, ceil(0.33 * count)), size-weighted random sampling.
- `full` — custom `XXHash64` (VerifyEngine.swift:359-507) over all files, 4 MB chunks.
- Checks order: file count -> per-path presence -> per-path size -> hash. Fail fast on first mismatch (fileCountMismatch / destinationMissing / fileSizeMismatch / hashMismatch). Empty source with mode != none -> noTransferableFiles. Cancellation propagates as `.cancelled`. Verify runs off MainActor (actor + await yields).
- INFERRED RISK: `VerifyEngine.sampleFiles(.none)` returns `[]`, so if `startVerification` were ever invoked with `.none` it would emit `.completed(.passed)` (VerifyEngine.swift:99-111). Currently unreachable because the coordinator fast-exits, but the engine itself does not enforce "none can never pass".

## Reports, Logs, Notifications, and Update Check

CONFIRMED:

- `ReportEngine` TXT V1: bilingual disclaimer near top, Operator Summary (Final Status, SAFE TO EJECT DESTINATION: YES/NO, Decision Reason), Source/Destination, Copy Result, Verify Result, Safety Decision, Warnings/Errors from logs, Timing, FULL TECHNICAL LOG section. Filename `FST_Report_<jobID>.txt` with `_N` suffix collision handling. `errorCount = max(1, failedFiles)` on `.error`.
- `LoggerService`: actor, in-memory `[LogEntry]`, categories info/warning/error/success/transfer/stdout/stderr/file/progress/verify/system. UI log filtering (`LogVisibilityFilter`) is display-only and does not mutate the report log store.
- Telegram: `NotificationCoordinator` + `TelegramNotificationService`; POST to fixed `https://api.telegram.org/bot<token>/sendMessage`; token in Keychain (`KeychainTelegramTokenStore`); settings in UserDefaults; terminal-event dedupe; heartbeat 15/30 min. Failures and disabled state return status objects only — they cannot change transfer state. Notification messages use source/destination names, never full paths.
- Update check: `AppUpdateService` GET `https://api.github.com/repos/cenvu/FST_V2/releases/latest` (read-only, 15 s timeout), semantic version compare, manual trigger only. It cannot mutate transfer state or app bundle.

## Current Xcode Configuration

CONFIRMED (xcodebuild -list / -showBuildSettings):

- Project: `FishSockTransfer/FishSockTransfer.xcodeproj`; shared scheme `FishSockTransfer`; targets `FishSockTransfer` (app) + `FishSockTransferTests` (unit bundle).
- Deployment target: macOS 13.5 (effective); ARCHS arm64; SDK macOS 26.2; SWIFT_VERSION = 5.0 (language mode; Swift 6-compatible compiler, SWIFT_APPROACHABLE_CONCURRENCY = YES).
- MARKETING_VERSION = 1.3.4; CURRENT_PROJECT_VERSION = 20260706; bundle id `com.cen.FishSockTransfer`; CODE_SIGN_STYLE Automatic, CODE_SIGN_IDENTITY = "-" (ad-hoc), no development team.
- Sandbox: ENABLE_APP_SANDBOX = YES; entitlements (FishSockTransfer/FishSockTransfer.entitlements): `com.apple.security.app-sandbox`, `com.apple.security.files.user-selected.read-write`, `com.apple.security.network.client` (v1.3.3 network-client entitlement preserved).
- No package dependencies.

## Current Test Inventory

CONFIRMED — test target `FishSockTransferTests` compiles the 11 files under
`Tests/XCTest/`: AppUpdateServiceXCTests, BundledRsyncServiceXCTests,
LogVisibilityFilterXCTests, MetadataOnlySourceSafetyXCTests,
NotificationCoordinatorXCTests, ProgressParserXCTests, ReportEngineXCTests,
RsyncBandwidthLimitXCTests, SemanticVersionXCTests,
TransferViewModelRuntimeXCTests, VerificationHashStrategyXCTests.

The 7 legacy files directly under `Tests/` (BundledRsyncServiceTests.swift,
ProgressParserTests.swift, ReportEngineMVPReportTests.swift,
ReportEngineWordingTests.swift, RsyncBandwidthLimitTests.swift,
TransferControlsLabelTests.swift, MetadataOnlySourceSafetyTests.swift) are NOT
in any build target (grep of pbxproj: 0 references).

Verification run (2026-08-01, Claude-specific DerivedData):

```text
xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -destination 'platform=macOS' \
  -derivedDataPath /tmp/FST-Claude-DerivedData
```

- exit code: 0; result: Passed
- 169 passed, 0 failed, 0 skipped (macOS 15.7.7, arm64, "My Mac")
- No warnings or blockers recorded; no signing required (ad-hoc).

## Current Git Work

- Branch main, HEAD 6c35cad, clean worktree.
- Commits since v1.3.4-b20260706 (5): a04ba55 (handover memory docs), 2a108dc (AI agent docs cleanup), 52e0ecf (second-Mac QA template), 045bd85 (failure/cancel QA template), 6c35cad (Safety Policy-2: block existing destination job paths before transfer — DriveService.swift + MetadataOnlySourceSafetyXCTests.swift; committed).
- Latest production change is the destination job-path block (6c35cad), consistent with preflight code seen in DriveService.swift.

## Documentation and Code Conflicts

- CONFLICT (stale baseline): COMMAND_CENTER_HANDOVER.md and Desktop handover state v1.3.4 HEAD = f0d0cbf; actual HEAD is 6c35cad. Handover describes the release snapshot, not current tip.
- CONFLICT (stale tree listings): docs/00_AI_AGENT_START_HERE.md and docs/02 list only Tests/ root test files and omit v1.3.x files: NotificationCoordinator, TelegramNotificationService, AppUpdateService, TechnicalLogsUpdateViewModel, NotificationTabView, and models AppUpdateState/GitHubRelease/NotificationSettings/SemanticVersion/LogVisibilityFilter. The actual compiled test files live in Tests/XCTest/.
- CONFLICT (rsync flags): docs (02 section 6) require `--info=progress2`; code uses `--info=name1,progress2 --outbuf=N` (superset; enables current-file names and avoids line-buffering stalls). No destructive flags added; exclusions come from TransferFileExclusionPolicy (.DS_Store, ._*, .Spotlight-V100, .Trashes, .fseventsd, .TemporaryItems).
- CONFLICT (bookmarks): PRD FR-003 and docs require persistent security-scoped bookmarks restored after relaunch, with access started before filesystem operations. `BookmarkService` is in-memory only and no Swift source calls `startAccessingSecurityScopedResource`/`stopAccessingSecurityScopedResource`. Persistence/restore-after-relaunch is not implemented in code.
- CONFLICT (operator wording on rsync exit codes): docs/02 section 6 says never expose raw exit codes alone ("Bad: rsync exit 23"); `TransferError.rsyncExit(Int32)` yields "Transfer process exited with error code N." (TransferEvent.swift) — the documented "Bad" form, wrapped as "TRANSFER ERROR: ...". Not SAFE TO EJECT-relevant, but a spec-vs-code drift.

## Suspected Risk Areas

Ranked by safety priority (for the later bug-repair session):

1. VerifyEngine `.none` defensive hole: if `startVerification` is ever invoked with mode `.none` (future refactor/wiring), it emits `.completed(.passed)` and the coordinator would authorize `.safeToFormat`. Guarded only by the coordinator fast-exit (TransferCoordinator.swift:229). Engine should itself refuse to pass for `.none`.
2. Rsync raw exit-code operator wording for codes 11 (I/O error) and 23 (partial transfer): currently generic "Transfer process exited with error code 11/23." (TransferEvent.swift rsyncExit) — violates docs/02 operator-messaging rule; not safety-authorizing (fails closed) but is an operator-truth gap.
3. `withCheckedContinuation` hang risk in `executeRsync`/`executeVerify` (TransferCoordinator.swift:332/484): if the event stream ever ends without a terminal event, the workflow stays in `.copying`/`.verifying` forever with no report. Currently every `RsyncEngine`/`VerifyEngine` path emits a terminal event (verified), so this is latent only.
4. Cancellation during `.validating` is ignored by `cancelTransfer` (guard limits to copying/verifying); UI also disables Stop during validating. Matches docs, but operator pressing Stop during a long scan gets no feedback.
5. Source-size accounting uses `totalFileAllocatedSize` (DriveService.scanFolder) while VerifyEngine compares logical `fileSize`; free-space checks use allocated size (conservative, safe direction; report "Total Size" is allocated size).
6. Destination observer progress is clamped to <= 99% (TransferViewModel.swift:238-239) and 100% only after copyComplete/safeToFormat state — safe, no fake completion.
7. `RsyncCommand` uses `preconditionFailure` if executableURL nil (RsyncEngine.swift:757) — unreachable today because the engine checks availability first; would crash if that ordering ever changes.

## First Recommended Repair Investigation

Target: `VerifyEngine.startVerification` (VerifyEngine.swift:99-111) and
`sampleFiles(inventory:mode:)` (VerifyEngine.swift:183-204).

Rationale: category "false SAFE TO EJECT / hidden verification failure". The
only code path found that lets `VerifyEngine` authorize a passed result for a
mode that must never produce SAFE TO EJECT is the `.none` branch, which emits
`.completed(.passed)`. It is currently unreachable only because
`TransferCoordinator.runWorkflow` fast-exits (TransferCoordinator.swift:229);
defense in depth requires the engine to fail (or explicitly no-op) for `.none`
so the SAFE TO EJECT gate cannot be opened by any future caller. Secondary
follow-ups: rsync exit-code wording (TransferEvent.swift `rsyncExit`) and the
`executeRsync`/`executeVerify` no-terminal-event hang guard.

Do not repair during setup; this file only records the target for the bug
instruction.

## Commands to Revalidate Before Editing

```bash
git diff --check
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' build
xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS' -derivedDataPath /tmp/FST-Claude-DerivedData
bash scripts/package-local-arm64.sh   # release packaging only; not for debug work
```

`xcodebuild` must be run from `/Users/cenvu/DEV/FST_V2/FishSockTransfer` (the
xcodeproj is not at the repo root).

## Files That Must Not Be Overwritten

- FST_AI/memory/CODEX_SESSION_CONTEXT.md (preserve concurrent Codex context; currently absent)
- FST_AI/memory/COMMAND_CENTER_HANDOVER.md, TASK_REGISTRY.md, WORK_HISTORY.md (append/propose updates per AGENTS.md rules; do not rewrite silently)
- AGENTS.md, docs/00-03 (authority docs — update only via the documented workflow)
- FishSockTransfer/FishSockTransfer/** (production Swift, entitlements, resources, bundled rsync) — no modifications during setup
- dist/** (release artifacts), scripts/package-local-arm64.sh
