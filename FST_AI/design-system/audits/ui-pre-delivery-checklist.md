<!-- FST / CenVu | (+84) 842 841 222 -->

# UI Pre-Delivery Checklist

Use this before accepting UI changes from Antigravity/Gemini Pro.

## Scope

- [ ] UI-only change confirmed.
- [ ] No core transfer/verify/safety/report logic modified.
- [ ] No new dependency added.
- [ ] No scope creep introduced.

## Operational Clarity

- [ ] Current phase visible.
- [ ] Source visible.
- [ ] Destination visible.
- [ ] Overall job progress visible.
- [ ] Project ETA / Whole Job ETA visible when available.
- [ ] Current file is secondary.
- [ ] SAFE TO EJECT status visible.
- [ ] Warning/error state visible.
- [ ] Report status visible when relevant.

## Safety

- [ ] Failed state cannot be mistaken for success.
- [ ] Cancelled state cannot be mistaken for success.
- [ ] Copy complete cannot be mistaken for verify complete.
- [ ] SAFE TO EJECT does not appear before backend decision.
- [ ] UI does not fake backend state.
- [ ] UI does not hide source/destination identity.

## Accessibility

- [ ] Critical text has sufficient contrast.
- [ ] State is not communicated by color alone.
- [ ] Focus states are visible.
- [ ] Reduced motion is respected.
- [ ] Buttons have clear labels.
- [ ] Disabled states are understandable.

## macOS / SwiftUI

- [ ] Layout works at expected window sizes.
- [ ] Text truncation does not hide critical state.
- [ ] Long paths remain inspectable.
- [ ] Progress updates do not freeze UI.
- [ ] View code remains composable and maintainable.

