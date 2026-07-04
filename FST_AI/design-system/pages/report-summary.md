<!-- FST / CenVu | (+84) 842 841 222 -->

# Design System Page Override: Report Summary

## Purpose

Report summary UI must show whether evidence was generated and what the final safety decision was.

## Required Information

Show:

- Report generated: YES / NO
- Report path if available
- Copy result
- Verify result
- SAFE TO EJECT decision
- Warnings count
- Errors count
- Skipped items count if available

## Rules

- Report summary must match report content.
- Report summary must match canonical final state.
- Report summary must not hide failure/cancel state.
- Report summary must not use vague success wording.
- Operator must know whether the report is safe evidence.

## Review Checklist

- [ ] Report path is visible or accessible.
- [ ] Final safety decision is visible.
- [ ] Copy/verify result is visible.
- [ ] Warnings/errors are not hidden.
- [ ] Summary matches generated TXT report.

