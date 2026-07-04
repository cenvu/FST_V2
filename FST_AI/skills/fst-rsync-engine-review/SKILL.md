<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-rsync-engine-review
description: Review FST rsync engine behavior, bundled rsync usage, source safety, destructive flag risks, and progress output handling.
---

# SKILL: fst-rsync-engine-review

## Role

Use this skill to review any FST change touching rsync execution, rsync arguments, process handling, progress output, transfer completion detection, or rsync-related error handling.

Primary reviewer: Claude.
Primary implementer: Codex.
Final safety gate: Mi.

## Use When

Use this skill when a change touches:

- RsyncEngine
- TransferEngine rsync integration
- rsync binary path
- bundled rsync validation
- rsync arguments
- process launch
- process termination
- stdout/stderr parsing
- progress output
- rsync exit code handling
- copy completion detection
- transfer cancellation
- source/destination path handling
- rsync-related report fields

## Project Context

FST must use bundled rsync 3.4.4 only.

Apple system rsync fallback is not allowed.

FST treats source media as read-only operational media.

The source volume must never be mutated, deleted, formatted, renamed, chmodded, chowned, or cleaned up by FST.

## Review Priority

Review in this order:

1. Source safety
2. Bundled rsync 3.4.4 enforcement
3. No Apple rsync fallback
4. No destructive rsync flags
5. Correct path handling
6. Correct process lifecycle handling
7. Correct exit-code interpretation
8. Correct progress parsing handoff
9. Correct cancellation behavior
10. Correct report evidence

## Hard Blocks

Reject the change if it introduces:

- Apple system rsync fallback
- `--delete`
- `--delete-before`
- `--delete-after`
- `--delete-during`
- `--remove-source-files`
- `--inplace` without explicit approved design
- Any source-mutating option
- Any source-deleting option
- Any hidden cleanup behavior
- Any behavior that treats rsync partial success as full success
- Any path construction that can target the wrong source or destination
- Any copy success path without exit status validation

## Required Checks

Check:

- Is the bundled rsync path validated?
- Is rsync version expected to be 3.4.4?
- Is Apple `/usr/bin/rsync` impossible to use accidentally?
- Are source and destination paths correctly quoted/escaped/passed as arguments?
- Are source paths treated read-only?
- Are destination writes expected and scoped?
- Is rsync launched without shell injection risk?
- Are stdout/stderr handled without blocking?
- Is process termination handled?
- Is cancellation handled?
- Are non-zero exit codes mapped correctly?
- Are partial transfers distinguished from complete transfers?
- Does report output record rsync failure accurately?
- Does UI have enough state to avoid appearing stuck?

## Progress Output Checks

Check whether:

- rsync output is parsed consistently.
- progress parser receives enough data.
- large-file and many-small-file cases are supported.
- stale progress can be detected.
- per-file progress is not confused with whole-job progress.
- rsync completion transitions the job state correctly.

## Cancellation Checks

Verify:

- Cancel sends the intended process termination signal.
- Cancelled jobs do not become complete.
- Cancelled jobs do not become SAFE TO EJECT.
- Cancelled reports are marked cancelled.
- Partial destination data is not misrepresented as verified.

## Output Format

Verdict:
Accept / Accept with risk / Reject

Rsync safety impact:
none / low / medium / high

Bundled rsync status:
pass / concern / fail

Destructive flag risk:
none / possible / confirmed

Source safety risk:
none / possible / confirmed

Process lifecycle concerns:

Progress/parser concerns:

Cancellation concerns:

Must fix before merge:

Recommended Codex revision prompt:

Runtime QA required:

Notes for Mi:

## Self-Check

Before finishing, confirm:

- No destructive source behavior was accepted.
- No Apple rsync fallback was accepted.
- No false copy success path was accepted.
- No SAFE TO EJECT path can result from rsync failure or cancellation.

