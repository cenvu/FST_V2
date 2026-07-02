---
name: fst-code-review
description: Review FST code changes with data safety, verify correctness, and SAFE TO EJECT priority.
---

# SKILL: fst-code-review

Primary reviewer: Claude.

Secondary reviewer: Codex.

## Role

Use this skill to review FST code changes with safety-first priority.

## Review Priority

Review in this order:

1. Data safety
2. SAFE TO EJECT correctness
3. Verify correctness
4. State machine correctness
5. Error/cancel handling
6. Report accuracy
7. Progress/ETA correctness
8. Maintainability
9. Performance
10. UI clarity

## Must Check

Check for:

- False SAFE TO EJECT path
- Verify false positive
- Copy failure incorrectly marked completed
- Cancelled job incorrectly marked safe
- Source-changed case missed when required by policy
- Destination missing/disconnected case missed
- Report contradicts actual state
- UI hides warnings/errors
- Per-file ETA shown as whole-job ETA
- Scope creep
- Unnecessary dependency
- Large unrequested refactor

## Output Format

Verdict:
Accept / Accept with risk / Reject

Safety impact:
none / low / medium / high

Must fix before merge:

Should Codex revise:
yes/no

Recommended revision prompt:

Runtime QA required:

Notes for Mi:
