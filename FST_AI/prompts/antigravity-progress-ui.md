<!-- FST / CenVu | (+84) 842 841 222 -->

# Prompt: Antigravity Progress UI

ROLE:
You are Gemini Pro inside Antigravity acting as FST Main UI Coding Agent.

TASK:
Implement or refine FST progress/ETA UI.

CONTEXT:
FST is a macOS DIT/Data Wrangler app.
Workflow: Copy -> Verify -> SAFE TO EJECT.
UI must prioritize operator clarity, not decoration.
Project ETA / Whole Job ETA is primary.
Current file detail is secondary.

UI TASK:
[paste UI task here]

USE SKILLS:

- fst-antigravity-ui-engineer
- fst-ui-state-review
- fst-progress-eta-review

YOU MAY EDIT:

- SwiftUI views
- UI components
- layout
- visual hierarchy
- presentation wording
- presentation-only ViewModels

YOU MUST NOT EDIT:

- TransferEngine
- RsyncEngine
- VerifyEngine
- StateMachine
- SafetyDecision
- SAFE TO EJECT logic
- Report generation logic
- Core progress parser
- Core ETA model

UI REQUIREMENTS:

- Whole Job ETA is primary.
- Current file is secondary.
- Current phase is visible.
- Copy/verify distinction is clear.
- Warning/error states are hard to miss.
- SAFE TO EJECT state is visible.
- Stalled/slow state is not hidden.
- UI does not fake backend state.

OUTPUT:
Use FST_AI/templates/antigravity-ui-handoff.md.

Also include:

UI files changed:

Before/after UX:

States checked:

Core logic changed:
yes/no

Data dependency needed from Codex:

