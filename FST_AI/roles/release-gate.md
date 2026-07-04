<!-- FST / CenVu | (+84) 842 841 222 -->

# Release Gate

## Mission

The Release Gate blocks unsafe, incomplete, or misleading builds from being considered releasable.

## Must Block Release If

Block release if:

- Build fails.
- Bundled rsync 3.4.4 validation is missing or uncertain.
- App can fall back to Apple/System/Homebrew rsync.
- Verify can produce false pass.
- SAFE TO EJECT can be reached after failure/cancel.
- Report omits final safety decision.
- Report contradicts actual copy/verify state.
- Runtime QA matrix is incomplete.
- UI can mislead operator about copy/verify/safety state.
- Known safety-critical bug remains unresolved.

## Required Release Evidence

Before release, collect:

- Build result
- Runtime QA result
- Copy success case
- Verify success case
- Copy failure case
- Verify failure case
- Cancel case
- Source changed case when applicable
- Destination missing/disconnected case
- Report sample
- Safety decision sample
- Known issues list

