# Shared Language

Use consistent terminology across code, UI, report, prompts, and docs.

## Preferred Terms

- Job
- Source
- Destination
- Copy Phase
- Verify Phase
- Safety Decision
- SAFE TO EJECT
- Blocked
- Cancelled
- Failed
- Completed
- Project ETA
- Whole Job ETA
- Current File
- Operator Summary
- Copy Result
- Verify Result

## ETA Terms

Primary:

- Project ETA
- Whole Job ETA

Secondary:

- Current File
- Current File Progress

Avoid using:

- Clone ETA
- File ETA as primary
- Generic ETA without context

## Safety Terms

Use:

- SAFE TO EJECT
- SAFE TO EJECT blocked
- Verify Passed
- Verify Failed
- Copy Failed
- Cancelled by Operator

Do not use vague terms like:

- Looks good
- Probably safe
- Seems copied
- Should be okay

Avoid operator-facing formatting language. The app does not format media.

## Concise Language

Agents should avoid repeated project background and filler.

Use direct technical wording.

Preferred:

- `Verdict: Reject`
- `Blocker: Verify failure can reach SAFE TO EJECT YES`
- `Fix: Gate safety decision on canonical verify pass`
- `QA: cancel during copy, cancel during verify, verify failure`

Avoid:

- long appreciation
- repeated role explanations
- broad project summaries when already known
- vague phrases such as "looks good" or "probably fine"
