<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-small-safe-change
description: Implement an already-scoped FST code, tooling, or documentation change with the smallest safe diff, targeted verification, and a clear stop condition.
---

# Skill: fst-small-safe-change

## Purpose

Keep FST changes small, safe, scoped, and easy to review.

## When to Use

Use for bug fixes, safety-critical changes, progress/ETA changes, verify logic, report logic, docs cleanup, or UI changes that could affect operator confidence.

## Owner Agent

Codex applies for core/docs. Antigravity applies for UI. Claude reviews risk. Mi gates scope.

## Required Startup Context

- `AGENTS.md` L0 kernel and the HOT header of `handoffs/CURRENT_HANDOFF.md`.
- Fresh Git/worktree/upstream state and the matching GitHub Issue.
- Targeted `TASK_REGISTRY.md` / `WORK_HISTORY.md` search for duplicate work.
- Load only direct authority, source, tests, role and skills required by the
  specific change. Load the full Command Center only for its L2 triggers.

## Inputs

- Task.
- Affected files.
- Risk classification.
- Required behavior.

## Safety Boundaries

- Do not weaken data safety for convenience.
- Do not add broad architecture unless explicitly approved.
- Do not let UI polish affect safety truth.

## Procedure

1. **AUTHORITY_DISCOVERY:** begin at the L0 kernel, current issue, and exact
   repository authority; preserve UNKNOWN and existing dirty state.
2. **CURRENT_HANDOFF:** read HOT first and open only the relevant section or
   referenced evidence.
3. **FRESH_GIT:** inspect branch, `HEAD`, worktree, and upstream; fetch before
   comparing remote state and fast-forward only a clean worktree.
4. **DUPLICATE_CHECK:** search matching task/history records; do not reread the
   full history. Ask before repeating a completed task.
5. **RESEARCH_FIRST_GATE:** establish project facts from canonical source;
   for external behavior use official upstream, upstream issues/discussions,
   community evidence, then a bounded experiment.
6. **SCOPE_BOUNDARY:** identify owner layer, touched paths, non-goals, and
   required evidence. State the smallest safe change before editing.
7. **SMALLEST_SAFE_CHANGE:** reuse existing tools and skills; patch only the
   justified surface; preserve all FST safety invariants.
8. **TARGETED_VERIFY:** run only checks that prove this change class. Do not
   run Xcode for a control-plane-only change unless an existing policy requires
   it or product behavior changed.
9. **POSTFLIGHT:** inspect exact diff, status, product-path diff, and required
   deterministic gates. Preserve history and unrelated state.
10. **HANDOFF:** report evidence and UNKNOWN values; propose state delta and
    exactly one next decision. Never set BRAIN-owned review/classification or
    active-next fields.
11. **STOP:** finalize through `fst-brain-return-finalizer` only after evidence
    and handoff are complete; do not continue into another task.

## Required Checks

- What safety behavior could regress?
- Can Claude review this efficiently?
- What runtime or doc check proves the fix?
- Are unrelated files untouched?

## Output Format

Smallest safe change:

Files changed:

Files intentionally not changed:

Safety risk:

Review notes:

## Stop / Escalate If

- The fix requires new policy.
- Scope expands to deferred features.
- Source safety, SAFE TO EJECT, or report truth is uncertain.

## Do Not

- Add dependency, database, cloud, multi-job, multi-destination, telemetry, analytics, new report format, or large refactor without explicit approval.
