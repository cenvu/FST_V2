<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-ui-accessibility-review
description: Review FST UI accessibility as an operational safety feature, including contrast, text clarity, focus, reduced motion, and non-color state communication.
---

# Skill: fst-ui-accessibility-review

## Purpose

Review UI accessibility as safety-critical operator readability.

## When to Use

Use when colors, warnings/errors, button states, progress UI, safety status, typography, spacing, focus, or motion changes.

## Owner Agent

Claude or Mi reviews. Antigravity/Gemini implements UI fixes.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/design-system/MASTER.md`
- `FST_AI/design-system/audits/accessibility-checklist.md`

## Inputs

- Screenshot or UI notes.
- Changed UI files.
- States reviewed.
- Any accessibility concerns.

## Safety Boundaries

- SAFE TO EJECT, warning, error, failed, and cancelled states must not rely on color alone.
- Accessibility polish must not change safety truth.

## Procedure

1. Check critical text contrast and size.
2. Check non-color state cues.
3. Check focus and button states.
4. Check reduced motion and readable paths.
5. Check whether failed state can be mistaken for success.

## Required Checks

- SAFE TO EJECT readability.
- Warning/error contrast.
- Disabled states understandable.
- ETA labels precise.
- Long paths readable or inspectable.
- Critical text not too small.

## Output Format

Accessibility verdict:

Blocking issues:

Non-blocking issues:

Recommended fix:

Notes for Mi:

## Stop / Escalate If

- Safety status relies on color alone.
- Error/warning visibility is weak.
- UI state can be misread under accessibility constraints.

## Do Not

- Approve low-contrast safety states.
- Use motion or styling that hides state transitions.
