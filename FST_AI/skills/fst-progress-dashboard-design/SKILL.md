---
name: fst-progress-dashboard-design
description: Guide FST progress dashboard design so Project ETA, phase, progress, warnings, and SAFE TO EJECT state are clear for operators.
---

# SKILL: fst-progress-dashboard-design

## Role

Use this skill when designing or reviewing FST progress/dashboard UI.

Primary implementer: Antigravity/Gemini Pro.
Primary core data provider: Codex.
Primary reviewer: Claude or Mi.

## Use When

Use when:

- Progress UI is confusing.
- ETA needs redesign.
- Copy/verify status needs clearer display.
- Job appears stuck.
- Current file detail overwhelms project progress.
- Producer-facing timing needs to be visible.

## Required Hierarchy

Progress dashboard must prioritize:

1. Current phase
2. Overall job progress
3. Project ETA / Whole Job ETA
4. SAFE TO EJECT status or pending safety state
5. Warning/error state
6. Source/destination identity
7. Current file detail
8. Technical metadata

## Data Rules

UI must not fake backend state.

Required data should come from core model:

- current phase
- total bytes expected
- bytes copied
- total files expected
- files completed
- current file
- transfer speed if reliable
- whole-job ETA if reliable
- stale progress state
- final safety decision

If missing, Antigravity must request Codex model support instead of inventing UI state.

## Anti-Patterns

Do not:

- Present per-file ETA as project ETA.
- Show 100% copy as final success before verify.
- Hide verify phase.
- Hide stalled progress.
- Use vague "almost done" wording.
- Make progress look complete when report/safety is not final.

## Output Format

Progress dashboard verdict:
Accept / Accept with revisions / Reject

Information hierarchy:

Missing backend data:

Misleading UI risks:

Recommended Antigravity revision prompt:

Recommended Codex data request if needed:

Notes for Mi:

