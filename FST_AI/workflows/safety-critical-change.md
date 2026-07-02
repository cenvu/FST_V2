# Workflow: Safety-Critical Change

## Use When

Use for:

- SAFE TO EJECT gate logic
- Verify result
- Copy result
- State machine
- Cancellation
- Failure handling
- Source changed detection
- Report safety decision

## Steps

1. Mi marks task as safety-critical.
2. Codex implements only smallest safe change.
3. Codex reports safety impact.
4. Claude performs primary safety review.
5. Codex revises if needed.
6. Claude rechecks.
7. Mi decides merge/no-merge.

## Merge Rule

No safety-critical change should be accepted without Claude review and Mi final approval.

