<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-small-safe-change
description: Keep FST changes minimal, safe, scoped, and reviewable.
---

# Skill: fst-small-safe-change

## Purpose

Keep FST changes small, safe, scoped, and easy to review.

## When to Use

Use for bug fixes, safety-critical changes, progress/ETA changes, verify logic, report logic, docs cleanup, or UI changes that could affect operator confidence.

## Owner Agent

Codex applies for core/docs. Antigravity applies for UI. Claude reviews risk. Mi gates scope.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/TASK_REGISTRY.md`

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

1. Identify the smallest surface area.
2. Confirm no new dependency or architecture is needed.
3. Patch only the relevant files.
4. Preserve existing layer boundaries.
5. List checks and remaining risks.

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
