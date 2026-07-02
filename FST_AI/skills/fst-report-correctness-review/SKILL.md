---
name: fst-report-correctness-review
description: Review whether FST report output truthfully matches canonical job state, copy result, verify result, errors, warnings, and SAFE TO EJECT decision.
---

# SKILL: fst-report-correctness-review

## Role

Use this skill to review the correctness of generated FST reports against canonical job state and runtime evidence.

Primary reviewer: Claude.
Primary implementer: Codex.
Final safety gate: Mi.

## Use When

Use this skill when reviewing:

- report output samples
- report builder changes
- report formatting changes
- report field mapping
- report final status
- report safety decision
- report warning/error sections
- report skipped item sections
- report summary wording

## Core Principle

The report must tell the truth.

The report must match canonical final state, not UI optimism, partial state, stale state, or inferred success.

## Required Comparison

Compare report output against:

- canonical final job state
- copy result
- verify result
- rsync exit code
- cancellation status
- source changed status
- mismatch status
- warning list
- error list
- skipped item list
- SAFE TO EJECT decision

## Hard Blocks

Reject if report:

- Says SAFE TO EJECT YES when canonical state says blocked.
- Says copy success when rsync failed.
- Says verify success when verify failed/incomplete.
- Omits cancellation.
- Omits source changed.
- Omits fileCountMismatch.
- Omits blocking errors.
- Omits skipped items that affect safety.
- Uses vague success wording for uncertain state.
- Conflicts with UI final state.
- Conflicts with internal state.
- Is generated before final state is settled.

## Field Mapping Checks

Check:

- Is Copy Result mapped from canonical copy result?
- Is Verify Result mapped from canonical verify result?
- Is Safety Decision mapped from canonical safety decision?
- Are warnings copied into report?
- Are errors copied into report?
- Are skipped items copied into report?
- Are source and destination paths correct?
- Is timestamp correct?
- Is tool/rsync version correct?
- Is job identity stable?
- Are byte/file counts consistent?

## Human Readability Checks

Report should be readable by:

- DIT
- Data Wrangler
- Producer
- Post Producer
- Assistant Editor
- Future operator reviewing evidence

Avoid vague phrases:

- probably copied
- looks good
- should be okay
- no obvious issue
- likely safe

Prefer explicit phrases:

- Copy Result: Passed / Failed / Cancelled
- Verify Result: Passed / Failed / Not Run / Cancelled / Incomplete
- SAFE TO EJECT: YES / NO
- Reason: ...

## Output Format

Verdict:
Accept / Accept with risk / Reject

Report correctness impact:
none / low / medium / high

Canonical state match:
pass / concern / fail

Safety Decision match:
pass / concern / fail

Missing evidence:

Contradictory wording:

Must fix before merge:

Recommended Codex revision prompt:

Required report samples:

Notes for Mi:

## Self-Check

Before finishing, confirm:

- Report matches canonical state.
- Report does not infer success.
- Report does not hide uncertainty.
- SAFE TO EJECT field is explicit.
- Human operator can understand what happened.

