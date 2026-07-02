---
name: fst-ui-state-review
description: Review whether FST UI states accurately reflect backend copy, verify, progress, error, and safety states.
---

# SKILL: fst-ui-state-review

## Role

Use this skill to review whether UI states correctly reflect FST core states.

## Check States

Review UI for:

- Idle
- Source selected
- Destination selected
- Ready to copy
- Copying
- Copy failed
- Verifying
- Verify failed
- Cancelled
- Completed
- SAFE TO EJECT allowed
- SAFE TO EJECT blocked

## Must Check

- Buttons enabled/disabled correctly.
- Errors are visible.
- Warnings are visible.
- Safety decision is visible.
- ETA label is not misleading.
- Current phase is clear.
- Report availability is clear.
- Failed state does not look successful.

## Output Format

UI state verdict:
Pass / Pass with concern / Fail

Incorrect states:

Missing warnings:

Misleading wording:

Recommended fix:
