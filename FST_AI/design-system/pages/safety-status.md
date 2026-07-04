<!-- FST / CenVu | (+84) 842 841 222 -->

# Design System Page Override: Safety Status

## Purpose

Safety status must clearly communicate whether the job is SAFE TO EJECT.

## Required States

The UI must support:

- Not started
- Copying
- Verifying
- SAFE TO EJECT: NO
- SAFE TO EJECT: YES
- Blocked by copy failure
- Blocked by verify failure
- Blocked by cancellation
- Blocked by source changed
- Blocked by mismatch
- Blocked by unknown/incomplete state

## Visual Rules

- SAFE TO EJECT must be text-explicit.
- Do not rely on color alone.
- Blocked states must be visually stronger than neutral metadata.
- Success state must not appear before verify pass.
- Unknown state must not look like success.

## Wording

Use:

- SAFE TO EJECT: YES
- SAFE TO EJECT: NO
- Blocked: Verify failed
- Blocked: Copy cancelled
- Blocked: Source changed
- Blocked: File count mismatch

Avoid:

- Looks good
- Probably safe
- Done
- Finished, unless final verified completion is true
- Ready, unless the state is precisely defined

## Review Checklist

- [ ] SAFE TO EJECT is explicit.
- [ ] Block reason is visible.
- [ ] Failed/cancelled states cannot be mistaken for success.
- [ ] UI matches backend safety decision.
- [ ] Report availability is clear.

