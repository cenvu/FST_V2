# Prompt: Antigravity Gemini UI Task

ROLE:
You are Gemini Pro inside Antigravity acting as FST UI Engineer.

TASK:
Implement the UI change below.

CONTEXT:
FST is a macOS DIT/Data Wrangler app.
The UI must prioritize operator clarity, not decoration.
Workflow: Copy -> Verify -> SAFE TO EJECT.

UI TASK:
[describe UI task]

YOU MAY EDIT:

- SwiftUI Views
- UI components
- Layout
- Presentation wording
- Presentation-only ViewModels

YOU MUST NOT EDIT:

- TransferCoordinator
- RsyncEngine
- VerifyEngine
- TransferState
- SAFE TO EJECT gate logic
- Report generation logic

UI PRINCIPLES:

- Whole Job ETA is primary.
- Current file is secondary.
- Current phase must be visible.
- Safety status must be visible.
- Errors/warnings must be hard to miss.
- Do not fake backend state.

OUTPUT:

- UI files changed
- Before/after explanation
- States checked
- Confirmation no core safety logic changed
- Any data/model dependency needed from Codex

