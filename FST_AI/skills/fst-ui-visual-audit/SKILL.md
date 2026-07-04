<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-ui-visual-audit
description: Audit FST UI changes for visual hierarchy, operator readability, warning/error visibility, and anti-patterns.
---

# SKILL: fst-ui-visual-audit

## Role

Use this skill to audit completed UI work from Antigravity/Gemini Pro.

Primary reviewer: Claude or Mi.
Primary implementer: Antigravity/Gemini Pro.

## Use When

Use when reviewing:

- Main window layout
- Progress view
- Source/destination panels
- Safety status display
- Report summary
- Warning/error banners
- Button states
- UI polish changes

## Required Checks

Check:

- Is current phase immediately visible?
- Is Project ETA / Whole Job ETA visible?
- Is current file secondary?
- Is SAFE TO EJECT explicit?
- Are warnings/errors hard to miss?
- Are source/destination visible?
- Is report status visible?
- Can operator understand state within 3 seconds?
- Does UI match backend state?
- Did Antigravity avoid core logic changes?

## Anti-Patterns

Reject or revise if:

- UI is decorative but less readable.
- Error/warning state is too subtle.
- Failed/cancelled state looks successful.
- Copy complete looks verified.
- Per-file ETA appears as project ETA.
- Critical path/source text is hidden.
- UI uses vague status wording.
- Motion distracts from state.
- Color is the only state indicator.

## Output Format

Visual audit verdict:
Pass / Pass with concerns / Fail

Major visual issues:

Safety visibility issues:

Accessibility issues:

Recommended Antigravity revision prompt:

Notes for Mi:

