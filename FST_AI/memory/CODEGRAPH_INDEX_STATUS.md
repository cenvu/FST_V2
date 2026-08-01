# FST CodeGraph Index Status

Status: INSTALLED — index built with a documented upstream Swift parser
limitation (see "Known Limitations"). Integration date: 2026-08-01.

## Exact version and origin

- Runtime: `codegraph-server-darwin-arm64` v0.19.1 (git ef6a466)
- Package: `@astudioplus/codegraph-mcp@0.19.1` (exact, pinned)
- Origin: https://github.com/codegraph-ai/CodeGraph (Apache-2.0, official)
- Built: 2026-07-19 with rustc 1.93.1
- Server binary self-identifies as `codegraph-server v0.19.1 (ef6a466)`
- Telemetry: anonymous usage telemetry in the package; explicitly disabled for
  FST via `CODEGRAPH_TELEMETRY=off` (documented opt-out). No API keys, no
  telemetry credentials added.

## Installation method

```bash
npm install --prefix "$HOME/.local/share/fst-codegraph-mcp" --no-fund --no-audit @astudioplus/codegraph-mcp@0.19.1
```

Installed OUTSIDE the repository (no package.json / node_modules added to FST).
Binary: `$HOME/.local/share/fst-codegraph-mcp/node_modules/@astudioplus/codegraph-mcp/bin/codegraph-server-darwin-arm64`.

## Pinned runtime command (wrapper)

`FST_AI/tools/fst-codegraph-mcp.sh` (executable, POSIX bash, dynamic repo-root
resolution, refuses to serve any directory other than /Users/cenvu/DEV/FST_V2,
diagnostics only to stderr, nonzero exit on invalid setup):

```bash
codegraph-server-darwin-arm64 --mcp \
  --workspace /Users/cenvu/DEV/FST_V2 \
  --exclude .git --exclude DerivedData --exclude build --exclude dist --exclude archives \
  --profile all
```

Stdio MCP transport. No secrets forwarded.

## Selected profile

`all` (42 tools). Reason: no narrower profile exposes the required pre-edit
tool set. Verified by tools/list handshakes: `graph` (17 tools) lacks
`codegraph_symbol_search`, `codegraph_get_edit_context`,
`codegraph_reindex_workspace`; `core` (8) lacks callers/callees/dependency
graph/impact/related-tests; `memory` lacks search/context/graph. `all` is the
only profile containing all eight required capabilities: symbol search, AI
edit context, callers, callees, dependency graph, impact analysis, related
tests, workspace reindexing.

## Index date and repository commit

- Index rebuilt (force): 2026-08-01
- Repository commit: 6c35cad12a20e664bbcaf972bf03f52589792dd0 (main)

## Index statistics

- Files indexed: 71 (force reindex: 71 parsed, 0 skipped)
- Symbols: 628 symbol vectors embedded (BGE-Small-EN-v1.5, 384d, 512-tok) for
  namespace `fst-v2-c035`
- Languages detected: Swift (primary), TypeScript/JS/CSS (docs/archive legacy
  web prototype, git-tracked historical files), Markdown (12 authority
  documents indexed via `codegraph_index_markdown`), TOML, YAML, shell
- Swift files detected by CodeGraph: 67 of 71 (4 Swift files fail to parse,
  see Known Limitations)
- Excluded paths: `.git`, `DerivedData`, `build`, `dist`, `archives`
- Authority documents indexed (codegraph_index_markdown, 12):
  AGENTS.md, CLAUDE.md, FST_AI/memory/COMMAND_CENTER_HANDOVER.md,
  docs/00_AI_AGENT_START_HERE.md, FST_AI/memory/TASK_REGISTRY.md,
  FST_AI/memory/WORK_HISTORY.md, docs/01_PRD.md, docs/02_FST_TECHNICAL_GUIDE.md,
  docs/03_PROJECT_MASTER_GUIDELINE.md, CHANGELOG.md, README.md,
  FST_AI/memory/CODEGRAPH_OPERATING_RULES.md
- Indexing warnings: 4 SyntaxError warnings (Swift parser defect, below)
- Indexing failures: 0 fatal; 4 per-file parse failures (below)

## Database / cache location

Home scope (shared by CodeGraph tooling on this machine):

- Per-project index: `~/.codegraph/projects/fst-v2-c035/` (index_state.json +
  memory/)
- Graph database: `~/.codegraph/graph.db/` (RocksDB)
- Embedding model cache: `~/.codegraph/fastembed_cache/`
- Pre-integration state backed up to `~/.codegraph.bak-fst-20260801-*` (the
  earlier index contained stale data from the previous `@colbymchenry/codegraph`
  1.4.1 fork session; the force reindex rebuilt it with the official runtime).

## Client configurations

| Client | Config file | Server name | Status |
|---|---|---|---|
| Claude Code (incl. DeepSeek V4 Flash via harness) | `.mcp.json` (project scope) | `fst-codegraph` | Registered; requires one-time `/mcp` project approval in an interactive Claude session |
| Antigravity IDE / Gemini | `.agents/mcp_config.json` (workspace local) | `fst-codegraph` | Configured; rule at `.agents/rules/fst-codegraph.md` |
| Codex CLI (GPT) | `~/.codex/config.toml` (global; Codex 0.145 has no project MCP scope) | `fst-codegraph` | Registered and enabled; wrapper permanently scoped to FST |

The Codex config was backed up to `~/.codex/config.toml.bak-20260801-115141`
before the change. Only the `fst-codegraph` entry was added; all pre-existing
servers (`codegraph` fork entry, `node_repl`, `computer-use`, `github`) are
untouched. The pre-existing `codegraph` MCP entries in Claude Code and Codex
point at the unrelated `@colbymchenry/codegraph` fork and were left untouched.

## Smoke-test results (2026-08-01, vs direct source)

Server start + initialize + tools/list: PASS (42 tools, profile all).
Force reindex via wrapper: PASS (71 parsed). Docs indexing: PASS (12 docs).

| # | Query | Result |
|---|---|---|
| 1 | Application entry point | PARTIAL — `codegraph_symbol_search` finds `FishSockTransferApp` (FishSockTransferApp.swift:12); `codegraph_find_entry_points` heuristic returns test functions, not `@main`; source confirms `@main` SwiftUI App |
| 2 | Transfer orchestration owner | MATCH — `TransferCoordinator` (Coordinators/TransferCoordinator.swift:5) |
| 3 | TransferState mutation locations | PARTIAL — `codegraph_get_callers TransferCoordinator.updateState` (depth 2) returns test callers; production call sites not directly attributed; direct source confirms all 13 mutations inside `TransferCoordinator` (lines 124-307) |
| 4 | Paths to `safeToFormat` | PARTIAL — `codegraph_traverse_graph` incoming on `TransferState.safeToFormat` returns only the Contains edge; source confirms single transition at TransferCoordinator.swift:307 |
| 5 | Can `none` reach `safeToFormat`? | PARTIAL — `codegraph_get_edit_context` returns current `runWorkflow` source incl. the `.none` fast-exit; graph cannot prove the negative; source confirms fast-exit at TransferCoordinator.swift:229-247 (never `safeToFormat`) |
| 6 | Callers of `VerifyEngine.startVerification` | PARTIAL — 5 test callers found (VerificationHashStrategyXCTests, MetadataOnlySourceSafetyTests, VerifyEngineTests); production caller `TransferCoordinator.executeVerify` missing (Swift call-edge defect) |
| 7 | Callees of `VerifyEngine.startVerification` | INCORRECT (documented defect) — returns empty with server diagnostic "the language parser doesn't extract call relationships"; source shows buildInventory / sampleFiles / generateHash |
| 8 | Tests covering verification-none | PARTIAL — `codegraph_find_related_tests` returned 0 (defect); source inventory: ReportEngineXCTests.testCopyOnlyReportIsTransferCompleteAndNotSafeToEject, TransferViewModelRuntimeXCTests, MetadataOnlySourceSafetyXCTests |
| 9 | Bundled rsync validation participants | PARTIAL — callees empty (defect); symbols resolve; source shows resolveBundledInfo -> parseVersion/runVersionCommand; callers TransferViewModel.refreshBundledRsyncInfo, RsyncEngine.startTransfer, TransferCoordinator.saveTerminalReport |
| 10 | Blast radius of `TransferCoordinator.startTransfer` | PARTIAL — 11 direct impacts found (10 tests + self); production caller `TransferViewModel.startTransfer` missing (its file fails to parse, below) |

Critical-symbol connectivity: TransferCoordinator MATCH; TransferState,
VerifyEngine, BundledRsyncService, ReportEngine queryable; **TransferViewModel
and RsyncEngine NOT queryable** (parser defect, below).

## Known limitations

1. **Swift multi-file parse defect in codegraph-server 0.19.1 (upstream)**.
   These files deterministically fail with `SyntaxError` when indexed in a
   multi-file workspace (each parses correctly alone; the failure follows the
   file content, not the filename — verified by rename experiments):
   - `FishSockTransfer/FishSockTransfer/ViewModels/TransferViewModel.swift`
   - `FishSockTransfer/FishSockTransfer/Engines/RsyncEngine.swift`
   - `FishSockTransfer/Tests/XCTest/AppUpdateServiceXCTests.swift`
   - `FishSockTransfer/Tests/XCTest/NotificationCoordinatorXCTests.swift`
   Impact: 2 of the 7 critical FST symbols (TransferViewModel, RsyncEngine)
   are not queryable through the graph. Cannot be fixed within task
   constraints: production Swift source must not be modified, Swift source
   must not be excluded, and 0.19.1 is the latest official version.
   Mitigation: the shared operating rules already mandate direct source
   inspection for safety-critical code; models must Read
   TransferViewModel.swift / RsyncEngine.swift directly.
2. **Swift call edges are not reliably extracted** (callees empty for known
   calling functions; callers partial; server diagnostic acknowledges the
   parser limitation). Verify call relationships against direct source.
3. `codegraph_find_entry_points` does not classify SwiftUI `@main` apps as
   entry points; use `codegraph_symbol_search` for `FishSockTransferApp`.
4. The pre-existing `codegraph` MCP entries (Claude user scope, Codex, Gemini
   user config `~/.gemini/config/mcp_config.json`) belong to the unrelated
   `@colbymchenry/codegraph` fork and were intentionally left untouched.

## Reindex procedure

- Incremental: MCP tool `codegraph_reindex_workspace` (no args) — only
  re-parses changed files.
- Full rebuild: MCP tool `codegraph_reindex_workspace` with `{"force": true}`
  — clears the graph namespace and re-parses all 71 files.
- Docs reindex: `codegraph_index_markdown` with the file path (replaces
  previous chunks for that path).
- After any code change: run `codegraph_reindex_workspace`, then
  `codegraph_analyze_impact` on changed symbols, per
  `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md`.

## Uninstall / rollback

Rollback removes only this integration; application source is untouched:

1. Remove `fst-codegraph` from `.mcp.json` (Claude project scope).
2. Remove `fst-codegraph` from `.agents/mcp_config.json` (Antigravity).
3. `codex mcp remove fst-codegraph` (or restore `~/.codex/config.toml` from
   `~/.codex/config.toml.bak-20260801-115141`).
4. Remove `FST_AI/tools/fst-codegraph-mcp.sh`.
5. Remove `.agents/rules/fst-codegraph.md`,
   `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md`, this file, and the CodeGraph
   sections added to AGENTS.md / CLAUDE.md.
6. Optional: remove the FST index — `rm -rf ~/.codegraph/projects/fst-v2-c035`
   and `~/.codegraph/graph.db` (CodeGraph regenerates them on next start);
   pre-integration state is preserved in `~/.codegraph.bak-fst-*`.
7. Unrelated MCP servers and the unrelated `codegraph` fork entries are left
   untouched throughout.

No credentials are stored in any integration file.
