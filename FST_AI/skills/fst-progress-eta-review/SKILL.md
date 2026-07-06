<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-progress-eta-review
description: Review FST progress, parser, observer, and ETA behavior while preserving safety truth.
---

# Skill: fst-progress-eta-review

## Purpose

Review progress and ETA behavior so operators see useful status without confusing UI estimates with safety truth.

## When to Use

Use when progress appears stuck, ETA is wrong, ETA appears per-file, observer metrics changed, Verify ETA changed, or progress UI is confusing.

## Owner Agent

Codex implements core progress fixes. Claude reviews. Antigravity handles UI display when routed.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `docs/02_FST_TECHNICAL_GUIDE.md`

## Inputs

- Logs.
- Rsync output.
- Parser output.
- Observer metrics.
- UI state/screenshot.
- Source/destination size and file count.

## Safety Boundaries

- Destination observer and Verify ETA are UI-only.
- They must never decide copy success, verify success, report truth, or SAFE TO EJECT.
- Rsync lifecycle decides copy truth. Verify result decides verification truth.

## Procedure

1. Identify whether issue is rsync output, parser, observer, model, or UI binding.
2. Separate whole-job progress from current-file progress.
3. Confirm stale/slow progress does not become false failure or false success.
4. Recommend smallest safe fix or route UI-only display work to Antigravity.

## Required Checks

- Total bytes/files expected.
- Bytes/files completed.
- Current phase.
- Current file is secondary.
- Project/whole-job ETA is clearly labeled.
- Verify ETA is approximate and UI-only.
- State transition after rsync completion remains authoritative.

## Output Format

Progress diagnosis:

ETA source:

Safety impact:

Parser risk:

UI binding risk:

Runtime QA:

## Stop / Escalate If

- Progress data is used to infer copy/verify success.
- UI can make stalled/cancelled/failed work look safe.
- Core data is missing for a UI request.

## Do Not

- Fake ETA.
- Present per-file ETA as project ETA.
- Change safety/report logic as part of UI polish.
