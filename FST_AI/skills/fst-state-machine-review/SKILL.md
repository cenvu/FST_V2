---
name: fst-state-machine-review
description: Review FST transfer state machine transitions, terminal states, cancellation, failure handling, and SAFE TO EJECT gating.
---

# SKILL: fst-state-machine-review

## Role

Use this skill to review any FST change touching state transitions, transfer lifecycle, verify lifecycle, terminal states, cancellation, failure handling, or SAFE TO EJECT gating.

Primary reviewer: Claude.
Primary implementer: Codex.
Final safety gate: Mi.

## Use When

Use this skill when a change touches:

- Transfer state
- Job state
- StateMachine
- Copy phase transitions
- Verify phase transitions
- Cancel behavior
- Failure behavior
- Completion behavior
- SAFE TO EJECT decision
- UI state model
- Report state mapping

## Core Principle

State must represent truth.

UI, report, and SAFE TO EJECT decision must derive from real backend state, not optimistic assumptions.

## Expected State Categories

FST should clearly distinguish:

- Idle
- Source selected
- Destination selected
- Ready
- Copying
- Copy failed
- Copy cancelled
- Copy completed
- Verifying
- Verify failed
- Verify cancelled
- Verify completed
- Report generated
- Completed
- SAFE TO EJECT allowed
- SAFE TO EJECT blocked

Exact enum names may differ, but these semantic states must not be collapsed unsafely.

## Review Priority

Review in this order:

1. No false SAFE TO EJECT
2. Terminal state correctness
3. Failure state correctness
4. Cancellation state correctness
5. Copy-to-verify transition correctness
6. Verify-to-complete transition correctness
7. Report state correctness
8. UI state mapping correctness
9. Retry/reset behavior
10. Maintainability

## Hard Blocks

Reject the change if:

- Failure can transition to SAFE TO EJECT.
- Cancellation can transition to SAFE TO EJECT.
- Verify failure can transition to completed.
- Copy failure can transition to verifying without explicit recovery policy.
- UI can display completed while backend is failed/cancelled.
- Report can say success while state is failed/cancelled.
- Unknown state is treated as success.
- State transitions bypass verify.
- State transition depends only on UI action rather than core result.

## Required Checks

Check:

- What states are terminal?
- What states are recoverable?
- What states allow retry?
- What states allow reset?
- What states allow report generation?
- What states allow SAFE TO EJECT?
- Can copy failure transition to verify?
- Can verify failure transition to completed?
- Can cancel race with completion?
- Can rsync process exit after cancel and mark success?
- Can stale progress affect state?
- Are async updates ordered safely?
- Are UI states derived from canonical state?
- Are reports derived from final canonical state?

## Race Condition Checks

Check for:

- Cancel at same time as rsync completion.
- Verify finishing after user cancel.
- Progress update arriving after terminal state.
- Report generation starting before final state is settled.
- UI state showing old success after new failure.
- Multiple state updates from background tasks.

## Output Format

Verdict:
Accept / Accept with risk / Reject

State safety impact:
none / low / medium / high

False SAFE TO EJECT risk:
none / possible / confirmed

Invalid transition risk:
none / possible / confirmed

Race condition risk:
none / possible / confirmed

Must fix before merge:

Recommended Codex revision prompt:

Runtime QA required:

Notes for Mi:

## Self-Check

Before finishing, confirm:

- Failure states cannot become SAFE TO EJECT.
- Cancelled states cannot become SAFE TO EJECT.
- Verify is required before SAFE TO EJECT.
- UI/report cannot contradict final canonical state.
- Async updates cannot overwrite terminal failure/cancel states.

