# FST Claude Code Instructions

FST / FishSock Transfer is a native macOS SwiftUI app for DIT / Data Wrangler
media offload. One source -> one destination -> one active job. It provides
copy and verification evidence only; it never formats, erases, reuses, or
ejects source media.

## Read First

- AGENTS.md
- FST_AI/memory/COMMAND_CENTER_HANDOVER.md
- docs/00_AI_AGENT_START_HERE.md
- FST_AI/memory/TASK_REGISTRY.md
- FST_AI/memory/WORK_HISTORY.md

For deeper context: `docs/01_PRD.md`, `docs/02_FST_TECHNICAL_GUIDE.md`,
`docs/03_PROJECT_MASTER_GUIDELINE.md`, `README.md`, `CHANGELOG.md`,
`FST_AI/memory/CLAUDE_SESSION_CONTEXT.md`.

## Authority Order

If docs conflict, this order wins:

1. AGENTS.md
2. FST_AI/memory/COMMAND_CENTER_HANDOVER.md
3. docs/00_AI_AGENT_START_HERE.md
4. FST_AI/memory/TASK_REGISTRY.md
5. FST_AI/memory/WORK_HISTORY.md

Do not silently reconcile conflicts; surface them.

Before running a task, check `TASK_REGISTRY.md` and `WORK_HISTORY.md` — if the
task appears already completed, ask whether to rerun, continue, or review.

After meaningful work, propose updates to `WORK_HISTORY.md` and
`TASK_REGISTRY.md`; if the baseline changes, propose a
`COMMAND_CENTER_HANDOVER.md` update.

## Product Mission

Answer one question: "Can the source media be safely ejected and handed off?"

Workflow: SOURCE -> COPY -> VERIFY -> SAFE TO EJECT / OPERATOR HANDOFF.

Priority: Data Safety -> Reliability -> Truthful Operator Feedback -> Speed ->
Convenience.

## Non-Negotiable Safety Rules

- Source media is read-only. Never mutate, delete, rename, move, clean, or
  write metadata on source media.
- Copy success alone is not verified success.
- UI estimates, destination-observer metrics, Telegram notifications, and
  update-check results must never authorize copy success, verification
  success, or SAFE TO EJECT.
- Operator-facing output uses SAFE TO EJECT / SAFE TO EJECT DESTINATION.
  Never display SAFE TO FORMAT or "format" language as a verified result.
- Data safety beats refactoring, abstraction, performance, convenience, and
  UI polish.

## Architecture Boundary

Allowed dependency flow only:

```text
SwiftUI View -> TransferViewModel -> TransferCoordinator -> Engines -> Services
```

Forbidden: View -> Engine/Service, ViewModel launching rsync/hashing or owning
workflow, Engine importing SwiftUI, Service changing TransferState,
Coordinator rendering UI.

## State Ownership

Only `TransferCoordinator` may change `TransferState`. Allowed states only:

```text
ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled
```

`safeToFormat` is a legacy internal state name. Operator-facing UI, logs,
reports, and docs must use SAFE TO EJECT.

## SAFE TO EJECT Gate

```text
SAFE TO EJECT = authoritative copy success AND authoritative verification success
```

Verification mode `none` may end at `copyComplete` (TRANSFER COMPLETE) but must
never produce `safeToFormat` or display SAFE TO EJECT. No operator override,
warning bypass, or auto-approval.

## Bundled Rsync Rule

Production transfer must use the bundled rsync 3.4.4 binary resolved through
`BundledRsyncService`, with executable and version validation. Silent fallback
to `/usr/bin/rsync`, Homebrew, MacPorts, or any other rsync installation is
forbidden. App version and rsync version are separate fields.

## Verification Rules

Modes: `none` (no hashing), `random33` (SHA256 sample ~33%, min 1 file),
`full` (xxHash64 100%). Compare relative paths and sizes before hashing. Any
verification failure blocks SAFE TO EJECT. `VerifyEngine` emits results;
`TransferCoordinator` decides the final state. Verify off the MainActor.

## Change Discipline

- Simple, explicit Swift; small changes; guard clauses; async/await.
- Patch the smallest safe surface; add or update tests when changing
  engine/parser/coordinator/report behavior.
- Never run rsync, hashing, scanning, or report generation on the MainActor.
- No silent `catch {}`, unsafe `try?`, or undocumented rsync flags.
- Do not add queue, multi-destination, cloud sync, database, MHL, LTO, or
  other out-of-scope features unless explicitly requested.
- Do not reintroduce dropped agent workflows (Roo/RooCode) or deprecated
  wording unless the user explicitly asks.
- No new dependencies unless they reduce media-loss risk.

## Required Tests and Reporting

- Standard checks:
  - `git diff --check`
  - `xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' build`
  - `xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS'`
  - `bash scripts/package-local-arm64.sh` (release packaging only)
- Use a Claude-specific DerivedData directory (e.g. `/tmp/FST-Claude-DerivedData`)
  to avoid colliding with other terminal sessions.
- Report format: PHASE / FILES / LAYER CHECK / PATCH / TESTS / VERIFY.
- When final status is uncertain, fail safely and tell the operator not to
  erase or reuse the source.

## CodeGraph MCP (fst-codegraph)

For Claude Code and DeepSeek through the Claude Code harness:

- The MCP server is `fst-codegraph` (project scope, `.mcp.json`), backed by
  `FST_AI/tools/fst-codegraph-mcp.sh` (pinned `@astudioplus/codegraph-mcp@0.19.1`).
- Read `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md` before coding; it lists the
  actual tool names and the bootstrap queries.
- Run pre-edit context and impact analysis via CodeGraph
  (`codegraph_get_edit_context`, `codegraph_analyze_impact`,
  `codegraph_get_callers`, `codegraph_get_callees`,
  `codegraph_find_related_tests`) before production edits; reindex with
  `codegraph_reindex_workspace` after changes.
- CodeGraph is an index, not the source of truth: actual Swift source, tests,
  Git state, AGENTS.md, and FST authority documents win.
- Fall back to direct source inspection when CodeGraph is unavailable; never
  block emergency inspection merely because MCP is unavailable. Never edit
  blindly.

## Handoff System (cross-agent)

For Claude Code and DeepSeek through the Claude Code harness:

- Read `handoffs/CURRENT_HANDOFF.md` before starting work and after resuming.
- Timestamped handoffs under `handoffs/` are immutable; `handoffs/INDEX.md` is
  append-only. Never edit historical entries; publish a CORRECTION or
  VERIFICATION handoff instead.
- GitHub Issues are the task queue; Git, tests, commits, PRs, and source are
  the final confirmation sources — a handoff is never proof when repository
  evidence disagrees.
- Before work: authority docs, `CURRENT_HANDOFF.md`, Git status/commit, the
  relevant GitHub Issue, `fst-codegraph`, direct source, confirm not already
  done; work in Sprint Mode and Lean Mode.
- After meaningful work: verify, inspect `git diff`, update the Issue when
  authorized, publish one handoff via
  `python3 FST_AI/tools/publish_handoff.py --draft <file> --agent "Claude Code"
  --model <model> --task <task> --phase <phase> --type NORMAL --corrects NONE`,
  confirm timestamped file + CURRENT + exactly one INDEX entry, report the
  filename, never edit an old handoff.
- Full rules: `handoffs/README.md`.
