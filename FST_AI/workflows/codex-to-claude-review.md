# Workflow: Codex to Claude Review

## Purpose

Use this workflow to preserve Codex token for coding while using Claude for primary review.

## Steps

1. Codex implements.
2. Codex outputs summary:
   - files changed
   - behavior changed
   - safety impact
   - tests/build needed
   - known risks
   - what Claude should review
3. Mi sends Codex summary and diff to Claude.
4. Claude reviews.
5. Claude returns:
   - Accept / Accept with risk / Reject
   - safety impact
   - must-fix issues
   - revision prompt
6. Mi sends revision prompt to Codex if needed.

## Skill Selection

When sending Codex work to Claude, Mi should select the most specific review skill:

- Rsync/process/copy transport changes -> `fst-rsync-engine-review`
- Verify/mismatch/source-changed changes -> `fst-verify-engine-review`
- State transition/cancel/failure changes -> `fst-state-machine-review`
- TXT report implementation changes -> `fst-detailed-txt-report`
- Error/cancel/retry/warning changes -> `fst-error-handling-review`
- Report output sample/field correctness changes -> `fst-report-correctness-review`
- General safety risk -> `fst-core-safety-review`
- General code review -> `fst-code-review`

Claude may combine multiple skills for safety-critical changes.
