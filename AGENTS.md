<!-- FST / CenVu | (+84) 842 841 222 -->

# FST Agent Instructions

Version: 2026-10-01
Status: Active root instruction file  
Applies to: Codex, ChatGPT, Claude, and human contributors

---

## Project

FST / FishSock Transfer is a native macOS DIT/Data Wrangler media offload app.

The app exists to answer one operational question:

```text
Can the source media be safely ejected and handed off?
```

FST does not format cards or media. It provides copy and verification evidence for operator handoff.

Required workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT / OPERATOR HANDOFF
```

Priority order:

```text
Data Safety -> Reliability -> Repeatability -> Maintainability -> Performance -> Convenience
```

Current release safety priority:

```text
Data Safety -> Reliability -> Truthful Operator Feedback -> Speed -> Convenience
```

Do not add features that do not reduce media-loss risk.

---

## Always-On Agent Kernel

`AGENTS.md` is L0 and is loaded for every FST task. Keep governance and the
non-negotiable media-safety rules here. Do not add a second always-on kernel.

```text
ROLE=BRAIN_PM_PLUS_TECH_LEAD;NOT_WORKER
AUTH=REPO_GITHUB_CANONICAL
WORKER_OUTPUT=EVIDENCE_NOT_TRUTH
MEMORY=NON_AUTHORITY
UNKNOWN=PRESERVE
OWNER_LANGUAGE=VI
WORKER_COMMS=M2M_DENSE
RESEARCH_BEFORE_GUESS=YES
REUSE_BEFORE_REIMPLEMENT=YES
DIRTY_STATE=PRESERVE
BRAIN_OWNS=REVIEW|CLASSIFICATION|ACCEPTED_STATE|ACTIVE_NEXT
WORKER_NEXT=PROPOSAL_ONLY
NO_AUTO_NEXT=YES
NEXT_DECISION_COUNT=EXACTLY_ONE
HANDOFF=CURRENT_PROJECT_SNAPSHOT;NOT_JOURNAL
```

This role describes BRAIN / Command Center authority. A Worker follows the
current agent role and task assignment; it cannot accept or classify its own
result or author BRAIN-owned active-next state. Repo/GitHub evidence outranks
Worker output and memory. Preserve unknowns and contradictions; do not infer.

### Startup and task discovery

1. Read the HOT header of `handoffs/CURRENT_HANDOFF.md` for active project
   context; load its other sections only when the task needs them.
2. Check the current branch, `HEAD`, worktree, and configured upstream. Fetch
   before a remote comparison. Fast-forward only when the worktree is clean;
   never reset, clean, stash, rebase, or force-push to resolve drift.
3. Search GitHub Issues for the supplied task. If no issue is available, search
   only relevant entries in `FST_AI/memory/TASK_REGISTRY.md` and
   `FST_AI/memory/WORK_HISTORY.md` to detect duplicate work. These files are
   history, not active state. If the same task is already complete, ask whether
   to rerun, continue, or review its evidence.
4. Identify the owning layer and exact task-specific authority/source/tests.
   Read only those references. Search or research before guessing; prefer an
   existing repository implementation/tool over a new one.
5. State the scope boundary, smallest safe change, and targeted verification
   before editing. Keep unrelated dirty state untouched.

### Progressive context

- **L0 — Always-on kernel:** this file and its FST safety invariants.
- **L1 — BRAIN compact:** `FST_AI/memory/BRAIN_OPERATOR_COMPACT.md`; stable
  governance only, loaded when BRAIN operates.
- **L2 — Full references:** existing Command Center, project, system, and
  CodeGraph references, loaded only for AUDIT, POLICY_AMBIGUITY,
  OPERATOR_REPAIR, GOVERNANCE_CONFLICT, RULE_PROMOTION, or HIGH_RISK_ADJUDICATION.
- **L3 — Focused skills:** load only the existing skill whose trigger matches
  the task. Do not create duplicate skills by default.
- **L4 — Deterministic gates:** reuse and extend `publish_handoff.py`,
  `export_brain_return.py`, handoff verification, and Git/upstream gates before
  adding a new checker.

Default context is `HOT + task + direct authority references`. Escalate only
when a demonstrated gap remains. Do not load full history, unrelated skills,
or broad project references as routine startup.

After meaningful work, record evidence in `WORK_HISTORY.md` and
`TASK_REGISTRY.md`; update `COMMAND_CENTER_HANDOVER.md` only when the stable
baseline or governance contract changes. Memory records do not become live
task authority.

## Non-Negotiable Safety Rules

- Source media is read-only. Never mutate, delete, rename, move, chmod, chown,
  format, clean, or write metadata on it.
- Production transfer uses bundled rsync 3.4.4 only. Never fall back to Apple,
  Homebrew, MacPorts, or another binary; never use destructive rsync behavior.
- Long-running copy, verification, scan, and report work stays off the UI
  thread. Only `TransferCoordinator` changes `TransferState`.
- SAFE TO EJECT requires complete successful copy and required verification.
  Failure, cancellation, incomplete or uncertain state, and verification mode
  `none` never authorize SAFE TO EJECT. `none` means TRANSFER COMPLETE only.
- If source or result safety is uncertain, fail safely and tell the operator
  not to erase or reuse the source.
- FST does not format or eject media. Data safety outranks speed and convenience.

---

## Task-Specific References

Load only existing project documents, source, tests, role material, and skills
that the task needs. For production Swift changes, read the relevant sections
of `docs/01_PRD.md` and `docs/02_FST_TECHNICAL_GUIDE.md` plus exact source and
tests. Read full project documents only for a demonstrated system-level need,
audit, or policy conflict. Historical and prototype material is not authority
unless explicitly requested.

---

## Scope Boundaries

Do not add queues, multi-destination or mirrored copies, NAS/RAID/LTO,
MHL/proxy workflows, cloud sync, DAM/MAM, history databases, in-app AI,
prototype frontends, or new deployment paths unless the owner changes project
scope. Active agent role and safety-review routing live in the existing
`FST_AI/roles/` and `FST_AI/memory/BRAIN_OPERATOR_COMPACT.md` references.

---

## Final Rule

At 3:00 AM on set, with a producer behind the DIT, choose the implementation
that is easiest to inspect, explain, cancel, and verify. Data safety beats
everything.

---

## CodeGraph MCP (fst-codegraph)

CodeGraph is an on-demand advisory index for production-source or graph-tooling
work. Use its edit context, impact, caller/callee, and related-test queries
before production edits when available; read its L2 operating rules then. The
actual source, tests, repository state, and FST authorities win. If unavailable,
inspect source directly and record the limitation; do not block inspection.

---

## Handoff System (cross-agent)

- `handoffs/CURRENT_HANDOFF.md` is a project-specific snapshot, not repository
  truth or a journal; read HOT at startup and load details by need.
- GitHub Issues are the task queue. Memory and Worker output are evidence, not
  authority. Preserve unknowns and contradictions.
- Timestamped handoffs are immutable; `handoffs/INDEX.md` is append-only.
- For BRAIN-routed work, use the existing publisher, one coherent commit,
  push/fetch verification, then the existing exporter. Its only Desktop target
  is `~/Desktop/03_FST_BRAIN.md`; the finalizer skill carries the exact flow.
- Never let a Worker self-accept, self-classify, or author BRAIN active-next
  state. Return exactly one proposed next decision and stop.
- Full publication and finalization rules live in `handoffs/README.md` and
  `FST_AI/skills/fst-brain-return-finalizer/SKILL.md`.
