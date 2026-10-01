# FST Handoff System

Operational continuation records shared by every coding agent: Antigravity IDE
(Gemini), Codex CLI (GPT), Claude Code (Claude), Claude Code harnesses using
DeepSeek V4 Flash, and future compatible agents.

## Purpose

A handoff records what one agent run actually did, what it verified, what
remains unknown, and one Worker-proposed next decision — so BRAIN can review
evidence without re-deriving context. Handoffs are **operational evidence and
continuation context**, not replacements for Git or GitHub Issues.

## Source-of-truth boundaries

- **Task queue:** GitHub Issues.
- **Final confirmation:** repository state, commits, tests, pull requests, and
  actual source.
- **Operational context:** `handoffs/` files. CURRENT is one project-specific
  snapshot, not a journal or active-state authority.
- **CodeGraph:** advisory index only; never replaces direct source inspection.
- **Desktop bridge:** `~/Desktop/03_FST_BRAIN.md` is a non-canonical one-file transport projection only.
- A handoff or Desktop bundle is never proof when repository evidence disagrees with it.

## Layout

```text
handoffs/
  README.md              <- this file
  HANDOFF_TEMPLATE.md    <- schema template (never published, never indexed)
  INDEX.md               <- append-only history table
  CURRENT_HANDOFF.md     <- always the latest published handoff
  YYYYMMDD-HHMMSS_<agent-slug>_<task-slug>.md  <- immutable timestamped handoffs
```

External BRAIN return projection (not part of repo history):

```text
~/Desktop/03_FST_BRAIN.md   <- the only FST Desktop file; overwritten per BRAIN return
```
## Startup process (every agent, before work)

1. Read the L0 governance/safety kernel in `AGENTS.md`.
2. Read only the HOT header of `handoffs/CURRENT_HANDOFF.md`.
3. Check Git branch, `HEAD`, worktree and configured upstream. Fetch before
   remote comparison; fast-forward only a clean worktree. Never reset, clean,
   stash, rebase or force-push to resolve drift.
4. Search GitHub Issues for the supplied task. Search relevant
   `TASK_REGISTRY.md` / `WORK_HISTORY.md` entries only to detect duplicates;
   memory is history, not active state.
5. Load the exact authority, code, tests, role and skill required by the task.
   Connect CodeGraph only for production-source work when its MCP is available;
   otherwise inspect source directly and record the unavailable tool.
6. Work in Sprint Mode and Lean Mode (below).

### Progressive disclosure

- Default context is HOT + task + direct authority references.
- `FST_AI/memory/BRAIN_OPERATOR_COMPACT.md` is the stable L1 governance layer
  for BRAIN operations.
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md` and other full project references
  are L2, loaded only for AUDIT, POLICY_AMBIGUITY, OPERATOR_REPAIR,
  GOVERNANCE_CONFLICT, RULE_PROMOTION or HIGH_RISK_ADJUDICATION.
- Load one focused L3 skill only when its specific trigger matches.
- Reuse L4 publisher/exporter/Git gates before adding a checker.
- `handoffs/CURRENT_HANDOFF.md` is a project-specific snapshot, not a journal
  or authority. GitHub/repository contents win. Timestamped handoffs are
  immutable; `INDEX.md` remains append-only.

### Handoff schema and ownership

Generic records use `HANDOFF_MARKDOWN`; FST publishes the current snapshot as
`handoffs/CURRENT_HANDOFF.md`. The current schema has a HOT header followed by
`COMPACT_REFS`, `CURRENT_STATE`, `REVIEW`, `RAW_REFS`, `REPORT`, and `NEXTSTEP`.
The HOT header carries schema/version, workstream and handoff IDs, repo/branch,
repo and remote HEAD observations, verification time, authority, state, gate,
blocker and one next decision. References resolve before report detail; raw
evidence is linked and recoverable without duplicating its body.

Workers may write raw references, report evidence, proposed state deltas and
one proposed next decision. Before BRAIN review the handoff must state
`BRAIN_REVIEW_STATUS=PENDING`, leave classification/accepted state unset, and
leave `ACTIVE_NEXT=NONE`. A Worker must not publish itself as accepted or
classify its own result. The publisher checks deterministic schema, workstream
ID, reference existence, placeholders, next-decision count, freshness-field
shape, and owner-field boundaries; it does not judge subjective acceptance or
safety. A previous BRAIN gate cannot be authenticated by the current publisher
and is rejected until canonical provenance can be validated.

After BRAIN adjudication, preserve the decision in a new record only when a
separate BRAIN-authorized task supplies canonical provenance. The current
publisher cannot authenticate a ChatGPT Web decision, so this cycle records
the exact gap and leaves the Worker handoff pending; do not simulate BRAIN
authority.

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
7. For mutating work, commit the authorized repository changes including the
   handoff, push, fetch, and verify local HEAD equals its configured upstream.
   For read-only work, verify zero mutation and current repository identity.
8. Build the single BRAIN return envelope:

```bash
python3 FST_AI/tools/export_brain_return.py \
  --task "<task>" \
  --result PASS \
  [--raw <repo-relative-evidence.md> ...]
```

   Use `--result FAIL` for a failed/blocked Worker outcome. The V2.1 packet
   includes Git and handoff gate fields. PASS is downgraded to FAIL if handoff
   verification, worktree cleanliness, upstream equality, Git observation, or
   valid/hashable BRAIN Operator snapshot is not proven.
9. Return only the compact status printed by the exporter. The last line tells
   Hùng to send `~/Desktop/03_FST_BRAIN.md` to ChatGPT Web BRAIN.

Every completed BRAIN-routed task ends with one canonical handoff and one
Desktop projection. The projection never replaces repository/GitHub truth.

## Single Desktop bridge rule

FST has exactly one authorized Agent-written Desktop path:

```text
~/Desktop/03_FST_BRAIN.md
```

Rules:

- No Agent may create, copy, export, rename, or generate any other FST file on Desktop.
- Do not manually copy a handoff, report, RAW log, prompt, or evidence file to Desktop.
- Repository artifacts remain under authorized project paths and normal Git/GitHub history.
- The Desktop file may be overwritten on the next BRAIN return; it is not immutable history.
- The Desktop file is never canonical authority. Repo/GitHub truth wins.
- The packet starts with `PACKET=FST_BRAIN_RETURN_V2_1`, preserves V2 pointers, SHA256 values, gates, explicit handoff facts, and sorted RAW metadata, then embeds exact UTF-8 `BRAIN_OPERATOR_COMPACT.md` bytes between `BRAIN_OPERATOR_BEGIN` and `BRAIN_OPERATOR_END`. Its repository path and SHA256 remain in the packet. The snapshot is fallback only; repository/GitHub content is canonical.
- `--full-report` defaults to `handoffs/CURRENT_HANDOFF.md`; its body is never embedded.
- `--raw` accepts repo-local UTF-8 evidence and records path, byte size, and SHA256 only.
- The operator snapshot is validated as UTF-8, and its SHA256 must match the canonical file and embedded bytes. Missing, unreadable, invalid UTF-8, or hash failure downgrades a PASS request to FAIL. No arbitrary byte ceiling applies to the operator snapshot.
- Explicit NOT_EXECUTED/BLOCKER lines may pass through as encoded values. The exporter does not summarize or infer handoff semantics.
- `FST_AI/tools/export_brain_return.py` intentionally has no `--output` argument and does not enumerate or clean Desktop.
- A FAIL result is still returned through `03_FST_BRAIN.md` when inputs are available, so BRAIN receives the evidence instead of forcing Hùng to hunt project files.
## Append-only policy

- Timestamped handoff files are **immutable** after publication: never edit,
  overwrite, rename, or delete them.
- `INDEX.md` is append-only: never edit, reorder, or delete history lines.
  Each publication appends exactly one line.
- `CURRENT_HANDOFF.md` is a normal Markdown snapshot (not a symlink), replaced
  atomically only by the publisher. It always equals the newest timestamped
  handoff and must not become a second journal or mutable status ledger.
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
- A handoff records one task's evidence and one Worker-proposed next decision;
  it is not a task queue or BRAIN adjudication.
- Other future tasks belong in GitHub Issues, not in a handoff.

## Sprint Mode

- One narrowly defined task per agent run.
- One accountable agent at a time.
- One active GitHub Issue when available.
- One smallest safe change surface.
- One proposed next decision; BRAIN owns the active next state.
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

- The publisher (`FST_AI/tools/publish_handoff.py`) validates the versioned
  `HANDOFF_MARKDOWN` schema; HOT/workstream/handoff identity; exactly one valid
  next decision; current reference existence; RAW byte/hash matches;
  placeholder absence; freshness-field shape; BRAIN-owned fields remain
  pending/unset; and no more than five active dead ends. Each dead end must
  match `approach|FAIL=reason|EV=repo-ref`, and its evidence ref must resolve.
- `--verify` checks CURRENT against the newest immutable handoff, the exact
  non-authoritative `current-priority.md` compatibility stub, schema validity
  for new handoffs, and exactly one last INDEX entry. Any appended live status
  text fails. Repair a projection from canonical CURRENT, never rewrite history.
- The publisher refuses to overwrite a timestamped handoff; locks `INDEX.md`
  during append (`fcntl.flock`); flushes and `fsync`s files; supports
  `--dry-run`, `--verify`, and correction metadata; never runs Git mutations;
  never touches application source.
- These are deterministic shape and integrity checks. The publisher does not
  adjudicate evidence, safety, acceptance, or BRAIN authority. The agent writes
  technical content; the tool must not construct technical claims.

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
