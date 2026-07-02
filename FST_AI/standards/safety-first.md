# Safety First

FST must never imply that source media is safe for operator handoff unless the application has reliable evidence.

## SAFE TO EJECT Requirements

A job may be considered SAFE TO EJECT only if:

- Copy completed successfully.
- Verification completed successfully.
- Source identity is unchanged where required by current policy.
- Destination exists.
- Required checks pass.
- No cancellation state is active.
- No failure state is active.
- Final report records the safety decision.

## Source Safety Rules

The source volume is treated as read-only operational media.

FST must never:

- Delete files from source.
- Move files from source.
- Rename files on source.
- Modify source file contents.
- Change source permissions.
- Change source ownership.
- Format source.
- Run destructive commands against source.
- Use rsync options that remove or mutate source files.

Allowed source operations:

- Read metadata.
- Enumerate files.
- Read file contents for copy/verify.
- Capture source identity for safety checks.

Any code path that writes to source must be treated as a critical safety violation.

## Rsync Safety Rules

FST uses bundled rsync 3.4.4 only.

FST must not use Apple system rsync fallback.

Forbidden or high-risk rsync behavior:

- `--delete`
- `--delete-before`
- `--delete-after`
- `--delete-during`
- `--remove-source-files`
- `--inplace`
- Any option that deletes source data.
- Any option that mutates source data.
- Any option that silently removes destination files without explicit approved design.

If a future feature requires cleanup behavior, it must be designed, reviewed, and tested as a separate safety-critical change.

## UI and MainActor Safety

Copy, verify, hashing, file enumeration, and large report generation must not block the UI.

Rules:

- Long-running file operations must not run on the MainActor.
- Verify work must not freeze SwiftUI.
- Progress updates should be delivered to UI through safe state updates.
- UI must distinguish slow progress from stalled progress.
- UI must remain responsive during copy, verify, cancel, and failure handling.
- Cancellation must remain available while long-running work is active.

A responsive UI is a safety feature because operators need accurate state during media handling.

## Must Never Happen

FST must never:

- Mark failed copy as safe.
- Mark cancelled job as safe.
- Mark verify-failed job as safe.
- Hide errors behind successful UI.
- Generate report that contradicts actual state.
- Allow UI polish to reduce warning visibility.

FST does not format media and does not eject media.
