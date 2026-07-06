<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-report-correctness-review
description: Review whether FST report output truthfully matches canonical job state, copy result, verify result, errors, warnings, and SAFE TO EJECT decision.
---

# Skill: fst-report-correctness-review

## Purpose

Review generated reports against actual transfer, verification, error, warning, and terminal-state evidence.

## When to Use

Use for report samples, report builder changes, field mapping, wording, safety decision output, warnings/errors, skipped items, or final status.

## Owner Agent

Claude reviews. Codex implements. Mi gates.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/skills/fst-detailed-txt-report/SKILL.md`

## Inputs

- Report sample.
- Final TransferState.
- Copy result.
- Verify result.
- Errors/warnings/skipped items.
- Logs if available.

## Safety Boundaries

- Report truth comes from canonical state, not UI optimism.
- UI estimates, observer metrics, speed, ETA, current item, and Verify ETA cannot affect report truth.
- Copy-only success is not verified SAFE TO EJECT.

## Procedure

1. Map report fields to canonical source data.
2. Check success, fail, cancel, verify fail, copy-only, and source-changed cases.
3. Confirm final safety wording and reason.
4. Check operator readability without weakening disclaimers.

## Required Checks

- SAFE TO EJECT YES only when copy and verification pass.
- SAFE TO EJECT NO for failed/cancelled/incomplete/uncertain cases.
- fileCountMismatch or missing evidence is not hidden.
- Warnings/errors are visible.
- No obsolete format authorization wording.

## Output Format

Verdict:

Mismatches:

Missing evidence:

Safety wording issues:

Recommended revision:

Notes for Mi:

## Stop / Escalate If

- Report contradicts runtime state.
- Report omits blocking failure evidence.
- Report could be read as permission to erase/format/reuse source media.

## Do Not

- Approve report samples without checking source state.
- Treat prettier wording as more important than truth.
