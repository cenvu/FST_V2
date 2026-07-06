<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-progress-dashboard-design
description: Guide FST progress dashboard design so phase, whole-job progress, warnings, and SAFE TO EJECT state are clear.
---

# Skill: fst-progress-dashboard-design

## Purpose

Design or review progress/dashboard UI for field-readable copy and verify work.

## When to Use

Use when progress UI, ETA, current item, warning display, or dashboard hierarchy changes.

## Owner Agent

Antigravity/Gemini implements UI. Codex provides core data when needed. Claude or Mi reviews.

## Required Startup Docs

- `FST_AI/design-system/MASTER.md`
- `FST_AI/design-system/pages/progress-view.md`
- `FST_AI/design-system/pages/safety-status.md`

## Inputs

- Progress data available.
- Copy/verify phase behavior.
- UI screenshot or layout.
- Any stale/slow progress symptoms.

## Safety Boundaries

- Destination observer and Verify ETA are UI-only.
- Dashboard cannot decide copy success, verify success, report truth, or SAFE TO EJECT.

## Procedure

1. Put current phase first.
2. Put whole-job progress and safety state before current-file detail.
3. Keep ETA clearly approximate.
4. Make warnings/errors visible.
5. Route missing data to Codex.

## Required Checks

- Phase visible.
- Whole-job ETA/progress visible when available.
- Copy and verify distinction clear.
- Stalled/slow state not hidden.
- Failure/cancel state cannot look safe.

## Output Format

Dashboard hierarchy:

Data dependencies:

Safety state display:

Risks:

Revision recommendation:

## Stop / Escalate If

- UI needs core progress model changes.
- ETA source is unclear.
- Dashboard implies safety before verification.

## Do Not

- Make current-file progress the primary job signal.
- Treat ETA as a promise.
- Hide error/cancel states.
