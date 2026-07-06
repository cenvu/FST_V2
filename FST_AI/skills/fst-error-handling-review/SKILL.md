<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-error-handling-review
description: Review FST error handling, cancellation, recovery, user-visible warnings, and preservation of failure evidence.
---

# Skill: fst-error-handling-review

## Purpose

Review whether errors, warnings, cancellation, and recovery preserve safety evidence.

## When to Use

Use when a change touches error mapping, thrown errors, warnings, cancellation, retry/reset, destination disconnect, permissions, rsync failure, verify failure, report failure, or UI warning banners.

## Owner Agent

Claude reviews. Codex or Antigravity implements depending on layer. Mi gates safety-sensitive outcomes.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `docs/02_FST_TECHNICAL_GUIDE.md`

## Inputs

- Diff.
- Error/cancel scenarios.
- Logs or report samples.
- UI state notes if relevant.

## Safety Boundaries

- Errors that affect copy, verify, report, or SAFE TO EJECT must not be swallowed.
- Failure and cancellation must block SAFE TO EJECT.
- Warnings must not hide blocking errors.

## Procedure

1. Identify error sources and affected phase.
2. Confirm blocking errors stay blocking.
3. Confirm cancellation is distinct from completion.
4. Confirm errors are visible to operator and report/log.
5. Check retry/reset does not reuse stale success state.

## Required Checks

- Non-zero rsync exit cannot become success.
- Verify error cannot become verify pass.
- Destination disconnect cannot become success.
- Permission denied is not warning-only when blocking.
- Report-write failure does not hide copy/verify failure.
- UI buttons recover safely after error.

## Output Format

Verdict:

Error safety impact:

Swallowed error risk:

User visibility:

Report visibility:

Required fix:

## Stop / Escalate If

- Error state can transition to SAFE TO EJECT without successful retry and verify.
- UI hides blocking errors.
- Report omits blocking errors.

## Do Not

- Use silent `catch {}` for safety-impacting failures.
- Convert blocking errors into cosmetic warnings.
