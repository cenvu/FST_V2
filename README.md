# FST - FishSock Transfer

FST / FishSock Transfer is a native macOS media offload app for DITs, Data Wranglers, and production crews.

It exists to answer one question:

```text
Can the source media be safely ejected and handed off?
```

FST does not format cards or media. It provides copy and verification evidence for operator handoff.

Workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT / OPERATOR HANDOFF
```

Priority:

```text
Data Safety -> Reliability -> Repeatability -> Maintainability -> Performance -> Convenience
```

If the final status is unclear, unsafe, or misleading, the product has failed.

---

## Current Status

FST is in MVP development.

Current focus:

- bundled rsync 3.4.4 validation
- transfer pipeline correctness
- bandwidth limiter correctness
- progress parser accuracy
- `.DS_Store` hang investigation
- cancellation safety
- SHA256 sample verification and xxHash64 full verification
- Safe To Eject enforcement
- TXT report truthfulness

Do not add feature expansion before these audit targets are stable.

---

## MVP Scope

In scope:

- one source folder
- one destination folder
- one active job
- drag/drop and folder picker
- security-scoped bookmarks
- storage validation
- bundled rsync 3.4.4 transfer
- bandwidth control
- real-time progress and logs
- cancellation
- SHA256 sample verification and xxHash64 full verification
- TXT report
- Safe To Eject gate

Out of scope:

- transfer queue
- multiple simultaneous jobs
- multiple destinations
- mirrored copy
- cloud sync
- DAM/MAM
- database/history engine
- proxy generation
- LTO
- MHL
- AI features inside the app

---

## Technical Baseline

- Platform: macOS 13+
- Language: Swift 5.9+ / Swift 6 compatible
- Framework: SwiftUI
- Architecture: MVVM + Coordinator + Engine + Service
- Transfer engine: bundled rsync 3.4.4 only
- Verification: SHA256 Sample 33% or xxHash64 Full 100%
- Report: plain TXT

Production transfer must not silently fallback to Apple `/usr/bin/rsync`.

---

## Repository Layout

Expected layout:

```text
FST_V2/
  AGENTS.md
  README.md
  docs/
    00_AI_AGENT_START_HERE.md
    01_PRD.md
    02_FST_TECHNICAL_GUIDE.md
    03_PROJECT_MASTER_GUIDELINE.md
    archive/

  FishSockTransfer/
    FishSockTransfer.xcodeproj
    FishSockTransfer/
      Assets.xcassets
      Coordinators/
      Engines/
      Models/
      Services/
      ViewModels/
      Views/
      FishSockTransferApp.swift
      rsync
    Tests/

  assets/
```

Rules:

- Active docs live in `docs/`.
- Swift app code lives in `FishSockTransfer/FishSockTransfer/`.
- Old prototype files must not be treated as production app code.

---

## Active Documentation

Read these files before changing code:

```text
1. AGENTS.md
2. docs/00_AI_AGENT_START_HERE.md
3. docs/01_PRD.md
4. docs/02_FST_TECHNICAL_GUIDE.md
5. docs/03_PROJECT_MASTER_GUIDELINE.md
```

`docs/archive/` is historical only.

---

## Architecture

Allowed dependency flow:

```text
SwiftUI View -> TransferViewModel -> TransferCoordinator -> Engines -> Services
```

Only `TransferCoordinator` may change transfer state.

Allowed states:

```text
ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled
```

Note: `safeToFormat` is a legacy internal state name for verified success. Operator-facing UI, logs, and reports must use SAFE TO EJECT.

Safe To Eject rule:

```text
copy success AND verification pass
```

If verification mode is `none`, final state must be:

```text
copyComplete
```

Never show SAFE TO EJECT after verification `none`, copy failure, verification failure, or cancellation.

---

## Rsync

FST uses bundled rsync 3.4.4 for production transfer.

Required behavior:

- resolve bundled rsync path
- validate executable permission
- validate rsync version
- log rsync path
- log rsync version separately from app version
- capture stdout and stderr
- parse real progress output
- support cancellation
- fail fast if bundled rsync is missing or invalid

Forbidden:

- silent fallback to `/usr/bin/rsync`
- destructive flags
- source mutation
- fake success state

---

## Verification

Supported modes:

```text
none, random33, full
```

Algorithms:

```text
random33 -> SHA256
full -> xxHash64
```

Rules:

- `none` skips hashing and ends at COPY COMPLETE.
- `random33` verifies about one third of files with SHA256.
- `full` verifies all files with xxHash64 fast non-cryptographic verification.
- Any verification failure blocks SAFE TO EJECT.

---

## Development Rules

Keep changes small and auditable.

For coding agents, every implementation response must include:

```text
PHASE:
FILES:
LAYER CHECK:
PATCH:
TESTS:
VERIFY:
```

Do not perform broad rewrites, architecture changes, or feature expansion unless explicitly requested.

---

## Build and Test

Open the Xcode project:

```text
FishSockTransfer/FishSockTransfer.xcodeproj
```

Build and test from Xcode, or use `xcodebuild` once the active scheme is confirmed.

Suggested verification areas:

- `ProgressParserTests`
- `RsyncBandwidthLimitTests`
- `TransferCoordinatorTests`
- `VerifyEngineTests`
- `ReportEngineTests`
- `BundledRsyncServiceTests`

Manual smoke tests:

- small folder transfer
- folder containing `.DS_Store`
- bandwidth-limited transfer
- unlimited transfer
- cancel during copy
- verification `none`
- verification `random33`
- verification `full`
- failed verify must not show SAFE TO EJECT

---

## Final Product Rule

A first-time DIT must be able to launch FST, select source, select destination, choose speed, choose verification mode, start transfer, and understand the final result without training.

Data safety beats speed, UI polish, and clever code.
