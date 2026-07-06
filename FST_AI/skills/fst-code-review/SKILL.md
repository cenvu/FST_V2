<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-code-review
description: Review FST code changes with data safety, verify correctness, and SAFE TO EJECT priority.
---

# Skill: fst-code-review

## Purpose

Review FST changes for safety, correctness, maintainability, and operator truth.

## When to Use

Use for general code or docs review when no narrower review skill is enough.

## Owner Agent

Claude is primary reviewer. Codex may perform secondary review. Mi gates safety-sensitive decisions.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/TASK_REGISTRY.md`
- `docs/00_AI_AGENT_START_HERE.md`

## Inputs

- Diff or changed files.
- Implementation summary.
- Tests/checks run.
- Known risks.

## Safety Boundaries

- No false SAFE TO EJECT path.
- No source media mutation.
- No Apple/System/Homebrew/MacPorts rsync fallback.
- UI estimates must not become safety truth.

## Procedure

1. Identify affected layer and safety surface.
2. Check data safety before maintainability.
3. Check failure/cancel/verify/report truth.
4. Check scope creep and unnecessary dependencies.
5. Recommend specific revision or approval.

## Required Checks

- Copy failure cannot become complete.
- Cancelled job cannot become safe.
- Verify false positive is not introduced.
- Report does not contradict actual state.
- UI does not hide warnings/errors.
- Per-file ETA is not shown as whole-job ETA.

## Output Format

Verdict:
Accept / Accept with risk / Reject

Safety impact:
none / low / medium / high

Must fix before merge:

Should Codex revise:

Runtime QA required:

Notes for Mi:

## Stop / Escalate If

- Safety behavior is uncertain.
- Review lacks enough evidence.
- Change touches SAFE TO EJECT, verify, rsync, cancellation, or report truth.

## Do Not

- Approve broad refactors without need.
- Treat passing UI progress as copy/verify evidence.
- Review a risky change only by the agent that implemented it.
