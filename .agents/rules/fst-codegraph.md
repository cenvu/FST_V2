# FST CodeGraph workspace rule (Antigravity / Gemini)

For FST production-source work, query the `fst-codegraph` MCP server when it is
available before editing the affected source. Use structural context for the
target symbols, callers, callees, impact, and related tests. This rule does not
add CodeGraph startup work for control-plane, documentation, or read-only tasks.

- Server name: `fst-codegraph` (stdio, project-scoped to /Users/cenvu/DEV/FST_V2).
- Always pass the repository root `/Users/cenvu/DEV/FST_V2` as the workspace/project path when a tool requires it.
- Do not reuse a previous workspace's or conversation's project root.
- Reject every graph result whose path is outside the FST repository root.

Full operating rules (all models): [../../FST_AI/memory/CODEGRAPH_OPERATING_RULES.md](../../FST_AI/memory/CODEGRAPH_OPERATING_RULES.md)

Non-negotiables:

- Source media is read-only. Never mutate, delete, rename, move, clean, or write metadata on source media.
- Only `TransferCoordinator` may change `TransferState`.
- SAFE TO EJECT requires authoritative copy success AND verification success.
- Verification mode `none` may end at `copyComplete`, never SAFE TO EJECT.
- Production transfer uses bundled rsync 3.4.4 only; no silent fallback.
- UI progress, destination-observer metrics, and Telegram notifications never decide transfer or verification success.
- CodeGraph is an index, not the source of truth: actual Swift source, tests,
  Git state, AGENTS.md, and FST authority documents win. Graph absence does not
  prove code absence. Graph linkage does not prove runtime correctness.
- No model may approve SAFE TO EJECT behavior from graph summaries alone.

Fallback: when `fst-codegraph` is unavailable, use direct source inspection
(Read/Grep) — never edit blindly, and never block emergency inspection merely
because MCP is unavailable.

## FST Handoff System (Antigravity / Gemini)

- Read only the HOT header of `handoffs/CURRENT_HANDOFF.md` at startup and
  reanchor; load other sections only when needed.
- Timestamped handoffs are immutable; `handoffs/INDEX.md` is append-only.
  Never edit historical entries; publish a CORRECTION or VERIFICATION handoff
  instead.
- GitHub Issues are the task queue; Git, tests, commits, PRs, and source are
  the final confirmation sources — a handoff is never proof when repository
  evidence disagrees.
- Before work: L0 kernel and CURRENT HOT, fresh Git state, matching issue and
  targeted duplicate search. Use CodeGraph for production-source work when
  available, then inspect direct source; work in Sprint Mode and Lean Mode.
- After meaningful work: verify, inspect `git diff`, update the Issue when
  authorized, publish one handoff via
  `python3 FST_AI/tools/publish_handoff.py --draft <file> --agent "Antigravity
  IDE" --model <model> --task <task> --phase <phase> --type NORMAL
  --corrects NONE`, confirm timestamped file + CURRENT + exactly one INDEX
  entry, report the filename, never edit an old handoff.
- Full rules: `handoffs/README.md` and
  `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md`.
