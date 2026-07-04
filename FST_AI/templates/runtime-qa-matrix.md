<!-- FST / CenVu | (+84) 842 841 222 -->

# Template: FST Runtime QA Matrix

Use this matrix when preparing manual Xcode runtime QA.

## QA Session Info

Date:
...

Tester:
...

Branch:
...

Build:
Debug / Release

macOS:
...

Machine:
...

FST version / commit:
...

Test media:
...

Source format:
...

Destination format:
...

## Required Runtime Scenarios

| ID | Scenario | Expected Result | Actual Result | SAFE TO EJECT | Report | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| QA-001 | Successful copy + verify | Copy passes, verify passes, SAFE TO EJECT YES | | | | Not Run | |
| QA-002 | Copy failure | Copy fails, verify not treated as pass, SAFE TO EJECT NO | | | | Not Run | |
| QA-003 | Verify failure | Verify fails, SAFE TO EJECT NO | | | | Not Run | |
| QA-004 | Cancel during copy | Job cancelled, partial data not treated as safe, SAFE TO EJECT NO | | | | Not Run | |
| QA-005 | Cancel during verify | Verify cancelled, SAFE TO EJECT NO | | | | Not Run | |
| QA-006 | Source changed after copy | Source changed detected or verify uncertain, SAFE TO EJECT NO | | | | Not Run | |
| QA-007 | Destination disconnected | Error visible, SAFE TO EJECT NO | | | | Not Run | |
| QA-008 | Large file progress | Progress updates, UI responsive, Project ETA is whole-job | | | | Not Run | |
| QA-009 | Many small files progress | Progress updates, UI responsive, Project ETA not per-file | | | | Not Run | |
| QA-010 | Report after success | Report shows copy pass, verify pass, SAFE TO EJECT YES | | | | Not Run | |
| QA-011 | Report after failure | Report records failure and SAFE TO EJECT NO | | | | Not Run | |
| QA-012 | Report after cancel | Report records cancellation and SAFE TO EJECT NO | | | | Not Run | |
| QA-013 | fileCountMismatch | Mismatch visible, report records mismatch, SAFE TO EJECT blocked unless approved policy says otherwise | | | | Not Run | |
| QA-014 | App close/reopen after job if supported | State/report availability remains truthful | | | | Not Run | |
| QA-015 | UI responsiveness during verify | UI does not freeze, cancellation remains available | | | | Not Run | |

## Blocking Criteria

Block release if:

- Any failure/cancel/verify-fail case produces SAFE TO EJECT YES.
- UI freezes during long copy/verify.
- Report contradicts final state.
- Error is hidden from operator.
- Source is mutated.
- Apple rsync fallback appears.
- Destructive rsync behavior appears.

## Summary

Passed:
...

Failed:
...

Blocked:
...

Not run:
...

Release recommendation:

- [ ] Ready
- [ ] Not ready
- [ ] Ready with known limitations

Notes:
...

