---
name: fst-diagnose-bug
description: Diagnose FST bugs using evidence-first debugging before implementation.
---

# SKILL: fst-diagnose-bug

Inspired by disciplined debugging workflows and small-step engineering practices.

## Role

Use this skill to diagnose FST bugs before implementing fixes.

## Use When

Use this skill when:

- App appears stuck.
- Progress is not updating.
- ETA is wrong.
- Copy does not complete.
- Verify fails unexpectedly.
- fileCountMismatch appears.
- Report output is incorrect.
- SAFE TO EJECT state is wrong.
- UI state does not match core state.

## Do Not

Do not:

- Implement immediately without diagnosis.
- Rewrite a subsystem without evidence.
- Add dependencies.
- Change UI to hide a core bug.
- Treat symptoms as root cause.
- Change SAFE TO EJECT logic without explicit review.

## Diagnosis Categories

Classify the bug as one or more:

- Rsync process issue
- Progress parser issue
- ETA aggregation issue
- Transfer state issue
- Verify engine issue
- State machine issue
- Report generation issue
- UI presentation issue
- Threading/main-thread issue
- File system/permissions issue

## Required Process

1. Restate the observed behavior.
2. Identify expected behavior.
3. List affected phase: Copy / Verify / Report / UI / Safety.
4. Identify likely root causes.
5. Identify evidence needed.
6. Locate likely files.
7. Propose smallest safe fix.
8. List tests or runtime checks.
9. State safety impact.

## Output Format

Diagnosis:

Expected behavior:

Likely root cause:

Evidence needed:

Files to inspect:

Smallest safe fix:

Safety impact:

Runtime QA:
