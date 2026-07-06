<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-ui-state-review
description: Review whether FST UI states accurately reflect backend copy, verify, progress, error, and safety states.
---

# Skill: fst-ui-state-review

## Purpose

Review whether FST UI state truthfully reflects backend copy, verify, progress, error, and safety states.

## When to Use

Use after UI changes, ViewModel presentation changes, progress display changes, safety status changes, or warning/error UI changes.

## Owner Agent

Claude or Mi reviews. Antigravity/Gemini implements UI. Codex provides core data if needed.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/design-system/pages/safety-status.md`

## Inputs

- UI diff or screenshot.
- Backend state description.
- UI states checked.
- Known data dependencies.

## Safety Boundaries

- UI cannot alter safety truth.
- Failed, cancelled, incomplete, or uncertain states must not look successful.
- Destination observer, speed, ETA, current item, and Verify ETA are UI-only.

## Procedure

1. Compare UI state to backend state.
2. Check idle, ready, copying, verifying, failed, cancelled, completed, and SAFE TO EJECT states.
3. Check buttons, warnings, reports, and ETA labels.
4. Identify missing core data rather than inventing UI state.

## Required Checks

- Buttons enabled/disabled correctly.
- Errors and warnings visible.
- Safety decision visible.
- ETA label not misleading.
- Report availability clear.
- Failed state does not look successful.

## Output Format

UI state verdict:

Incorrect states:

Missing warnings:

Misleading wording:

Recommended fix:

## Stop / Escalate If

- UI requires new backend safety data.
- UI contradicts backend final state.
- SAFE TO EJECT display is ambiguous.

## Do Not

- Fake backend state.
- Hide failure/cancel/uncertain state.
- Let progress display decide safety.
