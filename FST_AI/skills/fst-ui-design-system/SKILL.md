<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-ui-design-system
description: Guide FST UI design system decisions using operational clarity, accessibility, SwiftUI constraints, and safety-first visual hierarchy.
---

# Skill: fst-ui-design-system

## Purpose

Apply FST-specific UI design rules for a professional macOS offload utility.

## When to Use

Use when creating or revising UI direction, progress views, safety status, report summary, page-specific guidance, or visual consistency.

## Owner Agent

Antigravity/Gemini implements. Claude or Mi reviews. Mi gates.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/design-system/MASTER.md`
- Relevant `FST_AI/design-system/pages/`
- Relevant `FST_AI/design-system/audits/`

## Inputs

- UI area.
- Operator state requirements.
- Screenshots or design notes.
- Backend state available to UI.

## Safety Boundaries

- Status-first design.
- Safety state must be impossible to misread.
- UI cannot change copy, verify, report, or SAFE TO EJECT truth.

## Procedure

1. Identify target user workflow and phase.
2. Prioritize state, warnings, and evidence before visual polish.
3. Use calm, compact, dark-mode-first macOS utility styling.
4. Apply accessibility and operator clarity checks.
5. Reject decorative consumer/playful patterns.

## Required Checks

- Critical state visible in three seconds.
- SAFE TO EJECT / blocked state unambiguous.
- Text contrast and non-color state cues.
- Motion restrained and optional.
- No decorative branding that competes with status.

## Output Format

Design direction:

Page/audit docs used:

Operator clarity risks:

Accessibility checks:

Implementation notes:

## Stop / Escalate If

- UI needs new safety data.
- Proposed design hides errors or safety state.
- A design choice conflicts with FST safety doctrine.

## Do Not

- Import external design systems.
- Use consumer/playful UI.
- Use visual polish to soften failure/cancel states.
