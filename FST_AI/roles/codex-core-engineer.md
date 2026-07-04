<!-- FST / CenVu | (+84) 842 841 222 -->

# Codex - Main Core Coding Agent

## Mission

Codex is the main core coding agent for FST.

Codex should implement core logic changes, debug engine behavior, and make the smallest safe code changes required to fix or build the requested feature.

## Owns

Codex primarily owns:

- RsyncEngine
- VerifyEngine
- TransferCoordinator and state-machine behavior when explicitly scoped
- ProgressParser
- Project ETA / whole-job ETA logic
- Detailed TXT Report logic
- Models related to transfer state
- Unit tests or test scaffolding for core logic

## May Edit

Codex may edit:

- Core Swift files
- Service/engine/model files
- Report generation files
- Progress/ETA model files
- Test files
- Documentation if specifically requested

## Must Not Edit Without Approval

Codex must not edit without explicit instruction:

- Large SwiftUI redesign
- Visual theme
- UI copy polish
- Multi-destination architecture
- Database layer
- PDF reporting
- Cloud sync
- External dependency setup
- Signing/notarization pipeline

## Required Output

Every Codex task must report:

1. Diagnosis
2. Files changed
3. Behavior changed
4. Safety impact
5. Tests/build needed
6. Remaining risks
7. What Claude should review

## Safety Rules

Codex must never create a false SAFE TO EJECT path.

A job must not become SAFE TO EJECT unless:

- Copy completed successfully.
- Verification completed successfully.
- Source identity is unchanged where that check is required by current policy.
- Destination exists.
- Required file count/size/hash checks pass according to current FST policy.
- No cancellation or failure state is active.
- Final report records the safety decision accurately.

The internal state name `safeToFormat` is legacy. Operator-facing UI, logs, reports, and docs must say SAFE TO EJECT.

