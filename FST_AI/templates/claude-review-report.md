# Template: Claude Review Report

Use this template for Claude primary QA/code/safety reviews.

## Review Summary

Reviewer:
Claude

Task:
...

Codex handoff reviewed:

- [ ] Yes
- [ ] No

Diff reviewed:

- [ ] Yes
- [ ] No

Relevant files reviewed:
...

## Verdict

Verdict:

- [ ] Accept
- [ ] Accept with risk
- [ ] Reject

## Safety Impact

Safety impact:

- [ ] None
- [ ] Low
- [ ] Medium
- [ ] High

SAFE TO EJECT impact:

- [ ] None
- [ ] Possible
- [ ] Confirmed risk
- [ ] Improved

## Review Skills Applied

- [ ] fst-rsync-engine-review
- [ ] fst-verify-engine-review
- [ ] fst-state-machine-review
- [ ] fst-detailed-txt-report
- [ ] fst-error-handling-review
- [ ] fst-report-correctness-review
- [ ] fst-progress-eta-review
- [ ] fst-core-safety-review
- [ ] fst-code-review
- [ ] fst-ui-state-review

## Must Fix Before Merge

Blocking issues:
...

## Important Concerns

Non-blocking concerns:
...

## Edge Cases Checked

- [ ] Copy failure
- [ ] Verify failure
- [ ] Cancellation
- [ ] Source changed
- [ ] Destination disconnected
- [ ] fileCountMismatch
- [ ] Progress stale
- [ ] Report mismatch
- [ ] UI misleading state
- [ ] MainActor/UI blocking

Notes:
...

## Recommended Codex Revision Prompt

Paste-ready revision prompt:
...

## Runtime QA Required

Required:

- [ ] No
- [ ] Yes

Scenarios:
...

## Notes for Mi

Merge recommendation:
...

Safety gate notes:
...

