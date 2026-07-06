<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-state-machine-review
description: Review FST transfer state transitions, terminal states, cancellation, failure handling, and SAFE TO EJECT gating.
---

# Skill: fst-state-machine-review

## Purpose

Review state transitions so UI, report, and SAFE TO EJECT derive from canonical backend truth.

## When to Use

Use when a change touches TransferState, job state, copy/verify lifecycle, cancellation, failure, completion, report state mapping, UI state model, or SAFE TO EJECT decision.

## Owner Agent

Claude reviews. Codex implements. Mi gates.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `docs/02_FST_TECHNICAL_GUIDE.md`

## Inputs

- Diff.
- State transition description.
- Terminal states.
- Error/cancel scenarios.
- Report/UI mapping.

## Safety Boundaries

- Only valid copy success plus verification pass may allow SAFE TO EJECT.
- Failure, cancellation, incomplete, or unknown state must not become safe.
- Stale progress must not affect state truth.

## Procedure

1. Identify changed states and transitions.
2. Check terminal and recoverable states.
3. Check copy-to-verify and verify-to-complete transitions.
4. Check cancel/failure race conditions.
5. Check report and UI derive from final canonical state.

## Required Checks

- Failure cannot transition to SAFE TO EJECT.
- Cancellation cannot transition to SAFE TO EJECT.
- Verify failure cannot transition to completed.
- Copy failure cannot enter verify without approved recovery policy.
- Unknown state is not success.
- Report generation waits for settled final state.

## Output Format

Verdict:

State safety impact:

False SAFE TO EJECT risk:

Race risks:

Required fix:

Runtime QA:

## Stop / Escalate If

- State semantics are unclear.
- Async race can overwrite terminal state.
- UI/report can show success while backend failed/cancelled.

## Do Not

- Add or rename states without explicit spec update.
- Let UI actions alone decide workflow state.
