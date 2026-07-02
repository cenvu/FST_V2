# Workflow: Prepare Runtime QA

## Use When

Use before release or after core engine changes.

## Steps

1. Identify changed subsystem.
2. Select runtime scenarios.
3. Prepare test matrix.
4. Run or request Xcode runtime testing.
5. Record evidence.
6. Claude reviews QA completeness.
7. Mi decides whether more testing is needed.

## Required Scenarios

- Success
- Copy fail
- Verify fail
- Cancel during copy
- Cancel during verify
- Source changed when applicable
- Destination disconnected
- Large file
- Many small files
- Report success
- Report failure

## Required Templates

Use:

- `FST_AI/templates/runtime-qa-matrix.md`
- `FST_AI/templates/runtime-test-evidence.md`
- `FST_AI/prompts/claude-runtime-qa-review.md`

For release-sensitive changes, Claude must review QA completeness before Mi accepts the change.
