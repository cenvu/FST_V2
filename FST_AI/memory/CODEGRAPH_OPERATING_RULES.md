# FST CodeGraph Operating Rules

Applies to: Gemini (Antigravity IDE), GPT (Codex CLI), Claude, and DeepSeek
through the Claude Code harness. Server name: `fst-codegraph` — project-scoped
MCP stdio server for this repository only. See
`FST_AI/memory/CODEGRAPH_INDEX_STATUS.md` for version, profile, and reindex
procedure.

## Load and session bootstrap

This is an L2 reference. Load it only for production-source work or a task
about CodeGraph. It is not a general startup document.

For production-source work:

1. Follow the L0 startup/kernel in `AGENTS.md` and read CURRENT's HOT header.
2. Check Git status, branch, HEAD, and configured upstream.
3. When the `fst-codegraph` MCP is available, confirm its workspace is
   `/Users/cenvu/DEV/FST_V2` (or `git rev-parse --show-toplevel`) and query the
   target subsystem.
4. Identify entry points, callers, callees, dependencies, tests, and state
   mutations from graph results; then read the exact source and tests.
5. Compare graph results with current source. Source wins. If they disagree,
   reindex when available and record the discrepancy.

## Before editing

Before modifying any production symbol, when CodeGraph is available, the model must:

1. Request edit context: `codegraph_get_edit_context` for the target symbol/file.
2. Request impact analysis: `codegraph_analyze_impact` for the target symbol.
3. Inspect direct callers and callees: `codegraph_get_callers`,
   `codegraph_get_callees`, `codegraph_get_call_graph`, or
   `codegraph_traverse_graph`.
4. Locate related tests: `codegraph_find_related_tests` for the symbol.
5. Identify architecture-layer ownership (View / ViewModel / Coordinator /
   Engine / Service) and confirm the dependency direction
   `View -> ViewModel -> Coordinator -> Engines -> Services`.
6. Identify which FST safety invariants are affected (source read-only, state
   ownership, SAFE TO EJECT gate, verification rules, bundled rsync, observer
   isolation, report truthfulness).
7. State the smallest safe change surface.

For state-machine, transfer, verification, report, cancellation, rsync, source
access, notification, or update-check changes, direct source inspection is
mandatory even when CodeGraph returns a summary.

## During editing

The model must:

- edit only files justified by graph evidence;
- avoid opportunistic refactoring;
- avoid moving files;
- preserve architecture direction;
- preserve source read-only behavior;
- preserve coordinator-only state ownership (only `TransferCoordinator` changes
  `TransferState`);
- update or add tests for changed behavior;
- stop when graph results contradict actual source and report the discrepancy.

## After production-source editing

The model must:

1. Reindex: `codegraph_reindex_workspace` (or the documented CLI reindex procedure).
2. Rerun impact analysis: `codegraph_analyze_impact` on the changed symbols.
3. Rerun related tests: `codegraph_find_related_tests` then execute them.
4. Run the canonical test command
   (`xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS'` from `FishSockTransfer/`).
5. Inspect the Git diff (`git diff --check`, `git status --short`).
6. Record meaningful work in `FST_AI/memory/WORK_HISTORY.md` and
   `FST_AI/memory/TASK_REGISTRY.md` (propose; do not rewrite).
7. Report changed files, tests, risks, and remaining uncertainty.

For control-plane/docs-only changes, use the relevant repository sources,
publisher/exporter tests and Git diff gates. Do not run Xcode or load this full
reference unless the task demonstrates a need.

## Trust rules

```text
CodeGraph is an index, not the source of truth.
Stale graph data must be reindexed.
CodeGraph memory is advisory.
Actual source, tests, Git state, AGENTS.md, and FST authority documents win.
Graph absence does not prove code absence.
Graph linkage does not prove runtime correctness.
No model may approve SAFE TO EJECT behavior from graph summaries alone.
```

## Required project bootstrap queries

Tool names are the actual tools exposed by `fst-codegraph`
(@astudioplus/codegraph-mcp 0.19.1, profile `all`):

| Intention | CodeGraph tool(s) |
|---|---|
| Map application entry points | `codegraph_find_entry_points` (workspace) or `codegraph_traverse_graph` on `FishSockTransferApp` |
| Map TransferCoordinator callers and callees | `codegraph_get_callers TransferCoordinator`, `codegraph_get_callees TransferCoordinator.startTransfer`, `codegraph_get_call_graph TransferCoordinator` |
| Locate every TransferState mutation | `codegraph_get_callers TransferState.updateState`, `codegraph_get_callers TransferState`; then verify by direct source inspection |
| Locate every path to safeToFormat | `codegraph_get_callers TransferCoordinator.safeToFormat`, `codegraph_find_by_signature "safeToFormat"`; then verify by direct source inspection |
| Map VerifyEngine.startVerification and sample selection | `codegraph_get_callees VerifyEngine.startVerification`, `codegraph_get_detailed_symbol VerifyEngine.sampleFiles` |
| Map RsyncEngine process and cancellation flow | `codegraph_get_callees RsyncEngine.startTransfer`, `codegraph_get_callers RsyncEngine.cancel` |
| Map BundledRsyncService resolution and version validation | `codegraph_get_callees BundledRsyncService.bundledInfo`, `codegraph_get_detailed_symbol BundledRsyncService.parseVersion` |
| Find tests related to a safety-critical symbol | `codegraph_find_related_tests <symbol>` |
| Calculate impact before editing any of these symbols | `codegraph_analyze_impact <symbol>` |

Additional supported tools: `codegraph_symbol_search`,
`codegraph_get_symbol_info`, `codegraph_get_detailed_symbol`,
`codegraph_get_edit_context`, `codegraph_get_ai_context`,
`codegraph_get_curated_context`, `codegraph_find_by_imports`,
`codegraph_find_by_signature`, `codegraph_find_implementors`,
`codegraph_search_by_pattern`, `codegraph_search_by_error`,
`codegraph_get_dependency_graph`, `codegraph_get_module_summary`,
`codegraph_analyze_complexity`, `codegraph_find_circular_deps`,
`codegraph_find_hot_paths`, `codegraph_find_dead_imports`,
`codegraph_pr_context`, `codegraph_index_files`, `codegraph_index_directory`,
`codegraph_index_markdown`, `codegraph_search_docs`, `codegraph_memory_*`.

## Fallback

When `fst-codegraph` is unavailable or stale:

- Never block emergency inspection merely because MCP is unavailable.
- Use direct source inspection (Read/Grep) instead.
- Never edit blindly; always identify the owning layer and the smallest safe
  change surface before editing.
- Reindex before relying on graph evidence again.

## Known graph limitations (must-read)

The official runtime pinned for FST (codegraph-server 0.19.1) has two
documented upstream Swift defects (see `FST_AI/memory/CODEGRAPH_INDEX_STATUS.md`):

1. **Files that fail to parse in a multi-file workspace** (Symbol search and
   graph tools return nothing for them — always Read the source directly):
   `ViewModels/TransferViewModel.swift`, `Engines/RsyncEngine.swift`,
   `Tests/XCTest/AppUpdateServiceXCTests.swift`,
   `Tests/XCTest/NotificationCoordinatorXCTests.swift`.
2. **Swift call edges are not reliably extracted**: `codegraph_get_callees`
   frequently returns empty and `codegraph_get_callers` may miss production
   callers. Never conclude "no callers/callees" from an empty graph result;
   verify with direct source inspection (mandatory for the safety-critical
   symbols listed above).

## Handoff System

- Read only the HOT header of `handoffs/CURRENT_HANDOFF.md` at startup or
  reanchor; load other sections only when the task needs them.
- Timestamped handoffs under `handoffs/` are immutable evidence;
  `handoffs/INDEX.md` is append-only. Never edit historical entries; publish
  a CORRECTION or VERIFICATION handoff that references the older file.
- GitHub Issues are the task queue. Git, tests, commits, pull requests, and
  actual source are the final confirmation sources — never treat a handoff as
  proof when repository evidence disagrees.
- Sprint Mode and Lean Mode are active for all agent work.
- Publish completed work with `FST_AI/tools/publish_handoff.py` and report the
  published filename. Full procedure: `handoffs/README.md`.
