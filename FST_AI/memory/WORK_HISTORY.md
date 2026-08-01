# FST Work History

## Purpose

Append-only compact project work history. This is for future handoff, not detailed logs.

## Update Rule

After every meaningful Codex/AI batch, append a new entry at the top under "Recent History".

Each entry must include:
- Date/time if available
- Agent/model if known
- Branch/commit/tag if relevant
- Files changed
- What changed
- Safety boundary confirmation
- Build/test/package result
- Whether committed/tagged/released
- Next recommended action

## Recent History

### 2026-08-02 - v1.3.5 Release Sprint

- Agent/model: Antigravity IDE / Gemini 3.6 Flash
- Branch/commit/tag: main; tag v1.3.5 (pending)
- Files changed: multiple markdown documentation files and pbxproj versions
- What changed: Prepared all versioning metadata, documentation, handovers, project guidelines, PRD, and changelogs for the FST v1.3.5 release.
- Safety boundary confirmation: Version metadata and documentation update only. No changes to core Swift engines or runtime logic.
- Build/test/package result: Tests pending before package/tag execution.
- Whether committed/tagged/released: Will be committed as "release: v1.3.5", tagged, and published as a GitHub release.
- Next recommended action: Run tests, build package, commit, tag, and publish GitHub Release.

### 2026-08-01 - Consolidated pre-commit review Sprint (READY_TO_COMMIT)

- Agent/model: Antigravity IDE / Gemini 3.6 Flash
- Branch/commit/tag: main at 6c35cad; uncommitted worktree
- Files changed: `/tmp/FST_CONSOLIDATED_PRECOMMIT_REVIEW.md` (scratch report), `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, and one new VERIFICATION handoff
- What changed: Complete read-only review of all 9 modified files and 24 untracked paths in the repository. Validated internal consistency, safety invariants, secret scan, script syntax, JSON configs, and Handoff System. Formulated a 4-group atomic commit plan.
- Safety boundary confirmation: Review only — zero production Swift, test, Xcode, entitlement, or rsync changes made. All safety invariants preserved.
- Build/test/package result: Tooling validation PASS (`.mcp.json`, `.agents/mcp_config.json`, `fst-codegraph-mcp.sh`); Handoff publisher `--verify` PASS; Secret scan CLEAR.
- Whether committed/tagged/released: Not committed, not tagged, not released
- Next recommended action: Execute the approved commit plan one group at a time, stopping after each group for verification and without pushing.

### 2026-08-01 - Cancellation and engine-ownership investigation (NO_CROSS_GENERATION_RISK)

- Agent/model: Claude Code / deepseek-v4-flash
- Branch/commit/tag: main at 6c35cad; not committed
- Files changed: `/tmp/FST_CANCELLATION_ENGINE_OWNERSHIP_INVESTIGATION.md` (scratch report, not committed), `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, and one new VERIFICATION handoff through the publisher
- What changed: read-only investigation of shared `TransferCoordinator.isCancelled` and RsyncEngine/VerifyEngine active-operation references after the workflowTask ownership fix. Direct source trace proved NO_CROSS_GENERATION_RISK: (1) `startTransfer` resets `isCancelled` in the same synchronous actor section as the `.validating` admission reservation, before `Task.detached` creation, and Job-2 admission requires `workflowTask == nil` (cleared only by `workflowDidFinish` after `runWorkflow` returns) — so Job-1's reads at lines 179/203/277 always complete before any reset, and a new workflow cannot inherit `true`; (2) RsyncEngine awaits both pipe drainers before terminal emission and runs `cleanup()` (process = nil, pipes closed) before `startTransfer` returns, and engine-actor FIFO guarantees Job-2 engine calls execute only after Job-1's full startTransfer (incl. cleanup) returns — no stale overwrite, no cross-job cancel targeting, no drainer/termination callback outliving the job; exactly one terminal event per invocation; cancel-during-natural-exit always routes to `.cancelled`; (3) VerifyEngine resets `isCancelled` at entry, has no detached tasks, and every terminal event is followed by `return`; (4) late-callback matrix: all coordinator/engine callbacks either complete before ownership clears or are dropped by AsyncStream post-finish; observer post-stop fires are checkpointed and land in Job-1's terminal tail at latest (actor FIFO), operator-truth only; Telegram tasks/heartbeat are best-effort, state-guarded, visibility-only; (5) production constructs exactly one Coordinator → one engine set (ContentView.swift:14, TransferViewModel.swift:86); engine sharing is test-injection-only.
- Safety boundary confirmation: investigation only — no production Swift, tests, Xcode project, entitlements, or rsync changed; source read-only, Coordinator state ownership, SAFE TO EJECT gate, `.none → .copyComplete`, bundled rsync-only, observer isolation, and report truthfulness invariants preserved; repeated-start and terminal-tail fixes untouched
- Build/test/package result: targeted suites PASS 86/86 (exit 0; TransferViewModelRuntimeXCTests incl. terminal-tail regression, MetadataOnlySourceSafetyXCTests incl. repeated-start regression, VerificationHashStrategyXCTests incl. .none contract, ReportEngineXCTests, ProgressParserXCTests incl. observer stop) at `/tmp/FST-Cancellation-Ownership-Investigation`; full suite NOT run per Lean Mode (86/86 consistent with current 172/172 baseline); `git diff --check` PASS; CodeGraph advisory PARTIAL/INCORRECT/BLOCKED (0.19.1 Swift parse/call-edge defects; no reindex while another client may hold the DB); direct source authoritative
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: perform one consolidated pre-commit review of all current uncommitted production, test, tooling, documentation, MCP, and handoff changes and produce a safe commit-grouping plan without committing

### 2026-08-01 - Terminal-tail cross-job overlap fixed

- Agent/model: Codex CLI / GPT-5 (codex-cli 0.145.0)
- Branch/commit/tag: main at 6c35cad; not committed
- Files changed: `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`, `FishSockTransfer/Tests/XCTest/TransferViewModelRuntimeXCTests.swift`, FST memory records, and one new NORMAL handoff
- What changed: Added deterministic `testTerminalTailBlocksSecondCoordinatorStartUntilReportCallbacksFinish`. A debug-only asynchronous tail hook pauses Job 1 inside `saveTerminalReport(...)`; an `isolated TransferCoordinator` helper sends Job 2 Start and reads state in the same actor turn. Pre-fix it observed `.validating`, proving Job 2 admission during Job 1 terminal tail. Production now requires `workflowTask == nil` in `startTransfer(...)` and calls `workflowDidFinish()` only after `runWorkflow(...)` returns, including terminal report/log callbacks.
- Safety boundary confirmation: source remains read-only; Coordinator remains the sole authoritative state/admission owner; terminal UI wording/timing, SAFE TO EJECT gate, `.none -> .copyComplete`, bundled rsync-only policy, report wording/schema, observer, Telegram, and update-check paths were not changed. No ViewModel production change.
- Build/test/package result: pre-fix regression FAIL 1/1 (`validating` vs expected `error`); post-fix regression PASS 1/1; relevant suites PASS 100/100; canonical PASS 172/172, 0 failed, 0 skipped at `/tmp/FST-TerminalTail-Fix`; `git diff --check` passed. Existing deployment-link warnings only.
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: Perform an independent review of the terminal-tail ownership fix and determine whether the remaining write-only workflowTask risk has been fully resolved.

### 2026-08-01 - Terminal state report and log overlap investigation (DEFECT_CONFIRMED)

- Agent/model: Antigravity IDE / Gemini 3.6 Flash
- Branch/commit/tag: main at 6c35cad; not committed
- Files changed: `/tmp/FST_TERMINAL_REPORT_LOG_OVERLAP_INVESTIGATION.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, and one new VERIFICATION handoff through the publisher
- What changed: Investigated whether publishing terminal `TransferState` before terminal report and log work completes creates a real cross-job overlap defect. Direct source trace confirmed `DEFECT_CONFIRMED`: In all terminal paths (`.copyComplete`, `.safeToFormat`, `.error`, `.cancelled`), `TransferCoordinator.runWorkflow` calls `updateState(...)` BEFORE calling `saveTerminalReport(...)`. Terminal state update immediately sets `canStartTransfer = true` on `TransferViewModel`, enabling a new job (Job #2) to start while Job #1 is in `saveTerminalReport(...)`. This causes two concrete defects: (1) `saveTerminalReport` invokes `onLogsSnapshot` (fetching `viewModel.logs`) after Job #2 has started logging, embedding Job #2 logs into Job #1's TXT report; (2) Job #1's post-report log `"Report saved: <path>"` triggers `onLog`, updating `viewModel.reportStatusMessage` to point to Job #1's report while Job #2 is running.
- Safety boundary confirmation: Investigation only — no production Swift or test code modified; copied media safety and read-only source invariants remain intact (`PROVEN_IMPOSSIBLE`); repeated-start admission fix and `.none` VerifyEngine doc comment/test preserved untouched.
- Build/test/package result: Targeted test suites PASS 98/98 (`/tmp/FST-TerminalTail-Investigation`, exit 0); `git diff --stat` confirms zero production or test code changes introduced by this Sprint.
- Whether committed/tagged/released: Not committed, not tagged, not released
- Next recommended action: Add one deterministic regression test reproducing the terminal-tail overlap, then apply the smallest Coordinator-owned job-admission or callback-ownership fix.

### 2026-08-01 - VerifyEngine verification-mode-none contract resolved (TEST_AND_DOCUMENT)

- Agent/model: Claude Code / deepseek-v4-flash
- Branch/commit/tag: main at 6c35cad; not committed
- Files changed: `FishSockTransfer/FishSockTransfer/Engines/VerifyEngine.swift` (one doc comment on `startVerification`), `FishSockTransfer/Tests/XCTest/VerificationHashStrategyXCTests.swift` (one focused test), `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, and one new NORMAL handoff through the publisher
- What changed: selected TEST_AND_DOCUMENT for the internal VerifyEngine `.none` contract. Direct-source trace proved production can never send `.none` to the engine (`TransferCoordinator` fast-exits at TransferCoordinator.swift:231-249 to `.copyComplete` after copy success; `executeVerify`/`startVerification` only reachable for random33/full), while a direct engine invocation emits exactly one `.completed(.passed)` with `verifiedFiles == 0` after inventory build and count/size comparison — no hashing, deterministic. That semantics was undocumented in source and untested. Cleanup: one doc comment making the copy-only-pass contract explicit, plus `testDirectNoneModeVerificationDoesNotHashAndEmitsZeroVerifiedPassed` proving exactly one terminal `.completed` event, `.passed` with zero verified/passed files, no hashing events (.currentFile/.hashGenerated/.progress), no failure/cancel. ADD_EXPLICIT_SKIPPED rejected (would require >3 production files including ReportEngine exhaustive status switches, plus report/UI behavior change; no direct caller needs a machine-readable distinction).
- Safety boundary confirmation: no runtime behavior change (comment + test only); `.none` → `.copyComplete` and SAFE TO EJECT unreachable preserved; random33 (SHA256) and full (xxHash64) unchanged; bundled rsync, report, Telegram, update-check, UI, and state machine unchanged; repeated-start fix and regression untouched
- Build/test/package result: focused contract test PASS 1/1 before and after the comment (0.005s, deterministic, no sleeps); relevant suites PASS 98/98, 0 failed, 0 skipped (`/tmp/FST-VerifyNone-Contract`, exit 0); full suite NOT run per Sprint full-suite rule (test code + source comment only, no runtime behavior change); `git diff --check` PASS; CodeGraph incremental reindex (71 files, 2 parsed) + impact analysis low risk (9 test-side impacts)
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: investigate the terminal-state-before-report/log-completion overlap without modifying production code (the remaining P1 from both the independent review and this Sprint)

### 2026-08-01 - Repeated-start admission race fixed

- Agent/model: Codex CLI / GPT-5
- Branch/commit/tag: main at 6c35cad; implementation remains uncommitted
- Files changed: `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`, `FishSockTransfer/Tests/XCTest/MetadataOnlySourceSafetyXCTests.swift`, FST memory records, and one new NORMAL handoff
- What changed: added deterministic regression `testRepeatedStartAdmitsExactlyOneWorkflow`, which calls `TransferCoordinator.startTransfer` twice without suspension inside one `isolated TransferCoordinator` region and captures state after each request. Before the fix it failed with `[ready, ready]`; the minimal production fix now sets Coordinator-owned state to `.validating` immediately after the admissible-state guard and before creating `Task.detached`, so the second request observes an active state and cannot schedule a second workflow.
- Safety boundary confirmation: Coordinator remains the authoritative admission/state owner; one Start creates at most one workflow; no ViewModel, rsync, verification, cancellation, report, notification, update-check, source-media, Xcode, entitlement, dependency, or release behavior changed
- Build/test/package result: focused regression pre-fix FAIL confirmed (1/1 failed for double admission); post-fix PASS 1/1; relevant Coordinator/ViewModel/report suites PASS 57/57; canonical full suite PASS 170/170, 0 failed, 0 skipped; existing Swift-concurrency and XCTest deployment-link warnings only
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: perform an independent review of the repeated-start fix and then investigate VerifyEngine verification-mode-none semantics.

### 2026-08-01 - Repeated-start admission race investigation (CONFIRMED_RACE)

- Agent/model: Claude Code
- Branch/commit/tag: main at 6c35cad; not committed (investigation-only, no production changes)
- Files changed: `handoffs/` (one new timestamped VERIFICATION handoff + CURRENT + INDEX), `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`; report at `/tmp/FST_REPEATED_START_INVESTIGATION.md` (local scratch, not committed)
- What changed: investigated the repeated-start admission race flagged as the prior handoff's Single Next Action. Direct source inspection of `TransferCoordinator.swift`, `TransferViewModel.swift`, `RsyncEngine.swift`, `VerifyEngine.swift`, `TransferControlsView.swift` (plus grep for every production call site and all existing test coverage) shows: (1) `TransferCoordinator.startTransfer()`'s admission guard reads `state` but never mutates it synchronously — the transition to `.validating` happens later inside `runWorkflow()`, itself only reachable via a separately-scheduled `Task.detached`, leaving a window where a second `startTransfer()` call reads the same pre-transition state and is also admitted; (2) `TransferViewModel.startTransfer()` has no `transferState`/`canStartTransfer` check at all, relying entirely on the SwiftUI button's `disabled` binding; (3) `RsyncEngine.startTransfer`/`VerifyEngine.startVerification` have no re-entry guard and unconditionally overwrite `process`/cancellation state; (4) `workflowTask` is write-only (assigned, never read); (5) `isCancelled` flags at every layer are shared per-instance, not per-job-generation, so a stale cancelled task's completion can mutate a newly-started job's state. CodeGraph call-graph queries for this boundary were mostly BLOCKED/INCORRECT (known upstream Swift parser/call-edge defect, `TransferViewModel.swift` not indexed at all); every claim in the report is backed by direct source, not graph output. No existing test covers repeated-start admission.
- Safety boundary confirmation: investigation-only — no Swift source, tests, Xcode project, entitlements, or rsync changed; `git status --short`/`git diff --check` clean for all production paths
- Build/test/package result: no build/test run required by Lean Mode (no source changed); prior 169/169 baseline unchanged
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: implement one focused regression test that demonstrates the race (coordinator double-admission, no `await` between two `startTransfer` calls), then apply the smallest admission-guard fix — synchronous state reservation in `TransferCoordinator.startTransfer()`, a generation id threaded through `runWorkflow()`, and an explicit `canStartTransfer` guard in `TransferViewModel.startTransfer()` (full plan in the published handoff and `/tmp/FST_REPEATED_START_INVESTIGATION.md`)

### 2026-08-01 - Handoff System implementation (permanent cross-agent)

- Agent/model: Claude Code
- Branch/commit/tag: main at 6c35cad; not committed
- Files changed: `handoffs/` (README.md, HANDOFF_TEMPLATE.md, INDEX.md, CURRENT_HANDOFF.md, one timestamped initial handoff), `FST_AI/tools/publish_handoff.py`, `AGENTS.md`, `CLAUDE.md`, `.agents/rules/fst-codegraph.md`, `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`
- What changed: implemented the append-only Handoff System (15-section schema, timestamped immutable handoffs, `CURRENT_HANDOFF.md`, append-only `INDEX.md`, stdlib-only publisher with flock/fsync/O_EXCL/dry-run/verify/correction support, Asia/Bangkok timestamps); routed all agents (Antigravity/Gemini, Codex/GPT, Claude Code/Claude and DeepSeek) through CURRENT_HANDOFF; documented Sprint Mode and Lean Mode; GitHub Issues remain the task queue; published the initial handoff
- Safety boundary confirmation: documentation/tooling/routing only; no Swift source, tests, Xcode project, entitlements, rsync, or package change; no safety behavior change
- Build/test/package result: publisher `py_compile` passed; 13/13 validation checks in a temp repo outside FST; initial handoff published and verified (CURRENT == timestamped via `cmp`, exactly one INDEX entry); full 169-test suite not rerun (Lean Mode — no application files changed)
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: investigate the repeated-start admission race (TransferCoordinator.startTransfer/runWorkflow, TransferViewModel.startTransfer) per the initial handoff's Single Next Action

### 2026-08-01 - CodeGraph MCP integration (official @astudioplus/codegraph-mcp 0.19.1)

- Agent/model: Claude Code
- Branch/commit/tag: main at 6c35cad; not committed (config/tooling files only)
- Files changed: `.mcp.json` (new), `.agents/mcp_config.json` (new), `.agents/rules/fst-codegraph.md` (new), `FST_AI/tools/fst-codegraph-mcp.sh` (new), `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md` (new), `FST_AI/memory/CODEGRAPH_INDEX_STATUS.md` (new), `AGENTS.md`, `CLAUDE.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`; Codex `~/.codex/config.toml` (only `fst-codegraph` server entry added; backup at `~/.codex/config.toml.bak-20260801-115141`)
- What changed: installed official CodeGraph MCP (`@astudioplus/codegraph-mcp@0.19.1`, codegraph-ai/CodeGraph) pinned to `$HOME/.local/share/fst-codegraph-mcp`; created project-scoped wrapper; registered `fst-codegraph` for Claude Code (project .mcp.json), Antigravity (workspace .agents/), Codex CLI (global config.toml); built index (71 files, 628 symbols, 12 authority docs) in `~/.codegraph/`; wrote shared operating rules and index status
- Safety boundary confirmation: no Swift source, test, Xcode project, entitlement, rsync, or package change; no safety behavior change; no credentials added; source read-only invariants unchanged
- Build/test/package result: `xcodebuild test` with `/tmp/FST-CodeGraph-DerivedData`: 169 passed / 0 failed / 0 skipped
- Whether committed/tagged/released: not committed, not tagged, not released
- Known limitation recorded: codegraph-server 0.19.1 Swift parser fails on `TransferViewModel.swift`, `RsyncEngine.swift`, `AppUpdateServiceXCTests.swift`, `NotificationCoordinatorXCTests.swift` in multi-file workspaces (upstream defect; direct source inspection required for those files); Swift call edges partial. Claude project MCP approval still pending (one-time `/mcp` action).
- Next recommended action: user approves `fst-codegraph` in Claude via `/mcp`; monitor upstream 0.19.x for the Swift parser fix and re-test those 4 files

### 2026-07-06 - Safety Policy-2 destination existing job path hardening

- Agent/model: Codex
- Branch/commit/tag: main at 045bd85; not committed
- Files changed: `FishSockTransfer/FishSockTransfer/Services/DriveService.swift`, `FishSockTransfer/Tests/XCTest/MetadataOnlySourceSafetyXCTests.swift`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`
- What changed: preflight now blocks when the intended destination job path already exists as any filesystem item; report fallback avoids writing into the existing job path; added regression coverage for absent path, existing directory/file/symlink, and coordinator no-rsync/report safety
- Safety boundary confirmation: no source mutation; no transfer/verify/hash/rsync fallback changes; no merge, overwrite, reuse, or auto-suffix behavior added
- Build/test/package result: `git diff --check` passed; targeted `MetadataOnlySourceSafetyXCTests` passed; full `xcodebuild test` passed
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: review/commit, then run runtime QA for blocked existing destination path using a real external destination

### 2026-07-06 - Runtime QA-2 failure/cancel truthfulness QA template prepared

- Agent/model: Codex
- Branch/commit/tag: main at 52e0ecf; not committed
- Files changed: `FST_AI/templates/failure-cancel-truthfulness-qa-v1.3.4.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`
- What changed: created a failure/cancel truthfulness QA checklist/evidence template for cancel during copy, cancel during verify, copy failure, verify mismatch, verification none, destination observer false confidence, optional Telegram notification truthfulness, and report/log evidence
- Safety boundary confirmation: documentation/template/memory only; no Swift source, transfer, verify, report runtime, rsync, package, tag, push, or GitHub Release changes
- Build/test/package result: not run by instruction; `git diff --check` planned
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: Cen runs failure/cancel QA with the template and returns evidence block before any release readiness claim

### 2026-07-06 - Runtime QA-1 second-Mac package QA template prepared

- Agent/model: Codex
- Branch/commit/tag: main at 2a108dc; not committed
- Files changed: `FST_AI/templates/second-mac-package-qa-v1.3.4.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`
- What changed: created a second-Mac package QA checklist/evidence template for v1.3.4 GitHub Release zip, checksum, unzip, metadata, bundled rsync, Gatekeeper, launch, permission, small transfer, report, and final-state evidence
- Safety boundary confirmation: documentation/template/memory only; no Swift source, transfer, verify, report runtime, rsync, package, tag, push, or GitHub Release changes
- Build/test/package result: not run by instruction; `git diff --check` planned
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: Cen runs second-Mac QA with the template and returns evidence block before any release readiness claim

### 2026-07-06 - Batch AI-3A minor fix patch after AI-3 review

- Agent/model: Codex
- Branch/commit/tag: main at a04ba55; not committed
- Files changed: `AGENTS.md`, `docs/00_AI_AGENT_START_HERE.md`, `FST_AI/memory/agent-roles.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/roles/release-gate.md`, remaining older `FST_AI/skills/*/SKILL.md`
- What changed: aligned AGENTS role/archive wording, normalized remaining older skills to the AI-2 contract, and clarified release gate is not an agent role
- Safety boundary confirmation: docs/skills only; no Swift source, transfer, verify, report, rsync, package, tag, push, or GitHub Release changes
- Build/test/package result: not run; docs-only change
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: run final diff review, then commit AI-2/AI-3A together if accepted

### 2026-07-06 - Batch AI-2 docs, skills, memory, harness, and archive cleanup

- Agent/model: Codex
- Branch/commit/tag: main at a04ba55; not committed
- Files changed: `AGENTS.md`, `FST_AI/README.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/agent-roles.md`, `FST_AI/memory/project-baseline.md`, `FST_AI/research/AI_AGENT_SKILL_REFERENCE_NOTES.md`, `FST_AI/roles/`, focused `FST_AI/skills/`, `docs/00_AI_AGENT_START_HERE.md`, `docs/03_PROJECT_MASTER_GUIDELINE.md`, `docs/releases/release-notes-v1.3.3.md`, deleted archive Markdown
- What changed: added task registry/repeat-task guard, normalized role docs, updated focused skills, added docs cleanup and network security skills, recorded external reference notes, removed obsolete archive Markdown
- Safety boundary confirmation: documentation/skills/memory only; no Swift source, transfer, verify, rsync, report runtime, packaging, tag, push, or GitHub Release changes
- Build/test/package result: not run; docs-only change
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: review diff, run a human sanity pass on the new role/skill docs, then commit with `docs(ai): clean up agent roles skills and memory`

### 2026-07-06 - Command Center handover memory wired

- Agent/model: Codex
- Branch/commit/tag: main at f0d0cbf; not committed
- Files changed: `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/WORK_HISTORY.md`, `AGENTS.md`, `FST_AI/README.md`, `docs/00_AI_AGENT_START_HERE.md`, `docs/03_PROJECT_MASTER_GUIDELINE.md`
- What changed: created persistent Command Center handover memory and wired required startup/history rules into agent-facing docs
- Safety boundary confirmation: documentation/workflow only; no Swift source, transfer, verify, rsync, report runtime, packaging, tag, or release changes
- Build/test/package result: not run; docs-only change
- Whether committed/tagged/released: not committed, not tagged, not released
- Next recommended action: review and commit documentation handover changes, then continue second-Mac package QA and failure/cancel QA

### 2026-07-06 - v1.3.4 baseline established

- Release: v1.3.4-b20260706
- Commit: f0d0cbf
- Theme: Detailed TXT Report V1 hardening
- GitHub Release: zip + checksum uploaded
- Package: local ad-hoc arm64 macOS 13.5+
- Safety: no transfer/verify/hash/rsync/Telegram/update-check logic change
- Next: second-Mac package QA, failure/cancel QA, destination existing-folder policy, report evidence review, release automation
