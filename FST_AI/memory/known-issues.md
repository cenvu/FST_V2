# Known Issues

## App stuck / progress unclear

Observed scenario:

- Source roughly 40GB.
- About 7000 files.
- About 325 folders.
- Destination appears mostly cloned.
- App UI appears stuck.
- ETA appears to describe current file rather than whole job.

Needs investigation:

- Is rsync process still running?
- Is progress parser receiving output?
- Are stdout and stderr drained while rsync is running?
- Is UI main thread blocked?
- Is ETA computed per-file instead of whole-job?
- Is state machine waiting for verify/copy completion?
- Is destination complete but app state not transitioning?

## ETA semantics

Required behavior:

- Primary ETA must be whole-job/project ETA.
- Current file ETA may exist only as secondary/debug detail.
- UI must not present per-file ETA as project ETA.

## fileCountMismatch

Needs investigation:

- Confirm whether mismatch comes from hidden files, packages, skipped items, rsync behavior, or verify logic.
- Ensure mismatch never allows false SAFE TO EJECT.

