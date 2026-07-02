---
name: fst-detailed-txt-report
description: Guide implementation and review of FST Detailed TXT Report V1 with operational evidence and safety decision fields.
---

# SKILL: fst-detailed-txt-report

## Role

Use this skill to implement or review FST Detailed TXT Report V1.

Primary implementer: Codex.
Primary reviewer: Claude.
Final safety gate: Mi.

## Use When

Use this skill when a change touches:

- TXT report generation
- report schema
- report output fields
- copy result reporting
- verify result reporting
- warning/error reporting
- skipped item reporting
- SAFE TO EJECT decision reporting
- report file naming
- report storage location
- report generation timing

## Core Principle

The report is operational evidence.

It must accurately record what happened, what passed, what failed, what was skipped, and whether the media is SAFE TO EJECT.

The report must never make an unsafe or uncertain job look successful.

## Required Sections

Detailed TXT Report V1 should include:

1. Operator Summary
2. Job Identity
3. Source
4. Destination
5. Copy Result
6. Verify Result
7. Progress/Transfer Summary if available
8. Safety Decision
9. Warnings
10. Errors
11. Skipped Items
12. Timing
13. Tooling / rsync version
14. Final Status

## Required Safety Decision Fields

Report must explicitly include:

- SAFE TO EJECT: YES / NO
- Reason
- Copy result
- Verify result
- Source changed status
- Mismatch status
- Cancellation status
- Failure status
- Warnings count
- Errors count

## Success Report Requirements

A success report must show:

- Copy completed successfully.
- Verify completed successfully.
- No blocking mismatch.
- No cancellation.
- No failure.
- Source identity is unchanged or policy-compliant.
- SAFE TO EJECT is YES.
- rsync/tooling info is recorded.

## Failure Report Requirements

A failure report must show:

- Which phase failed.
- Why it failed if known.
- Whether copy was partial.
- Whether verify was skipped, failed, or incomplete.
- SAFE TO EJECT is NO.
- Error details are preserved.
- Warnings are visible.

## Cancel Report Requirements

A cancelled report must show:

- Operator cancellation occurred.
- Phase where cancellation occurred.
- Copy/verify did not complete.
- SAFE TO EJECT is NO.
- Partial destination data may exist.
- Operator should not treat destination as verified.

## Source Changed Report Requirements

A source-changed report must show:

- Source changed or source identity mismatch.
- When it was detected.
- What result was affected.
- SAFE TO EJECT is NO unless a future explicit approved policy says otherwise.

## Review Priority

Review in this order:

1. Safety Decision correctness
2. Copy/verify accuracy
3. Failure/cancel accuracy
4. Warning/error visibility
5. Skipped item visibility
6. Source/destination identity
7. Tooling evidence
8. Timing evidence
9. Human readability
10. Maintainability

## Hard Blocks

Reject the change if:

- Report can say SAFE TO EJECT YES after failure.
- Report can say SAFE TO EJECT YES after cancellation.
- Report can hide verify failure.
- Report can hide fileCountMismatch.
- Report can omit Safety Decision.
- Report contradicts canonical state.
- Report uses vague success language for uncertain state.
- Report is generated before final state is settled.
- Report omits errors/warnings that affected safety.

## Output Format

Verdict:
Accept / Accept with risk / Reject

Report safety impact:
none / low / medium / high

Safety Decision correctness:
pass / concern / fail

Missing required fields:

Contradictions:

Must fix before merge:

Recommended Codex revision prompt:

Runtime QA/report samples required:

Notes for Mi:

## Self-Check

Before finishing, confirm:

- The report can be used as operator evidence.
- Failed/cancelled/incomplete jobs are clearly unsafe.
- SAFE TO EJECT is explicit.
- Warnings/errors/skipped items are visible.
- Report state matches canonical final state.

