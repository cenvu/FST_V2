<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-ui-visual-audit
description: Audit FST UI changes for visual hierarchy, operator readability, warning/error visibility, and anti-patterns.
---

# Skill: fst-ui-visual-audit

## Purpose

Audit completed or proposed FST UI for operator clarity and safety-readable visual hierarchy.

## When to Use

Use for main window, progress view, source/destination panels, safety status, report summary, warning/error banners, button states, or UI polish.

## Owner Agent

Claude or Mi reviews. Antigravity/Gemini implements.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/design-system/MASTER.md`
- Relevant page override.
- UI audit checklists.

## Inputs

- Screenshot or UI notes.
- Changed files.
- State list tested.
- Known backend state.

## Safety Boundaries

- UI must match backend truth.
- No failed/cancelled/uncertain state may look successful.
- UI estimates must not affect safety gates.

## Procedure

1. Inspect phase/status hierarchy.
2. Check safety state readability.
3. Check warnings/errors.
4. Check source/destination readability.
5. Check accessibility and density.

## Required Checks

- Can operator understand state within three seconds?
- Is whole-job status primary?
- Is current file secondary?
- Are warnings/errors impossible to miss?
- Is SAFE TO EJECT explicit only when valid?
- Does UI avoid decorative noise?

## Output Format

Verdict:

Blocking UI issues:

Operator clarity issues:

Accessibility issues:

Recommended revision:

## Stop / Escalate If

- UI contradicts backend state.
- UI requires core data changes.
- Safety status is ambiguous.

## Do Not

- Approve UI that hides risk.
- Request decorative work that reduces readability.
