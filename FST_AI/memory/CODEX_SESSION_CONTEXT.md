# Codex Session Context

## Generated Snapshot

- CONFIRMED generation date: 2026-08-01 11:12:30 +0700 (Asia/Ho_Chi_Minh).
- CONFIRMED repository root: `/Users/cenvu/DEV/FST_V2` from `git rev-parse --show-toplevel`.
- CONFIRMED branch: `main`.
- CONFIRMED HEAD: `6c35cad12a20e664bbcaf972bf03f52589792dd0` (`fix: block existing destination job paths before transfer`).
- CONFIRMED nearest tag: `v1.3.4-b20260706`; HEAD is 5 commits ahead (`v1.3.4-b20260706-5-g6c35cad`). No tag points at HEAD.
- CONFIRMED initial worktree status: clean; staged 0, unstaged 0, untracked 0.
- CONFIRMED concurrent work observed during this audit: untracked `CLAUDE.md` and `FST_AI/memory/CLAUDE_SESSION_CONTEXT.md`. Codex did not create, edit, delete, or stage either file.
- CONFIRMED Codex CLI: `codex-cli 0.145.0`.
- CONFIRMED Codex project instruction mechanism: root `AGENTS.md` was present in `codex debug prompt-input` model-visible context. `codex exec --help` also documents project exec-policy `.rules` loading through `--ignore-rules`; CLI help documents global `~/.codex/config.toml`, not a verified project-local config schema. No Codex config or rules file was created.
- CONFIRMED `.codegraph/` is absent; CodeGraph was not used or installed.

## Authority Files Read

| Path | Status | Conflict/result |
|---|---|---|
| `AGENTS.md` | CONFIRMED present/read | Highest authority. |
| `FST_AI/memory/COMMAND_CENTER_HANDOVER.md` | CONFIRMED present/read | CONFLICT: records baseline HEAD `f0d0cbf`; actual HEAD is `6c35cad` (5 commits after tagged baseline). |
| `docs/00_AI_AGENT_START_HERE.md` | CONFIRMED present/read | Source tree inventory omits current notification/update-check files. |
| `FST_AI/memory/TASK_REGISTRY.md` | CONFIRMED present/read | Latest registered implementation is destination existing-job-path hardening; this Codex setup/audit task was not already registered. |
| `FST_AI/memory/WORK_HISTORY.md` | CONFIRMED present/read | Historical entries describe pre-commit states; actual repository contains those later commits. |
| `docs/01_PRD.md` | CONFIRMED present/read | Mission and safety invariant agree with `AGENTS.md`. |
| `docs/02_FST_TECHNICAL_GUIDE.md` | CONFIRMED present/read | Architecture and source tree differ from current code as recorded below. |
| `docs/03_PROJECT_MASTER_GUIDELINE.md` | CONFIRMED present/read | Mission and safety invariant agree with `AGENTS.md`. |
| `CHANGELOG.md` | CONFIRMED present/read | Latest documented release is v1.3.4. |
| `README.md` | CONFIRMED present/read | User-facing baseline is v1.3.4, macOS 13.5+, arm64. |
| `$HOME/Desktop/FST_AI_PROJECT_HANDOVER.md` | CONFIRMED present/read | CONFLICT: says clean HEAD matches tag; actual HEAD is 5 commits ahead and concurrent untracked Claude files now exist. Orientation only. |

Additional required FST_AI files read: `FST_AI/README.md`, `FST_AI/memory/current-priority.md`, `FST_AI/memory/agent-roles.md`, `FST_AI/standards/safety-first.md`, `FST_AI/standards/agent-boundaries.md`, `FST_AI/standards/minimal-safe-change.md`, `FST_AI/roles/codex-core-engineer.md`, and `FST_AI/roles/claude-primary-reviewer.md`.

## Product Mission

- CONFIRMED FST is a native macOS DIT/Data Wrangler copy/verify/report application for one source, one destination, and one active job.
- CONFIRMED required operational flow: `SOURCE -> COPY -> VERIFY -> SAFE TO EJECT / OPERATOR HANDOFF`.
- CONFIRMED FST does not format, erase, reuse, or eject source media.
- CONFIRMED priority: data safety, reliability, truthful operator feedback, repeatability, maintainability, performance, then convenience.

## Non-Negotiable Safety Invariants

- CONFIRMED source media must remain read-only. No delete, rename, move, chmod, chown, metadata write, cleanup, format, or destructive rsync operation is permitted.
- CONFIRMED `SAFE TO EJECT = authoritative copy success AND authoritative verification success`.
- CONFIRMED verification mode `none` may only finish at `copyComplete` / `TRANSFER COMPLETE`.
- CONFIRMED production transfer must use app-bundled rsync 3.4.4; no system/Homebrew/MacPorts fallback.
- CONFIRMED destination observer metrics, UI progress, speed, ETA, Telegram delivery, and update-check results are visibility only and must not authorize success.
- CONFIRMED failed, cancelled, incomplete, or uncertain work must never produce `safeToFormat` or operator-facing `SAFE TO EJECT`.

## Verified Architecture

- CONFIRMED primary UI flow: SwiftUI views call `TransferViewModel`; `TransferViewModel.startTransfer()` calls `TransferCoordinator.startTransfer(...)`; the coordinator invokes `RsyncEngine`, `VerifyEngine`, `ReportEngine`, `DriveService`, `LoggerService`, and `BundledRsyncService`.
- CONFIRMED `RsyncEngine` uses `BundledRsyncService`; `VerifyEngine` and `ReportEngine` are actor-isolated engines; source/destination validation is in `DriveService`.
- CONFIRMED no SwiftUI import exists in the inspected engines.
- CONFLICT the documented strict chain `View -> ViewModel -> Coordinator -> Engines -> Services` is not literal in current code: `TransferViewModel` directly owns/calls `DriveService` and `BundledRsyncService`, and `TechnicalLogsUpdateViewModel` directly owns/calls `AppUpdateService`. `TransferViewModel` also owns `NotificationCoordinator`.
- CONFIRMED `BookmarkService` exists but has no production call site found by repository search; persisted bookmark restore/start/stop security scope is therefore UNVERIFIED as a runtime feature.

## Actual Runtime Flow

1. CONFIRMED `TransferControlsView.handleActionButton()` calls `TransferViewModel.startTransfer()` when the UI mirror state is terminal/ready and `canStartTransfer` is true.
2. CONFIRMED `TransferViewModel.startTransfer()` checks bundled rsync availability, source/destination selection, destination capacity metadata, and bandwidth input, then asynchronously calls `TransferCoordinator.startTransfer(...)`.
3. CONFIRMED `TransferCoordinator.startTransfer(...)` accepts ready/terminal states and starts detached `runWorkflow(...)` work.
4. CONFIRMED `runWorkflow(...)` changes coordinator state to `validating`, uses `DriveService` and `TransferPreflightValidator`, then changes state to `copying` and calls `executeRsync(...)`.
5. CONFIRMED `executeRsync(...)` consumes only `RsyncEngine` terminal events for copy truth. `DestinationActivityObserver` snapshots are forwarded only through `onCopyRuntimeSnapshot`.
6. CONFIRMED rsync failure/cancel produces `.error`/`.cancelled`. Status 0 produces `.completed`; only then can workflow continue.
7. CONFIRMED mode `none` immediately changes to `.copyComplete`, logs `TRANSFER COMPLETE. Verification disabled.`, writes a copy-only report, and returns.
8. CONFIRMED `random33`/`full` change to `.verifying`, verify `<destination>/<source.lastPathComponent>`, and consume `VerifyEngine` events.
9. CONFIRMED only a completed `VerificationResult` whose status is `.passed` is treated as verify success. Failure/cancel blocks verified success.
10. CONFIRMED verified success changes coordinator state to legacy `.safeToFormat`, logs `Verification Passed. SAFE TO EJECT.`, then writes the terminal report.

## TransferState Mutation Map

- CONFIRMED authoritative workflow state storage: `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`, property `state`.
- CONFIRMED authoritative mutation method: `TransferCoordinator.updateState(_:)`; direct assignment to coordinator `state` occurs only there.
- CONFIRMED transitions in `TransferCoordinator.runWorkflow(...)`: `.validating`, `.error`, `.cancelled`, `.copying`, `.copyComplete`, `.verifying`, and `.safeToFormat`.
- CONFIRMED the only production `.safeToFormat` transition is the verified-success tail of `runWorkflow(...)`.
- CONFLICT `FishSockTransfer/FishSockTransfer/ViewModels/TransferViewModel.swift` exposes `@Published public var transferState` with a public setter and mutates this UI mirror in internal `applyTransferState(_:)`. Current production call site is the coordinator callback, but the type-level API does not enforce the written “only TransferCoordinator may change TransferState” rule.
- CONFIRMED `TechnicalLogsUpdateViewModel.state` is `AppUpdateState`, not `TransferState`, and cannot authorize transfer safety.

## SAFE TO EJECT Proof

- CONFIRMED copy proof: `RsyncEngine.startTransfer(...)` emits `.completed` only when the launched bundled process terminates with status 0. `ProgressParser` clamps active progress to 99%; 100% is emitted only on status 0.
- CONFIRMED verify proof: `TransferCoordinator.executeVerify(...)` returns success only for `.completed(result)` with `result.status == .passed`.
- CONFIRMED gate: `TransferCoordinator.runWorkflow(...)` reaches `.safeToFormat` only after rsync success, non-`none` mode, no cancellation flag, and verify success.
- CONFIRMED copy-only proof: the `mode == .none` branch occurs before `.verifying` and returns after `.copyComplete`.
- CONFIRMED report defense: `ReportEngine.finalStatusDescription(for:)` renders `SAFE TO EJECT DESTINATION` only when final state is `.safeToFormat`, mode is not `.none`, and verification result is `.passed`; invalid facts render `MANUAL CHECK REQUIRED`.
- CONFIRMED observer isolation: `DestinationActivityObserver` has no callback that returns a copy-success value; it only supplies `CopyRuntimeSnapshot` and diagnostics.
- CONCERN `TransferCoordinator.startTransfer(...)` does not reserve the job by changing state before it creates detached `runWorkflow(...)`. A rapid second start can be accepted while actor state is still `.ready`, potentially creating two workflows. This is not covered by the canonical target and is the first recommended repair investigation below.

## Bundled Rsync Resolution

- CONFIRMED resolver: `BundledRsyncService.init()` uses only `Bundle.main.url(forResource: "rsync", withExtension: nil)`.
- CONFIRMED validation: file existence, executable permission, canonical `rsync version <x.y.z> protocol version <n>` parsing, and exact equality to `3.4.4`.
- CONFIRMED failure behavior: unavailable/missing/non-executable/unrecognized/wrong-version cases return no executable URL; `RsyncEngine` emits `.failed(.rsyncNotFound)`.
- CONFIRMED no `/usr/bin/rsync`, Homebrew, or MacPorts fallback path was found in production source or project settings.
- CONFIRMED `RsyncCommand` uses the validated URL and arguments `-a`, `-h`, `--info=name1,progress2`, `--outbuf=N`, optional converted `--bwlimit`, exclusion arguments, source path, and destination path.
- CONFIRMED no destructive rsync option (`--delete`, `--remove-source-files`, or `--inplace`) was found in constructed arguments.
- CONFIRMED Xcode filesystem-synchronized app target copies `FishSockTransfer/FishSockTransfer/rsync` into app resources. Built resource is executable arm64 Mach-O and prints `rsync version 3.4.4 protocol version 32`.
- CONFIRMED required dylibs are copied by build phase `Copy Bundled Rsync Dylibs`; no Swift package dependencies are configured.

## Verification Modes and Algorithms

- CONFIRMED `VerificationMode.none`: no hash algorithm; coordinator bypasses `VerifyEngine` and ends copy-only.
- CONFIRMED `VerificationMode.random33`: SHA256, `ceil(fileCount * 0.33)` with minimum one eligible file, weighted random selection favoring larger files.
- CONFIRMED `VerificationMode.full`: all eligible files, xxHash64.
- CONFIRMED `VerifyEngine.startVerification(...)` builds exclusion-aware source/destination inventories, compares file count, relative paths, and sizes before hashing, hashes in 4 MiB chunks, and fails on the first proven mismatch.
- CONFIRMED cancellation is checked during inventories, before each hash, and during chunked hashing.
- UNVERIFIED runtime source-identity stability across the whole job; generated reports explicitly state source change detection is not available in V1.

## Reports, Logs, Notifications, and Update Check

- CONFIRMED `TransferCoordinator.saveTerminalReport(...)` writes only to a destination-side folder accepted by `TransferPreflightValidator.safeReportFolder(...)`; inspected safety tests cover not writing into source or an existing destination job directory on preflight failure.
- CONFIRMED `ReportEngine` maps copy-only to `TRANSFER COMPLETE`, verified pass to `SAFE TO EJECT DESTINATION`, verify failure to `MANUAL CHECK REQUIRED`, copy/preflight failure to `TRANSFER ERROR`, and cancellation to `CANCELLED`.
- CONFIRMED full ViewModel logs can be included in the report; operator-visible filtering does not mutate the stored full logs.
- CONFIRMED `NotificationCoordinator`/`TelegramNotificationService` catch delivery failures into notification status. They have no `TransferCoordinator` dependency and no state mutation path.
- CONFIRMED Telegram token storage uses Keychain. No token, chat ID, authenticated URL, or Keychain value was read or recorded in this snapshot.
- CONFIRMED `AppUpdateService.checkForUpdates()` performs a user-triggered GitHub latest-release read and returns `AppUpdateState`; it has no transfer state, download, install, or app-bundle mutation path.
- CONFIRMED source entitlements enable app sandbox, user-selected read/write file access, and outbound network client. Test builds inject additional test-only entitlements; do not treat those as release entitlements.

## Current Xcode Configuration

- CONFIRMED Xcode: 26.3 (build 17C529); installed compiler: Apple Swift 6.2.4.
- CONFIRMED project: `FishSockTransfer/FishSockTransfer.xcodeproj`; no separate user-authored `.xcworkspace` was found (the project contains its generated internal workspace).
- CONFIRMED targets: application `FishSockTransfer`; unit test bundle `FishSockTransferTests`.
- CONFIRMED shared scheme: `FishSockTransfer`; it builds both targets and tests `FishSockTransferTests`.
- CONFIRMED available destination: local `My Mac`, macOS, arm64. Command destination used: `platform=macOS,arch=arm64`.
- CONFIRMED effective app target deployment target: macOS 13.5. Project-level setting is 15.7, but app/test targets override it to 13.5.
- CONFIRMED effective Debug architecture for this destination: arm64; `ARCHS_STANDARD` is `arm64 x86_64`, `ONLY_ACTIVE_ARCH=YES` in Debug. Current bundled rsync is arm64 only.
- CONFIRMED `SWIFT_VERSION=5.0` language mode with Swift 6.2.4 compiler, `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`, and approachable concurrency enabled.
- CONFIRMED version metadata: `MARKETING_VERSION=1.3.4`, `CURRENT_PROJECT_VERSION=20260706`.
- CONFIRMED sandbox: enabled; user-selected files read/write; outgoing network enabled; incoming network disabled; hardened runtime disabled; automatic/ad-hoc local signing resolved to identity `-` in this Debug run.
- CONFIRMED package dependencies: none.

## Current Test Inventory

- CONFIRMED canonical Xcode target contains 11 XCTest source files under `FishSockTransfer/Tests/XCTest/`: `AppUpdateServiceXCTests.swift`, `BundledRsyncServiceXCTests.swift`, `LogVisibilityFilterXCTests.swift`, `MetadataOnlySourceSafetyXCTests.swift`, `NotificationCoordinatorXCTests.swift`, `ProgressParserXCTests.swift`, `ReportEngineXCTests.swift`, `RsyncBandwidthLimitXCTests.swift`, `SemanticVersionXCTests.swift`, `TransferViewModelRuntimeXCTests.swift`, and `VerificationHashStrategyXCTests.swift`.
- CONFIRMED canonical test result: 169 passed, 0 failed, 0 skipped, 0 expected failures on local arm64 macOS 15.7.7.
- CONFIRMED `FishSockTransfer/Tests/*.swift` outside `XCTest/` and root `Tests/UnitTests/**/*.swift` are not members of `FishSockTransferTests`; their additional tests were not run by the canonical command.
- CONCERN root `Tests/UnitTests/Coordinators/TransferCoordinatorTests.swift` contains coordinator success-flow assertions but is not in the canonical test target. Canonical tests cover coordinator preflight failures but not repeated-start/single-active-job admission.

Verification commands and results:

- CONFIRMED `xcodebuild -list -project FishSockTransfer/FishSockTransfer.xcodeproj` -> exit 0; targets/scheme listed. Sandbox emitted non-fatal CoreSimulator/cache warnings.
- CONFIRMED `xcodebuild -showBuildSettings -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FST-Codex-DerivedData` -> exit 0.
- BLOCKED first sandboxed canonical test attempt -> exit 65 because nested `sandbox-exec` could not run build phase `Copy Bundled Rsync Dylibs`; no code/test failure was reached.
- CONFIRMED approved out-of-sandbox canonical test and incremental revalidation: `xcodebuild test -quiet -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FST-Codex-DerivedData` -> exit 0.
- CONFIRMED `xcrun xcresulttool get test-results summary --path <latest xcresult>` -> exit 0; result Passed, 169/169.

## Current Git Work

- CONFIRMED starting snapshot was clean at HEAD `6c35cad`.
- CONFIRMED Codex intentionally creates only `FST_AI/memory/CODEX_SESSION_CONTEXT.md` in this task.
- CONFIRMED concurrent untracked files appeared during the audit: `CLAUDE.md` and `FST_AI/memory/CLAUDE_SESSION_CONTEXT.md`. They belong to another agent/session and must be preserved.
- CONFIRMED no staged or tracked unstaged production changes were present at snapshot time.
- CONFIRMED no fetch, pull, push, checkout, switch, reset, clean, stash, merge, rebase, commit, or tag command was run.

## Documentation and Code Conflicts

- CONFLICT current handover/Desktop HEAD facts are stale (`f0d0cbf`/tag) versus actual `6c35cad` five commits later.
- CONFLICT documented source trees omit notification, update-check, and newer model/view files present in production.
- CONFLICT strict documented dependency chain is bypassed by ViewModel-to-Service dependencies described under Verified Architecture.
- CONFLICT “only TransferCoordinator may change TransferState” is true for authoritative coordinator state but not type-enforced for public mutable `TransferViewModel.transferState` UI mirror.
- CONFLICT docs say Swift 5.9+ while Xcode project explicitly uses Swift language mode 5.0; compiler itself is Swift 6.2.4.
- CONFLICT technical guide lists minimum dedicated `TransferCoordinatorTests`, `VerifyEngineTests`, and other suites, but several root test files are not members of the canonical Xcode test target.
- CONFLICT docs show required rsync flag `--info=progress2`; actual command intentionally uses the superset `--info=name1,progress2` plus `--outbuf=N` for file-name/progress streaming.

## Suspected Risk Areas

- CONCERN repeated-start admission race in `TransferCoordinator.startTransfer(...)`: state remains ready until detached `runWorkflow(...)` executes `updateState(.validating)`.
- CONCERN public mutability of `TransferViewModel.transferState` weakens compile-time state ownership even though current production call paths use coordinator callbacks.
- CONCERN canonical Xcode tests do not execute the separate root coordinator success tests or directly test double-start rejection.
- CONCERN source-change detection is unavailable in V1; inventory/size/hash evidence may become uncertain if source contents change during a job.
- CONCERN `BookmarkService` is in-memory and unused by production call sites found; persistent security-scoped access behavior is UNVERIFIED.
- INFERRED random33 sampling is deliberately nondeterministic, which complicates exact reproduction of a particular sampled set unless logs are retained.
- UNVERIFIED real-device runtime failure/cancel/disconnect QA and second-Mac packaged-app QA remain outstanding per task registry/work history.

## First Recommended Repair Investigation

- CONCERN priority classification: possible concurrent-copy/false-terminal-state risk before lower-priority operator polish.
- Inspect `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`: `startTransfer(...)`, `runWorkflow(...)`, `updateState(_:)`, and `workflowTask` ownership.
- Inspect `FishSockTransfer/FishSockTransfer/ViewModels/TransferViewModel.swift`: `startTransfer()` and `canStartTransfer`.
- Inspect `FishSockTransfer/FishSockTransfer/Views/TransferControlsView.swift`: `handleActionButton()` and `isActionButtonEnabled`.
- Add no fix yet. First prove or disprove that two immediate `startTransfer` calls can both enter validation/copy, then design a targeted canonical XCTest for single-active-job admission and cancellation ownership.

## Commands to Revalidate Before Editing

```bash
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
git describe --tags --always --dirty
git status --short
codex --version
xcodebuild -list -project FishSockTransfer/FishSockTransfer.xcodeproj
xcodebuild -showBuildSettings -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FST-Codex-DerivedData
xcodebuild test -quiet -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/FST-Codex-DerivedData
git diff --check
git status --short
```

## Files That Must Not Be Overwritten

- `AGENTS.md` and all existing authority/project documentation unless a later explicit docs task authorizes changes.
- `CLAUDE.md` and `FST_AI/memory/CLAUDE_SESSION_CONTEXT.md` (concurrent other-agent work).
- Production Swift, tests, Xcode project/settings, scheme, entitlements, assets/resources, bundled rsync/dylibs, release artifacts, and package scripts during this setup-only task.
- Any staged, unstaged, or untracked user/agent work discovered in a later pre-edit snapshot.
