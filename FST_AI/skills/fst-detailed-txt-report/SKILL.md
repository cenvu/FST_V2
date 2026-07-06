<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-detailed-txt-report
description: Guide implementation and review of FST Detailed TXT Report V1 with operational evidence and safety decision fields.
---

# Skill: fst-detailed-txt-report

## Purpose

Implement or review Detailed TXT Report V1 as operator evidence, not permission to erase, format, or reuse source media.

## When to Use

Use when report generation, schema, wording, fields, filenames, storage, terminal status, warnings, errors, skipped items, or SAFE TO EJECT decision output changes.

## Owner Agent

Codex implements. Claude reviews. Mi gates.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `docs/02_FST_TECHNICAL_GUIDE.md`

## Inputs

- Report code diff.
- Expected success/failure/cancel outputs.
- Transfer/verify result mapping.
- Wording requirements.

## Safety Boundaries

- Report must match canonical job state.
- Report must not imply permission to erase, format, or reuse source media.
- Verified success wording is SAFE TO EJECT / SAFE TO EJECT DESTINATION.
- Failed/cancelled/uncertain states must record SAFE TO EJECT NO.

## Procedure

1. Identify report source data.
2. Confirm required sections and final safety decision.
3. Compare success, failure, cancel, verify-fail, and copy-only cases.
4. Confirm wording avoids obsolete format-safety language.
5. Recommend report correctness review.

## Required Checks

- Operator summary.
- Job/source/destination identity.
- Copy result.
- Verify result or copy-only status.
- SAFE TO EJECT decision and reason.
- Warnings/errors/skipped items.
- Timing/tooling.
- Technical log sharing note when applicable.

## Output Format

Files changed:

Report behavior changed:

Safety wording:

Required fields covered:

Sample scenarios:

Review needed:

## Stop / Escalate If

- Report can contradict final state.
- Report omits cancellation/failure/verify failure.
- Report uses obsolete format authorization wording.

## Do Not

- Add PDF/database/report viewer features.
- Generate optimistic report output before final canonical state.
