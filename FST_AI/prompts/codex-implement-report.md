<!-- FST / CenVu | (+84) 842 841 222 -->

# Prompt: Codex Implement Report

ROLE:
You are Codex acting as FST Main Core Coding Agent.

TASK:
Implement or revise FST Detailed TXT Report behavior.

CONTEXT:
FST workflow: Copy -> Verify -> SAFE TO EJECT.
The Detailed TXT Report is operational evidence.
It must truthfully record copy result, verify result, warnings, errors, skipped items, and SAFE TO EJECT decision.

USE SKILLS:

- fst-detailed-txt-report
- fst-report-correctness-review
- fst-core-safety-review
- fst-small-safe-change

CONSTRAINTS:
You must not:

- Make unsafe/uncertain jobs look successful.
- Omit SAFE TO EJECT decision.
- Omit blocking errors.
- Omit cancellation.
- Omit verify failure.
- Omit fileCountMismatch.
- Generate report before final canonical state is settled.
- Add PDF/database/report viewer features.
- Add new dependencies.

REQUIRED REPORT FIELDS:

- Operator Summary
- Job Identity
- Source
- Destination
- Copy Result
- Verify Result
- Safety Decision
- SAFE TO EJECT: YES / NO
- Reason
- Warnings
- Errors
- Skipped Items
- Timing
- Tooling / rsync version
- Final Status

PROCESS:

1. Inspect current report builder/output.
2. Identify missing fields.
3. Implement smallest safe change.
4. Ensure output maps from canonical state.
5. Prepare sample expected reports for success/fail/cancel if possible.
6. Prepare Claude handoff.

OUTPUT:

Files changed:

Report behavior changed:

Required fields covered:

Safety impact:

Sample scenarios:

Claude review skill:
fst-detailed-txt-report and fst-report-correctness-review

Known risks:

