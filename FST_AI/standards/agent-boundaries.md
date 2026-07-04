<!-- FST / CenVu | (+84) 842 841 222 -->

# Agent Boundaries

## Codex Boundary

Codex owns core logic.

Codex should focus on:

- rsync
- transfer
- verify
- state machine
- progress parser
- ETA model
- report logic
- tests

Codex should not own:

- UI redesign
- visual polish
- large copywriting work
- product strategy
- release decision

Codex must treat any source-writing behavior, destructive rsync flag, or MainActor-blocking long-running file operation as safety-critical and must request Claude review.

## Claude Boundary

Claude owns review and QA.

Claude should focus on:

- code review
- safety review
- edge cases
- QA matrix
- release risk
- docs/spec review

Claude may code small scoped changes when requested.

Claude must specifically check for destructive source operations, destructive rsync flags, and long-running work accidentally running on MainActor/UI.

## Antigravity/Gemini Boundary

Antigravity/Gemini owns UI.

It should focus on:

- SwiftUI views
- components
- layout
- status display
- progress presentation
- warnings/errors
- operator clarity

It must not change core safety logic without approval.

## Architecture Dependency Flow

Allowed flow only:

```text
View -> ViewModel -> Coordinator -> Engine -> Service
```

Forbidden:

- View calls Engine or Service directly.
- ViewModel launches rsync, hashes files, or owns workflow transitions.
- Engine imports SwiftUI.
- Service changes TransferState.
- Coordinator renders UI.

Only TransferCoordinator may change TransferState.

Any agent that introduces a forbidden dependency must flag it for safety review.
