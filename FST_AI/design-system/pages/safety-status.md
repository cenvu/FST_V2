<!-- FST / CenVu | (+84) 842 841 222 -->

# Design System Page Override: Safety Status

## Purpose

Safety status must clearly communicate whether the job is SAFE TO EJECT.

## Required States

The UI must support:

- READY or SETUP REQUIRED
- PREPARING
- COPYING
- VERIFYING
- TRANSFER COMPLETE (copy succeeded; verification disabled)
- SAFE TO EJECT (copy succeeded and verification passed)
- MANUAL CHECK REQUIRED (verification failure)
- TRANSFER ERROR (generic transfer failure)
- CANCELLED
- Blocked by copy failure
- Blocked by verify failure
- Blocked by cancellation
- Blocked by source changed
- Blocked by mismatch
- Blocked by unknown/incomplete state

## Visual Rules

- Show SAFE TO EJECT positively only when backend copy and verification truth confirms success.
- Do not display SAFE TO EJECT: NO during normal READY, PREPARING, COPYING, or VERIFYING.
- Outcome text and operator action are separate; an outcome surface must not secretly perform Retry.
- Error detail and Open Technical Log provide diagnostic evidence without inventing recovery instructions.
- Report existence is separate from safety truth; preserve saved, skipped, and warning evidence.
- SAFE TO EJECT must be text-explicit.
- Do not rely on color alone.
- Blocked states must be visually stronger than neutral metadata.
- Success state must not appear before verify pass.
- Unknown state must not look like success.
- Terminal outcomes: TRANSFER COMPLETE, SAFE TO EJECT, MANUAL CHECK REQUIRED, TRANSFER ERROR, CANCELLED.
- TRANSFER COMPLETE uses neutral/blue copy-only treatment; only SAFE TO EJECT uses verified-success green.
- Keep the UI minimal for terminal outcomes (control/action state + text badge). Do not require a giant celebratory final card.

## Wording

Use:

- SAFE TO EJECT
- TRANSFER COMPLETE
- MANUAL CHECK REQUIRED with the real verification reason
- TRANSFER ERROR with the real transfer reason
- CANCELLED
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

