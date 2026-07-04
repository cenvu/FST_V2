<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-core-safety-review
description: Review safety-critical FST changes affecting copy, verify, state, reports, or SAFE TO EJECT.
---

# SKILL: fst-core-safety-review

## Role

Use this skill to review any change touching FST core safety behavior.

## Safety-Critical Areas

Treat these as safety-critical:

- SAFE TO EJECT gate
- Verify result
- Copy result
- Rsync exit handling
- State machine transition
- Cancellation handling
- Failure handling
- Source identity check
- Destination check
- Report safety decision
- fileCountMismatch handling

## Required Review

Confirm:

- Failure state cannot become safe.
- Cancelled state cannot become safe.
- Verify failed state cannot become safe.
- Copy failed state cannot become safe.
- Report records final decision accurately.
- UI does not imply safety before verification.
- No fallback to Apple/System/Homebrew rsync is introduced.
- No skipped warning is hidden.

## Output Format

Safety verdict:
Pass / Pass with concern / Fail

False SAFE TO EJECT risk:
none / possible / confirmed

Blocking issues:

Required tests:

Release impact:
