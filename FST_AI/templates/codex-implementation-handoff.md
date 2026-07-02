# Template: Codex Implementation Handoff

Use this template when Codex finishes a coding task and Mi needs to send the result to Claude for primary review.

## Task Summary

Task:
...

Issue / Feature:
...

Agent:
Codex

Date:
...

Branch:
...

## Scope

Files changed:
...

Files intentionally not changed:
...

Subsystems affected:

- [ ] Rsync / copy
- [ ] Verify
- [ ] State machine
- [ ] Progress / ETA
- [ ] Report
- [ ] Error handling
- [ ] UI data model
- [ ] UI view
- [ ] Documentation only

## Behavior Changed

Before:
...

After:
...

## Safety Impact

Safety impact:

- [ ] None
- [ ] Low
- [ ] Medium
- [ ] High

Could this affect SAFE TO EJECT?

- [ ] No
- [ ] Yes
- [ ] Uncertain

Explanation:
...

## Review Skill Recommendation

Claude should review with:

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

Reason:
...

## Tests / Checks Performed

- [ ] Build passed
- [ ] Unit tests passed
- [ ] Manual Xcode runtime test performed
- [ ] Not run

Details:
...

## Known Risks

Known risks:
...

Unverified assumptions:
...

## Runtime QA Needed

Required scenarios:

- [ ] Success
- [ ] Copy failure
- [ ] Verify failure
- [ ] Cancel during copy
- [ ] Cancel during verify
- [ ] Source changed
- [ ] Destination disconnected
- [ ] Large file progress
- [ ] Many small files progress
- [ ] Report success sample
- [ ] Report failure sample

## Claude Review Input

Paste diff / summary / relevant files:
...

