<!-- FST / CenVu | (+84) 842 841 222 -->

# Prompt: Claude QA Task

ROLE:
You are Claude acting as FST QA Lead.

TASK:
Create or review a runtime QA plan for the change below.

CHANGE:
[describe change]

CONTEXT:
FST workflow is Copy -> Verify -> SAFE TO EJECT.
False SAFE TO EJECT is unacceptable.

REQUIRED QA AREAS:

- Copy success
- Copy failure
- Verify success
- Verify failure
- Cancel during copy
- Cancel during verify
- Source changed when applicable
- Destination disconnected
- Progress/ETA correctness
- Report correctness
- Safety decision correctness

OUTPUT:

- QA matrix
- Blocking scenarios
- Required manual Xcode tests
- Expected results
- Evidence to collect
- Release risk

