<!-- FST / CenVu | (+84) 842 841 222 -->

# FST Design System Master

## Purpose

This file is the source of truth for FST UI design direction.

FST is not a decorative consumer app. FST is an operational macOS tool for DIT/Data Wrangler workflows.

The UI must help operators make correct decisions under time pressure.

## Product Category

FST belongs to these UI categories:

- Professional desktop utility
- Operational dashboard
- Data safety tool
- Real-time monitoring interface
- Cinema production workflow tool

## UI Personality

FST should feel:

- Calm
- Precise
- Technical
- Trustworthy
- Fast to read
- Low-noise
- Professional
- Safety-first

FST should not feel:

- Trendy
- Decorative
- Playful
- Marketing-driven
- Over-animated
- Ambiguous
- Consumer-social

## Recommended Style Direction

Primary styles:

- Minimalism / Swiss Style
- Accessible & Ethical
- Data-Dense Dashboard
- Real-Time Monitoring
- Executive Dashboard, only for summary areas
- Dimensional Layering, very lightly for hierarchy

Allowed secondary style:

- Bento Grid, only for grouping clear operational panels

Avoid:

- Heavy glassmorphism
- Neumorphism
- Cyberpunk
- AI purple/pink gradients
- Brutalism
- Gen Z chaos / maximalism
- Motion-driven portfolio style
- 3D/hyperrealism
- Decorative gradients that reduce readability
- Low-contrast dark UI

## Visual Hierarchy

The hierarchy must be:

1. Current phase
2. Overall job progress
3. Project ETA / Whole Job ETA
4. SAFE TO EJECT status
5. Source and destination identity
6. Warnings/errors
7. Current file details
8. Report availability
9. Secondary metadata

## Color Principles

Use color semantically.

Color must communicate state:

- Neutral: idle, setup, waiting
- Active: copying, verifying
- Success: verified and SAFE TO EJECT
- Warning: non-blocking issue
- Error: blocking issue
- Blocked: not safe

Do not rely on color alone.

Every critical color state must also have text.

## Typography Principles

Typography should prioritize readability and density.

Use system-native macOS typography where possible.

Avoid decorative fonts.

Recommended approach:

- Use SF Pro / system font
- Clear section headers
- Monospaced style only for paths, logs, technical values, checksums, or report-like evidence
- Avoid oversized marketing headings

## Spacing and Density

FST should support dense operational information without feeling cramped.

Use:

- Clear grouping
- Consistent spacing
- Strong alignment
- Compact metadata rows
- Larger emphasis only for phase/progress/safety state

Avoid:

- Huge empty hero sections
- Marketing-style spacing
- Decorative cards that waste space

## Motion

Motion must be functional.

Allowed:

- Subtle progress animation
- State transition feedback
- Spinner only when meaningful

Avoid:

- Decorative motion
- Long animations
- Motion that hides state changes
- Motion that ignores reduced motion settings

Respect reduced motion preferences.

## Accessibility

Minimum requirements:

- Text contrast suitable for operational use
- Critical states readable without color
- Focus states visible
- Keyboard navigation not broken
- Warnings/errors announced clearly in text
- Reduced motion respected
- Small text avoided for critical values

## SwiftUI Guidance

For SwiftUI implementation:

- Keep views composable.
- Keep core safety logic out of views.
- Use presentation ViewModels only for UI state mapping.
- UI must not fake backend state.
- Use canonical job state from core.
- Keep Current File secondary to Project ETA.
- Never derive SAFE TO EJECT visually without backend state.

## FST-Specific Anti-Patterns

Do not:

- Show per-file ETA as Project ETA.
- Hide stalled progress.
- Make failed state look similar to success.
- Use vague wording such as "Looks good" or "Probably done".
- Display SAFE TO EJECT before verify pass.
- Bury warnings/errors below fold.
- Use decorative badges for safety-critical state.
- Make source/destination paths hard to inspect.
- Let UI polish reduce operator confidence.

## Pre-Delivery UI Checklist

Before accepting UI work, check:

- [ ] Current phase is visible.
- [ ] Project ETA / Whole Job ETA is visible when available.
- [ ] Current file is secondary.
- [ ] Source is visible.
- [ ] Destination is visible.
- [ ] SAFE TO EJECT state is visible.
- [ ] Warnings are visible.
- [ ] Errors are visible.
- [ ] Failed state cannot be mistaken for success.
- [ ] Cancel state cannot be mistaken for completion.
- [ ] UI remains responsive during copy/verify.
- [ ] UI does not fake backend state.
- [ ] Reduced motion is respected.
- [ ] Critical text has sufficient contrast.
- [ ] Buttons have clear enabled/disabled states.

