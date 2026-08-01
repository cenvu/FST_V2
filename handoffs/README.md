# FST Handoff System

Operational continuation records shared by every coding agent: Antigravity IDE
(Gemini), Codex CLI (GPT), Claude Code (Claude), Claude Code harnesses using
DeepSeek V4 Flash, and future compatible agents.

## Purpose

A handoff records what one agent run actually did, what it verified, what
remains unknown, and the single next action — so the next agent can continue
without re-deriving context. Handoffs are **operational evidence and
continuation context**, not replacements for Git or GitHub Issues.

## Source-of-truth boundaries

- **Task queue:** GitHub Issues.
- **Final confirmation:** repository state, commits, tests, pull requests, and
  actual source.
- **Operational context:** `handoffs/` files.
- **CodeGraph:** advisory index only; never replaces direct source inspection.
- A handoff is never proof when repository evidence disagrees with it.

## Layout

```text
handoffs/
  README.md              <- this file
  HANDOFF_TEMPLATE.md    <- schema template (never published, never indexed)
  INDEX.md               <- append-only history table
  CURRENT_HANDOFF.md     <- always the latest published handoff
  YYYYMMDD-HHMMSS_<agent-slug>_<task-slug>.md  <- immutable timestamped handoffs
```

## Startup process (every agent, before work)

1. Read the authority documents (`AGENTS.md`,
   `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `docs/00_AI_AGENT_START_HERE.md`,
   `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`).
2. Read `handoffs/CURRENT_HANDOFF.md`.
3. Check Git status and the current commit.
4. Check the relevant GitHub Issue.
5. Connect `fst-codegraph` and run initial context/impact queries.
6. Read direct source before editing.
7. Confirm the task is not already completed.
8. Work in Sprint Mode and Lean Mode (below).

## Publication process (after meaningful work)

1. Run the required verification for the change class (Lean Mode rules).
2. Inspect `git diff` and `git status`.
3. Update the GitHub Issue when authorized.
4. Write one complete handoff draft using `handoffs/HANDOFF_TEMPLATE.md`.
5. Publish it:

```bash
python3 FST_AI/tools/publish_handoff.py \
  --draft /path/to/completed-handoff.md \
  --agent "Claude Code" \
  --model "Claude" \
  --task "Short task slug" \
  --phase "Infrastructure setup" \
  --type NORMAL \
  --corrects NONE
```

6. Confirm the receipt: timestamped file created, `CURRENT_HANDOFF.md`
   replaced atomically, exactly one `INDEX.md` entry appended.
7. Report the published handoff filename.

Every completed task ends with one handoff unless the agent made no repository
change and produced no meaningful investigation result.

## Append-only policy

- Timestamped handoff files are **immutable** after publication: never edit,
  overwrite, rename, or delete them.
- `INDEX.md` is append-only: never edit, reorder, or delete history lines.
  Each publication appends exactly one line.
- `CURRENT_HANDOFF.md` is a normal Markdown copy (not a symlink), replaced
  atomically only by the publisher.
- Do not fix a historical typo in place. Publish a correction handoff instead.

## Correction policy

When an old handoff is incorrect:

- Never edit it.
- Create a new handoff with type `CORRECTION` or `VERIFICATION`.
- Set `Corrects Handoff` to the historical filename.
- Explain the incorrect claim and provide new evidence.
- Append one new index line; `CURRENT_HANDOFF.md` becomes the new handoff.
- A correction handoff does not erase history.

## GitHub Issues relationship

- GitHub Issues are the task queue.
- A handoff records one task's outcome and the single next action; it is not a
  task queue.
- Other future tasks belong in GitHub Issues, not in a handoff.

## Sprint Mode

- One narrowly defined task per agent run.
- One accountable agent at a time.
- One active GitHub Issue when available.
- One smallest safe change surface.
- One primary next action.
- One handoff at task completion.
- No opportunistic refactor, no unrelated cleanup.
- Stop after acceptance evidence is obtained.

## Lean Mode

- Documentation/tooling/handoff/agent-routing changes: validate only the
  changed tooling and document structure, inspect the Git diff, and do not
  rerun the full Xcode suite unless production behavior may have changed.
- Production Swift changes: run the most relevant targeted tests, and one full
  canonical test pass before the final handoff when the change touches
  transfer, verification, state, cancellation, report safety, bundled rsync,
  source access, release behavior, or another safety-critical path. Do not
  repeat identical full test runs without new code changes or a specific
  failure reason.
- UI-only low-risk changes: targeted build/tests plus one relevant UI
  verification; full suite only when dependencies or behavior warrant it.
- Never reduce testing below what is required to establish safety.

## Validation expectations

- The publisher (`FST_AI/tools/publish_handoff.py`) validates all required
  headings, the `Single Next Action` section, and the `Resume Prompt`; refuses
  to overwrite an existing timestamped handoff; locks `INDEX.md` during append
  (`fcntl.flock`); flushes and `fsync`s files; supports `--dry-run`,
  `--verify`, and correction metadata; never runs Git mutations; never touches
  application source.
- The agent writes the technical content. The tool never constructs technical
  claims.

## Emergency / manual publication

If the publisher is unavailable (no Python, tool corrupted, or blocked):

1. Copy `handoffs/HANDOFF_TEMPLATE.md` and fill every section honestly.
2. Name the file `handoffs/<YYYYMMDD-HHMMSS>_<agent>_<task>.md` using the
   current Asia/Bangkok time.
3. Copy the identical content to `handoffs/CURRENT_HANDOFF.md`.
4. Append one line to `handoffs/INDEX.md` using the documented table format.
5. Record in the handoff itself that publication was manual and why.
6. Repair the publisher and re-run `--verify` at the earliest opportunity.

## Rollback procedure

Rollback removes only the Handoff System; application source is untouched:

1. Keep all timestamped handoff files — they are immutable evidence.
2. Optionally restore the previous `CURRENT_HANDOFF.md` from the prior
   timestamped handoff (copy, never symlink).
3. If the system must be dismantled, move the whole `handoffs/` directory to a
   timestamped backup path instead of deleting it.
4. Remove the handoff routing sections from `AGENTS.md`, `CLAUDE.md`,
   `.agents/rules/fst-codegraph.md`, and
   `FST_AI/memory/CODEGRAPH_OPERATING_RULES.md`.
5. Keep `FST_AI/tools/publish_handoff.py` or archive it with the backup.
6. Update memory files to record the change. Never delete history.

## Publisher command reference

```bash
python3 FST_AI/tools/publish_handoff.py \
  --draft <completed-handoff.md> \
  --agent "<Agent Host>" \
  --model "<model or UNVERIFIED>" \
  --task "<task slug>" \
  --phase "<phase>" \
  --type NORMAL|CORRECTION|VERIFICATION|BLOCKED \
  --corrects <filename>|NONE \
  [--dry-run] [--verify]
```

Run `python3 FST_AI/tools/publish_handoff.py --help` for the full interface.
