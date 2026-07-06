<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-runtime-qa
description: Prepare and review runtime QA scenarios for FST copy, verify, cancel, failure, report, and safety behavior.
---

# Skill: fst-runtime-qa

## Purpose

Prepare and review runtime evidence for FST safety, progress, report, and operator feedback.

## When to Use

Use after core engine, verify, state, progress/ETA, report, permission, package, or release-sensitive changes.

## Owner Agent

Claude reviews QA completeness. Codex prepares matrices/evidence. Mi decides sufficiency.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/TASK_REGISTRY.md`
- `FST_AI/templates/runtime-qa-matrix.md`

## Inputs

- Change summary.
- Build/package identity.
- Test media description.
- Runtime logs.
- Generated report samples.
- Screenshots or operator observations when available.

## Safety Boundaries

- Destination observer and Verify ETA are UI-only.
- They must never affect copy success, verify success, report truth, or SAFE TO EJECT.
- Failure, cancellation, uncertainty, or verify failure must block SAFE TO EJECT.

## Procedure

1. Select scenarios based on changed subsystem.
2. Record source/destination size, file count, and filesystem context.
3. Run success, copy failure, verify failure, cancel during copy, cancel during verify, destination disconnect, large file, many-small-files, and report cases when applicable.
4. Compare UI terminal state, report, and logs.
5. Mark blocking issues before release.

## Required Checks

- Successful copy + verify.
- Copy failure.
- Verify failure.
- Cancel during copy.
- Cancel during verify.
- Destination disconnected.
- Source changed when policy applies.
- Report after success/failure/cancel.
- SAFE TO EJECT blocked cases.

## Output Format

Runtime QA matrix:

Pass/fail summary:

Blocking issues:

Evidence gaps:

Release recommendation:

## Stop / Escalate If

- UI freezes during long work.
- SAFE TO EJECT is shown after failure/cancel/uncertainty.
- Report contradicts final state.
- Runtime evidence is too incomplete for release.

## Do Not

- Treat UI progress, observer metrics, or ETA as safety evidence.
- Skip failure/cancel cases for release-sensitive work.
