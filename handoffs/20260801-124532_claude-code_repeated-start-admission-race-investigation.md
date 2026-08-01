# FST Agent Handoff

## 1. Handoff Identity

- Handoff ID: 20260801-124532_claude-code_repeated-start-admission-race-investigation
- Created At: 2026-08-01T12:45:32+07:00
- Handoff Type: VERIFICATION
- Corrects Handoff: NONE
- Previous Handoff: 20260801-123020_claude-code_implement-permanent-append-only-cross-agent-hand.md

## 2. Task and Phase

- Task: Investigate and classify the repeated-start admission race (TransferCoordinator.startTransfer/runWorkflow, TransferViewModel.startTransfer)
- Phase: Investigation only — no fix applied
- GitHub Issue: NONE (no repository issues exist; `gh issue list --state all` returns empty)
- Sprint Mode: YES
- Lean Mode: YES
- Task Status: COMPLETE

## 3. Agent and Model

- Agent Host: Claude Code
- Provider: Anthropic (harness)
- Model: Claude Sonnet 5 (claude-sonnet-5)
- CLI or IDE Version: Claude Code 2.1.220
- Execution Mode: interactive harness

## 4. Repository Snapshot

- Repository: /Users/cenvu/DEV/FST_V2
- Branch: main
- Starting Commit: 6c35cad12a20e664bbcaf972bf03f52589792dd0
- Ending Commit: 6c35cad12a20e664bbcaf972bf03f52589792dd0 (no commit created; no production change)
- Working Tree Before: modified AGENTS.md + FST_AI/memory files (CodeGraph/Handoff integration, pre-existing from prior session) + untracked .agents/, .mcp.json, CLAUDE.md, FST_AI/memory/CLAUDE_SESSION_CONTEXT.md, FST_AI/memory/CODEGRAPH_INDEX_STATUS.md, FST_AI/memory/CODEGRAPH_OPERATING_RULES.md, FST_AI/memory/CODEX_SESSION_CONTEXT.md, FST_AI/tools/, handoffs/
- Working Tree After: same tracked/untracked set, plus updated FST_AI/memory/TASK_REGISTRY.md and FST_AI/memory/WORK_HISTORY.md (append-only investigation entries) and this new handoff; no production Swift/Xcode file touched at any point (`git diff --stat -- FishSockTransfer/` empty throughout)
- Related PR: NONE
- Related Commit: NONE

## 5. Starting Context

- Authority files read: AGENTS.md, handoffs/CURRENT_HANDOFF.md, FST_AI/memory/COMMAND_CENTER_HANDOVER.md, docs/00_AI_AGENT_START_HERE.md, FST_AI/memory/TASK_REGISTRY.md, FST_AI/memory/WORK_HISTORY.md, docs/01_PRD.md, docs/02_FST_TECHNICAL_GUIDE.md, docs/03_PROJECT_MASTER_GUIDELINE.md, CLAUDE.md, FST_AI/memory/CODEGRAPH_OPERATING_RULES.md, FST_AI/memory/CODEGRAPH_INDEX_STATUS.md, FST_AI/memory/CLAUDE_SESSION_CONTEXT.md
- Previous handoff read: 20260801-123020_claude-code_implement-permanent-append-only-cross-agent-hand (its Single Next Action was exactly this investigation)
- Task request: prove or disprove a suspected repeated-start admission race involving TransferCoordinator.startTransfer(), TransferCoordinator.runWorkflow(), TransferViewModel.startTransfer(), investigation-only, no fix during this Sprint
- Known blockers: none at start
- Relevant task history: TASK_REGISTRY "2026-08-01 - Handoff System implementation" recorded this exact investigation as the next recommended action; no prior task registry entry investigated this race before now
- Relevant GitHub Issue: NONE (`gh issue list --state all --limit 5` → `[]`; `gh repo view` confirms `cenvu/FST_V2` resolves correctly, so the empty result is authoritative, not an auth/config failure)

## 6. Work Completed

- CONFIRMED Revalidated repository state: branch main, HEAD 6c35cad, worktree not clean (matches expected orientation state; all modifications pre-existing from the prior Handoff/CodeGraph integration session, not created by this investigation).
- CONFIRMED Read `TransferCoordinator.swift` in full (713 lines). `public actor TransferCoordinator` (line 5). `startTransfer(source:destination:bandwidthLimit:mode:)` (lines 81-92) is non-async; its guard reads `state` (line 83) but the function body never mutates `state` — the transition to `.validating` happens only inside `runWorkflow()` (line 124), reachable only via a separately-scheduled `Task.detached` (line 89). `workflowTask` (declared line 31, assigned line 89) is grep-confirmed write-only: never read anywhere else in the file, not consulted by `cancelTransfer()` (lines 94-113), not used as an admission gate.
- CONFIRMED Read `TransferViewModel.swift` startTransfer/cancelTransfer/canStartTransfer regions. `@MainActor final class TransferViewModel` (lines 17-18). `startTransfer()` (lines 261-312) is non-async and contains zero check of `transferState` or `canStartTransfer` — it validates only rsync availability, source/destination presence, destination space, and bandwidth, then spawns a fire-and-forget `Task { ... }` (lines 303-311) that eventually calls `await coordinator.startTransfer(...)` (line 305). `canStartTransfer` (lines 744-757) correctly reflects `transferState` but is only consulted by the View's button-disabled binding, never inside `startTransfer()` itself.
- CONFIRMED Read `RsyncEngine.swift` startTransfer/cancel (lines 1-135+). `public actor RsyncEngine` (line 5) with a single `process: Process?` (line 6). `startTransfer(request:onEvent:)` (lines 19-127) has zero guard against re-entry: `isCancelled = false` (line 20) and `self.process = rsyncProcess` (line 52) are unconditionally overwritten on every call. `isRunning()` (line 412) exists but is grep-confirmed never called anywhere in production code (its only repo reference is an unrelated `DestinationActivityObserver.isRunning()` call in a test).
- CONFIRMED Read `VerifyEngine.swift` startVerification/cancel (lines 1-181). `public actor VerifyEngine` (line 11); `startVerification(request:onEvent:)` (lines 16-177) has the identical no-guard pattern (`isCancelled = false` at line 17, unconditional).
- CONFIRMED Grep-verified exactly one production call site per architecture layer, no bypass path: `TransferControlsView.swift:429` (`viewModel.startTransfer()`) → `TransferViewModel.swift:305` (`await coordinator.startTransfer(...)`) → `TransferCoordinator.swift:89` (`Task.detached` → `runWorkflow`) → `TransferCoordinator.swift:342` (`await rsyncEngine.startTransfer(...)`).
- CONFIRMED Traced Scenarios A-E (full event-order tables in the report) proving: (A) no single guaranteed point makes a second Start impossible — only the async round-trip through the UI's disabled state provides any practical barrier; (B) two immediate `startTransfer()` calls can both pass every layer's guard and reach `RsyncEngine.startTransfer` concurrently on the same actor instance, producing two concurrent rsync `Process` launches against the same destination; (C) no layer atomically rejects a second Start the instant validation begins — the Coordinator's guard reads pre-mutation state; (D) direct/programmatic double-invocation of either `viewModel.startTransfer()` or `coordinator.startTransfer()` (no `await` between calls) reaches the same race deterministically, with zero UI/timing dependency; (E) the coordinator's and both engines' `isCancelled` flags are shared per-instance, not per-job-generation — a `startTransfer()` call issued shortly after a cancel resets `isCancelled` out from under the still-running old task, letting its stale completion write `.error`/state over a newly-started job.
- CONFIRMED Searched all of `FishSockTransfer/Tests/XCTest/*.swift` for repeated-start/admission/concurrent-start coverage: zero matches beyond `MetadataOnlySourceSafetyXCTests.swift`, which calls `coordinator.startTransfer` exactly once per test (preflight-failure paths only) and proves nothing about concurrency. `TransferViewModelRuntimeXCTests.testVerifyETAClearsOnCancelFailureResetNewJob` only simulates callbacks via direct `applyTransferState(...)` calls, never a real coordinator, and proves nothing about task/process admission.
- CONFIRMED Discovered via CodeGraph symbol search a stale, git-tracked but non-build-target directory `/Users/cenvu/DEV/FST_V2/Tests/UnitTests/` (0 references in `FishSockTransfer.xcodeproj/project.pbxproj`) containing a `TransferCoordinatorTests.swift` that assigns a settable `coordinator.onStateChanged` property that does not exist on the current `TransferCoordinator` API — confirmed pre-refactor scaffolding, not evidence about current behavior in either direction.
- CONFIRMED Ran 8 CodeGraph advisory queries (symbol_search, get_callers/get_callees on startTransfer and runWorkflow, analyze_impact, find_related_tests); classified each MATCH/PARTIAL/STALE/INCORRECT/BLOCKED in the report. `TransferViewModel.startTransfer()` never appears in any graph query result (BLOCKED — matches the documented Swift multi-file parse defect for `TransferViewModel.swift`). `get_callers`/`get_callees`/`analyze_impact`/`find_related_tests` on `TransferCoordinator.startTransfer`/`runWorkflow` were empty or undercounted versus direct source (INCORRECT/BLOCKED). `get_callees` on `runWorkflow` correctly matched direct source (PARTIAL/MATCH). No conclusion in the report relies on graph output; every claim is backed by direct source and grep.
- CONFIRMED Wrote the full investigation report to `/tmp/FST_REPEATED_START_INVESTIGATION.md` with all 19 required sections, final classification **CONFIRMED_RACE**, the "admission decision and transition out of ready occur within one serialized critical section" invariant classified **VIOLATED**, a Minimal Fix Plan (not implemented), and a Regression Test Plan (not implemented).
- CONFIRMED No production Swift, test, Xcode project, entitlement, or release file was modified at any point (`git status --short` / `git diff --stat -- FishSockTransfer/` empty for that path throughout the session).

## 7. Files Changed

| Path | Change Type | Reason | Production Behavior Changed |
|---|---|---|---|
| FST_AI/memory/TASK_REGISTRY.md | modified (append-only entry) | Record investigation task | NO |
| FST_AI/memory/WORK_HISTORY.md | modified (append-only entry) | Record investigation work history | NO |
| handoffs/<this-timestamped-handoff>.md | created (publisher) | Immutable published VERIFICATION handoff | NO |
| handoffs/CURRENT_HANDOFF.md | updated (publisher) | Points at the new handoff | NO |
| handoffs/INDEX.md | appended (publisher) | One new append-only entry | NO |
| /tmp/FST_REPEATED_START_INVESTIGATION.md | created | Investigation report (local scratch, not part of repo) | NO |

Files inspected but not changed (important for continuation): `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`, `FishSockTransfer/FishSockTransfer/ViewModels/TransferViewModel.swift`, `FishSockTransfer/FishSockTransfer/Engines/RsyncEngine.swift`, `FishSockTransfer/FishSockTransfer/Engines/VerifyEngine.swift`, `FishSockTransfer/FishSockTransfer/Views/TransferControlsView.swift`, `FishSockTransfer/Tests/XCTest/MetadataOnlySourceSafetyXCTests.swift`, `FishSockTransfer/Tests/XCTest/TransferViewModelRuntimeXCTests.swift`, `Tests/UnitTests/Coordinators/TransferCoordinatorTests.swift` (stale, not in build target), `Tests/UnitTests/ViewModels/TransferViewModelTests.swift` (stale, not in build target).

## 8. Verification Evidence

- Exact commands (working directory /Users/cenvu/DEV/FST_V2 unless noted):
  - `git rev-parse --show-toplevel && git branch --show-current && git rev-parse --short HEAD && git status --short && git log --oneline -5` — exit 0
  - `gh issue list --state all --limit 5 --json number,title` — exit 0, result `[]`; `gh repo view --json nameWithOwner` — exit 0, `cenvu/FST_V2`
  - `grep -rn "\.startTransfer(\|\.cancelTransfer(" FishSockTransfer/FishSockTransfer/` — exit 0, 5 matches (one call site per layer)
  - `grep -n "workflowTask" FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift` — exit 0, 2 matches (declaration + single assignment, confirming write-only)
  - `grep -rn "isRunning()" FishSockTransfer/` — exit 0, confirms `RsyncEngine.isRunning()` has no production caller
  - `grep -rln "repeated.start\|double.start\|...admission..." FishSockTransfer/Tests/XCTest/*.swift` — exit 0, 1 file matched (`MetadataOnlySourceSafetyXCTests.swift`, on the `startTransfer` substring only)
  - `ls -la Tests/; grep -c "Tests/UnitTests" FishSockTransfer/FishSockTransfer.xcodeproj/project.pbxproj; git ls-files Tests/UnitTests/` — exit 0, confirmed stale tracked-but-unbuilt directory
  - `git status --short && git diff --check && git diff --stat -- FishSockTransfer/` — exit 0, no production Swift changes at any point
- Targeted test result: NOT RUN — investigation-only Sprint; no code changed that would require a targeted test rerun; existing 169/169 baseline (recorded in `FST_AI/memory/CLAUDE_SESSION_CONTEXT.md`, 2026-08-01) is unaffected since no source was modified
- Full test result: not run (Lean Mode — no production/test file changed)
- Syntax or integration checks: `git diff --check` clean
- Manual verification: report file `/tmp/FST_REPEATED_START_INVESTIGATION.md` exists with all 19 required sections and a single unambiguous classification line
- Tests not run and the reason: full 169-test Xcode suite not rerun — Lean Mode explicitly limits this Sprint to investigation; no production or test source was modified so there is nothing new to validate by running the suite

## 9. Git and GitHub Evidence

- Branch: main
- Status: same pre-existing modified/untracked set as session start, plus this handoff's own files (TASK_REGISTRY.md, WORK_HISTORY.md, handoffs/) — no production path touched
- Diff summary: `git diff --stat -- FishSockTransfer/` — empty (zero production files changed)
- Commit: NONE
- Pull request: NONE
- Issue: NONE (no GitHub Issues exist in this repository)
- Uncommitted files: see Working Tree After in section 4
- Does repository state confirm the claimed work? YES — the report file exists on disk with the full required structure; `git diff --stat -- FishSockTransfer/` is empty confirming zero production changes; TASK_REGISTRY.md/WORK_HISTORY.md carry the new append-only entries

GitHub Issues are the task queue. Git, tests, commits, pull requests, and actual source are the final confirmation sources.

## 10. CodeGraph Evidence

- CodeGraph version: 0.19.1 (pinned @astudioplus/codegraph-mcp), profile `all`
- Index commit: 6c35cad (71 files, 628 symbols, per FST_AI/memory/CODEGRAPH_INDEX_STATUS.md; not reindexed this session — investigation-only, no source changed)
- Queries used: `codegraph_symbol_search` ("startTransfer", "runWorkflow", "TransferViewModel startTransfer"), `codegraph_get_callers`/`codegraph_get_callees` on `TransferCoordinator.startTransfer` (node 434) and `TransferCoordinator.runWorkflow` (node 436), `codegraph_analyze_impact` on `TransferCoordinator.startTransfer`, `codegraph_find_related_tests` on `TransferCoordinator.startTransfer`
- Result: 8 queries classified — 1 MATCH/PARTIAL (`runWorkflow` callees), 1 PARTIAL/MATCH-adjacent, 4 INCORRECT/BLOCKED (callers of startTransfer and runWorkflow both empty; analyze_impact undercounted to 1; find_related_tests returned 0 despite 3 real test call sites), 1 BLOCKED (TransferViewModel.startTransfer never indexed), 1 STALE (broad search surfaced the non-build-target Tests/UnitTests/ tree without distinguishing it from live code)
- Symbols found: `TransferCoordinator.startTransfer` (line 81), `TransferCoordinator.runWorkflow` (line 115), `TransferCoordinator.cancelTransfer` (line 94), `VerifyEngine.startVerification` (line 16) all queryable; `TransferViewModel.startTransfer` NOT queryable (parser defect)
- Impact analysis result: `codegraph_analyze_impact` on `TransferCoordinator.startTransfer` returned `direct_impacted: 1` (self only), `risk_level: low` — contradicted by direct source/grep, which found 1 production caller and 3 test call sites
- Direct-source confirmation: YES — every safety-relevant claim in the investigation report is backed by direct `Read`/`grep` evidence with exact line numbers, independent of CodeGraph output
- Parser limitations relevant to the task: `TransferViewModel.swift` and `RsyncEngine.swift` remain unparseable in the multi-file workspace (documented pre-existing defect, `FST_AI/memory/CODEGRAPH_INDEX_STATUS.md`); this directly affected queries 1-2, 4, 6-7 in the report's CodeGraph Evidence table

CodeGraph is advisory and did not replace direct source inspection.

## 11. Remaining Risks and Unknowns

- P0 CONFIRMED_RACE: `TransferCoordinator.startTransfer()`/`TransferViewModel.startTransfer()` admit repeated concurrent workflows; `RsyncEngine`/`VerifyEngine` have no re-entry guard; reachable deterministically via direct/programmatic double invocation (Scenario D), no fix applied yet by design (investigation-only Sprint).
- P0 Secondary defect discovered during this investigation: shared, non-per-generation `isCancelled` flags at the Coordinator/RsyncEngine/VerifyEngine layers allow a stale cancelled task's completion to mutate a newly-started job's state (Scenario E) — same root cause class (no generation/job id anywhere in the codebase), same fix family.
- P1 No regression test exists anywhere in the repository (build-target or stale `Tests/UnitTests/`) that would catch either defect; a future contributor could "fix" one code path and leave the other silently vulnerable without a test to guard it.
- P2 Runtime reproduction was not captured (no Instruments/os_signpost trace); the report's timeline is a structural proof from source plus reasoned Swift Concurrency scheduling behavior, not an observed trace on a live build (see report's Missing Evidence section).
- P3 The stale `Tests/UnitTests/` directory (not in the Xcode target, API-incompatible with current `TransferCoordinator`) remains in the repository and could mislead a future agent searching for coverage; out of scope to remove/clean up during this investigation-only Sprint.

## 12. Safety Invariants

- Source media read-only: PRESERVED — no source-access code touched or analyzed as writable
- Coordinator-only TransferState ownership: PRESERVED — confirmed by direct source; the race does not violate this rule (only `TransferCoordinator.updateState` ever writes `TransferState`), but it does allow *multiple concurrent legitimate writers* (multiple `runWorkflow` invocations) into that single writer, which is the defect
- SAFE TO EJECT gate: AFFECTED (latent) — not directly bypassed by this race, but a stale/second `runWorkflow` could in principle reach `updateState(.safeToFormat)` for an abandoned job and have it read as the coordinator's current state; not yet proven reachable in this investigation (would require a follow-up trace), flagged as a concrete remaining risk
- Verification none never SAFE TO EJECT: PRESERVED — unrelated code path, not touched
- Bundled rsync 3.4.4 only: PRESERVED — race does not touch rsync binary resolution
- Observer/Telegram/update-check isolation: PRESERVED — unrelated code path, not touched
- Cancellation cannot produce success: AFFECTED (latent) — Scenario E shows cancellation state can be silently reset by a new start, allowing a stale task to write `.error` (not success) over a newer job; the report did not find a path to false *success* specifically, but did find a path to state corruption, which is safety-relevant and warrants the fix
- Reports cannot overstate safety: PRESERVED for this Sprint — no report-generation code was touched; the report notes a stale task could still write a spurious TRANSFER ERROR report for an abandoned job, which is a truthfulness gap worth fixing but not an overstatement of success

## 13. Single Next Action

- Action: Implement one focused regression test that demonstrates the race, then apply the smallest admission-guard fix.
- Reason: `TransferCoordinator.startTransfer()`'s admission guard reads `state` without synchronously reserving it (the `.validating` transition is deferred into a separately-scheduled `Task.detached`), `TransferViewModel.startTransfer()` has no `transferState` guard at all, and `RsyncEngine`/`VerifyEngine` have no re-entry guard — confirmed reachable via direct/programmatic double invocation with no timing luck required (Scenario D in the report).
- Exact Files: `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`, `FishSockTransfer/FishSockTransfer/ViewModels/TransferViewModel.swift`, plus a new regression test under `FishSockTransfer/Tests/XCTest/`
- Exact Symbols: `TransferCoordinator.startTransfer(source:destination:bandwidthLimit:mode:)` (line 81), `TransferCoordinator.workflowTask` (line 31), `TransferCoordinator.runWorkflow` (line 115), `TransferCoordinator.isCancelled` (line 30), `TransferViewModel.startTransfer()` (line 261), `TransferViewModel.canStartTransfer` (line 744)
- Acceptance Evidence: a new regression test that calls `startTransfer` twice back-to-back with no `await` between calls and asserts only one workflow/rsync invocation occurs; the fix makes state reservation synchronous with the admission guard (single non-suspending critical section) and threads a generation id through `runWorkflow` so stale completions cannot mutate a newer job; full 169+N tests passing
- Stop Condition: regression test added and passing against the fix, full `xcodebuild test` green, evidence recorded, and a new handoff published

## 14. Resume Prompt

```text
You are continuing FST work. Read the authority documents (AGENTS.md,
FST_AI/memory/COMMAND_CENTER_HANDOVER.md, docs/00_AI_AGENT_START_HERE.md,
FST_AI/memory/TASK_REGISTRY.md, FST_AI/memory/WORK_HISTORY.md). Read
handoffs/CURRENT_HANDOFF.md. Check git status and the current commit. Check
the relevant GitHub Issue (none exist yet for this repository). Connect
fst-codegraph. Inspect direct source before editing. Read the full
investigation report referenced by the current handoff
(/tmp/FST_REPEATED_START_INVESTIGATION.md, or reconstruct its Minimal Fix
Plan and Regression Test Plan sections from the current handoff if that path
is unavailable). Perform only the Single Next Action from the current
handoff: implement one focused regression test demonstrating the repeated-
start admission race (call TransferCoordinator.startTransfer twice with no
await between calls, or TransferViewModel.startTransfer twice on MainActor,
and assert only one workflow/rsync invocation occurs), then apply the
smallest admission-guard fix — make the state reservation in
TransferCoordinator.startTransfer() synchronous with its admission guard,
thread a generation/job id through runWorkflow() so stale completions from
an abandoned task cannot mutate a newer job's state, and add an explicit
canStartTransfer guard inside TransferViewModel.startTransfer(). Work in
Sprint Mode (one narrow task, one smallest safe change surface, one handoff)
and Lean Mode, but this time run the full 169+N-test suite since this is a
safety-critical source change. Publish a new handoff when done using
FST_AI/tools/publish_handoff.py. Never edit an old handoff.
```

## 15. References

- Prior handoffs: 20260801-123020_claude-code_implement-permanent-append-only-cross-agent-hand (its Single Next Action was this investigation)
- GitHub Issues: NONE
- Commits: 6c35cad12a20e664bbcaf972bf03f52589792dd0 (main, starting and ending point — unchanged)
- Pull requests: NONE
- Authority documents: AGENTS.md, docs/00_AI_AGENT_START_HERE.md, docs/01_PRD.md, docs/02_FST_TECHNICAL_GUIDE.md, docs/03_PROJECT_MASTER_GUIDELINE.md, CLAUDE.md, FST_AI/memory/CODEGRAPH_OPERATING_RULES.md
- Reports: /tmp/FST_REPEATED_START_INVESTIGATION.md (full investigation report, 19 sections, classification CONFIRMED_RACE)
- Logs: NONE