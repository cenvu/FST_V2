# FST Task Registry

## Purpose

Track meaningful AI/Codex task batches so future agents can detect repeated prompts.

## Rule

Before running a new task, Codex must check this registry and `FST_AI/memory/WORK_HISTORY.md`.

If the same or substantially similar task already exists, Codex must stop and ask:

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
