<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-ui-accessibility-review
description: Review FST UI accessibility as an operational safety feature, including contrast, text clarity, focus, reduced motion, and non-color state communication.
---

# SKILL: fst-ui-accessibility-review

## Role

Use this skill to review FST UI accessibility.

Accessibility is treated as a safety feature because operators need to read copy, verify, error, and SAFE TO EJECT state accurately.

## Use When

Use when:

- UI colors change.
- Warning/error design changes.
- Button states change.
- Progress UI changes.
- Safety status UI changes.
- Typography/spacing changes.
- Motion/animation changes.

## Required Checks

Check:

- Critical text contrast.
- Warning/error contrast.
- SAFE TO EJECT readability.
- State labels not color-only.
- Focus states visible.
- Reduced motion respected.
- Buttons clearly labeled.
- Disabled states understandable.
- Critical text not too small.
- Long paths readable or inspectable.
- ETA labels are precise.

## Hard Blocks

Reject if:

- SAFE TO EJECT status relies on color alone.
- Error state is low contrast.
- Warning state is hidden.
- Motion hides state transition.
- Critical text is too small to read.
- Button state is ambiguous.
- Failed state looks like success.

## Output Format

Accessibility verdict:
Pass / Pass with concerns / Fail

Blocking accessibility issues:

Non-blocking issues:

Recommended fix:

Notes for Mi:

