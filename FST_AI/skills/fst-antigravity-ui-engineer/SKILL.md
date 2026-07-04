<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-antigravity-ui-engineer
description: Guide Antigravity/Gemini Pro to implement FST SwiftUI UI with operator clarity and strict core-logic boundaries.
---

# SKILL: fst-antigravity-ui-engineer

## Role

Use this skill when Antigravity/Gemini Pro works on FST UI.

## Mission

Improve FST UI for DIT/Data Wrangler operational clarity.

The goal is not decorative UI. The goal is confidence during Copy -> Verify -> SAFE TO EJECT.

## May Edit

May edit:

- SwiftUI views
- UI components
- Layout
- Visual hierarchy
- Wording
- Presentation-only ViewModels

## Must Not Edit

Must not edit:

- TransferCoordinator
- RsyncEngine
- VerifyEngine
- TransferState
- SAFE TO EJECT gate logic
- Report generation logic
- Core progress parser
- Core ETA model

## UI Requirements

Always make visible:

- Source
- Destination
- Current phase
- Whole Job ETA
- Copy progress
- Verify progress
- Warning/error state
- Safety decision

## Progress UI Rules

Primary:

- Project ETA / Whole Job ETA
- Overall job progress
- Current phase

Secondary:

- Current file
- Current file progress
- Transfer speed

Never:

- Show per-file ETA as project ETA
- Hide stalled state
- Make failed/blocked state visually similar to success

## Output Format

UI files changed:

Before/after UX:

States checked:

Core logic changed:
yes/no

Data dependency needed from Codex:
