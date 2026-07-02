---
name: fst-error-handling-review
description: Review FST error handling, cancellation, recovery, user-visible warnings, and preservation of failure evidence.
---

# SKILL: fst-error-handling-review

## Role

Use this skill to review error handling across FST copy, verify, report generation, UI state, and cancellation flows.

Primary reviewer: Claude.
Primary implementer: Codex or Antigravity/Gemini depending on affected layer.
Final safety gate: Mi.

## Use When

Use this skill when a change touches:

- error mapping
- thrown errors
- result enums
- warning handling
- cancellation
- retry/reset behavior
- destination disconnected behavior
- permission errors
- rsync failure handling
- verify failure handling
- report generation failure
- user-visible error messages
- UI warning banners

## Core Principle

Errors are safety evidence.

FST must preserve, surface, and report errors clearly.

No error that affects copy, verify, or SAFE TO EJECT may be swallowed.

## Review Priority

Review in this order:

1. Errors that affect safety are preserved
2. Failures block SAFE TO EJECT
3. Cancellations block SAFE TO EJECT
4. Errors are visible to operator
5. Errors are recorded in report
6. Recovery/reset is explicit
7. Retry does not reuse unsafe stale state
8. UI does not hide blocking errors
9. Logs are useful for diagnosis
10. Maintainability

## Hard Blocks

Reject the change if:

- Safety-impacting errors are swallowed.
- Non-zero rsync exit becomes success.
- Verify error becomes verify pass.
- Report generation failure hides copy/verify failure.
- Cancellation becomes completion.
- Destination disconnected becomes success.
- Permission denied becomes warning-only when it blocks copy/verify.
- UI hides blocking error.
- Report omits blocking error.
- Retry preserves stale success state.
- Error state can transition to SAFE TO EJECT without successful retry and verify.

## Required Checks

Check:

- Are error types specific enough?
- Are errors mapped to correct phase?
- Are warnings distinct from blocking errors?
- Are cancellation errors distinct from failures?
- Are user-facing messages accurate?
- Are technical details preserved for report/log?
- Are errors available to Claude/Mi for QA review?
- Are destination disconnects handled?
- Are permission errors handled?
- Are file-system errors handled?
- Are report-write failures handled?
- Are UI buttons disabled/enabled correctly after error?
- Can operator retry safely?
- Can operator reset safely?

## Warning vs Error Rules

Use warning when:

- Issue is non-blocking.
- Copy and verify remain valid.
- Report records it clearly.
- SAFE TO EJECT remains justified.

Use error when:

- Copy failed.
- Verify failed.
- Source changed.
- Destination missing/disconnected.
- Required file missing.
- Required check incomplete.
- Cancellation occurred.
- Report cannot record final safety decision.

## Output Format

Verdict:
Accept / Accept with risk / Reject

Error safety impact:
none / low / medium / high

Swallowed error risk:
none / possible / confirmed

User visibility:
pass / concern / fail

Report visibility:
pass / concern / fail

Recovery/retry risk:
none / possible / confirmed

Must fix before merge:

Recommended Codex or Antigravity revision prompt:

Runtime QA required:

Notes for Mi:

## Self-Check

Before finishing, confirm:

- Blocking errors remain blocking.
- Cancellations remain unsafe.
- Errors are visible in UI and report.
- Retry/reset cannot reuse stale success.
- Operator will not be misled.

