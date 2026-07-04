<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-runtime-qa
description: Prepare and review runtime QA scenarios for FST copy, verify, cancel, failure, report, and safety behavior.
---

# SKILL: fst-runtime-qa

## Role

Use this skill to prepare and review runtime QA for FST.

## Required Scenarios

Test:

1. Successful copy + verify
2. Copy failure
3. Verify failure
4. User cancel during copy
5. User cancel during verify
6. Source changed after copy when applicable
7. Destination disconnected
8. App progress during large file
9. App progress during many small files
10. Report generation after success
11. Report generation after failure
12. SAFE TO EJECT blocked cases

## Required Evidence

For each scenario, record:

- Source
- Destination
- File count
- Total size
- Copy result
- Verify result
- Final state
- Safety decision
- Report generated: yes/no
- UI state
- Any warning/error

## Output Format

Runtime QA matrix:

Pass/fail summary:

Blocking issues:

Non-blocking issues:

Release recommendation:
