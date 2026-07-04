<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-verify-engine-review
description: Review FST verify engine behavior, copy verification correctness, mismatch handling, source identity checks, and false-pass risks.
---

# SKILL: fst-verify-engine-review

## Role

Use this skill to review any FST change touching verify behavior, verification result classification, mismatch handling, source/destination comparison, or verify-related SAFE TO EJECT decisions.

Primary reviewer: Claude.
Primary implementer: Codex.
Final safety gate: Mi.

## Use When

Use this skill when a change touches:

- VerifyEngine
- verification service
- file count checks
- file size checks
- hash/checksum checks if present
- source changed detection
- destination missing detection
- skipped item handling
- verify pass/fail classification
- verify report fields
- SAFE TO EJECT decision inputs

## Core Principle

Verify must never false-pass.

A false verify pass can lead to unsafe media handling.

If verification is uncertain, incomplete, interrupted, cancelled, or inconsistent, the result must not be treated as verified.

## Review Priority

Review in this order:

1. False-pass prevention
2. Source identity correctness
3. Destination completeness
4. File count correctness
5. File size/hash correctness according to current policy
6. Mismatch classification
7. Skipped item handling
8. Cancel/failure behavior
9. Report accuracy
10. UI state clarity

## Hard Blocks

Reject the change if it allows:

- Verify failure to become verify pass.
- Cancelled verify to become verify pass.
- Incomplete verify to become verify pass.
- Source changed case to become verify pass.
- Missing destination to become verify pass.
- fileCountMismatch to become SAFE TO EJECT without explicit approved policy.
- Skipped files to be hidden from report.
- Verify error to be swallowed.
- Unknown state to be treated as success.

## Required Checks

Check:

- How is the source enumerated?
- How is the destination enumerated?
- Are package directories handled consistently?
- Are hidden files handled consistently?
- Are skipped files recorded?
- Are file counts compared correctly?
- Are byte sizes compared correctly?
- Are checksums/hashes used or explicitly not used?
- Is source identity captured before and after copy/verify?
- Is source changed detection implemented?
- Are verify errors surfaced?
- Is cancellation supported?
- Is verify work off the MainActor/UI thread?
- Is verify result recorded in report?
- Does SAFE TO EJECT depend on verify pass?

## fileCountMismatch Checks

When fileCountMismatch appears, verify:

- The mismatch source is identified.
- Hidden/system files are considered.
- macOS package/directory behavior is considered.
- Excluded/skipped items are considered.
- rsync itemization behavior is considered.
- The mismatch is not ignored silently.
- The report includes mismatch evidence.
- SAFE TO EJECT is blocked unless policy explicitly allows otherwise.

## Source Changed Checks

Confirm:

- Source identity is captured.
- Source is not mutated by FST.
- Source change after copy is detected.
- Source change blocks verify pass or marks verify uncertain according to policy.
- Report records source-changed condition.

## Output Format

Verdict:
Accept / Accept with risk / Reject

Verify safety impact:
none / low / medium / high

False-pass risk:
none / possible / confirmed

Mismatch handling:
pass / concern / fail

Source changed handling:
pass / concern / fail

MainActor/UI blocking risk:
none / possible / confirmed

Must fix before merge:

Recommended Codex revision prompt:

Runtime QA required:

Notes for Mi:

## Self-Check

Before finishing, confirm:

- No uncertain verify path is accepted as pass.
- No verify failure can produce SAFE TO EJECT.
- fileCountMismatch is not hidden.
- Source changed behavior is explicit.
- Verify does not freeze UI.

