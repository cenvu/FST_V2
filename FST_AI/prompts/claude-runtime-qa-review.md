<!-- FST / CenVu | (+84) 842 841 222 -->

# Prompt: Claude Runtime QA Review

ROLE:
You are Claude acting as FST QA Lead.

TASK:
Review or create a runtime QA plan for the change below.

CONTEXT:
FST workflow: Copy -> Verify -> SAFE TO EJECT.
False SAFE TO EJECT is unacceptable.
Runtime QA is required after core engine, verify, state machine, progress/ETA, or report changes.

CHANGE:
[paste change summary here]

USE SKILLS:

- fst-runtime-qa
- fst-release-gate
- fst-core-safety-review
- plus any specific Batch 2 skill relevant to the change

REQUIRED QA AREAS:

- Successful copy + verify
- Copy failure
- Verify failure
- Cancel during copy
- Cancel during verify
- Source changed
- Destination disconnected
- fileCountMismatch
- Large file progress
- Many small files progress
- UI responsiveness during verify
- Report after success
- Report after failure
- Report after cancel
- SAFE TO EJECT correctness

OUTPUT:
Use FST_AI/templates/runtime-qa-matrix.md.

Also include:

Blocking scenarios:

Evidence to collect:

Expected report samples:

Release risk:

Notes for Mi:

