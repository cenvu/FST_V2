# FST - Project Master Guideline

Version: 2026-06-21  
Status: Architecture Locked  
Codename: FishSock Transfer / Focused Secure Transfer

---

## 1. Intent

Build a safe native macOS DIT media offload tool.

Workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT / OPERATOR HANDOFF
```

FST does not format cards or media. The app exists to provide copy and verification evidence for operator handoff.

Data safety beats speed, UI convenience, and clever code.

---

## 2. Doctrine

Every feature must reduce media-loss risk. If not, reject.

Priority order:

```text
Data Safety -> Reliability -> Repeatability -> Maintainability -> Performance -> Convenience
```

Rules:

- Simple beats clever.
- Predictable beats magical.
- Logs beat guesses.
- Explicit beats abstract.
- Tests beat confidence.

---

## 3. Repository Doctrine

Docs and app code must be separated.

Correct layout:

```text
FST_V2/
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
  README.md
```

Rules:

- `docs/` contains active project documentation.
- `docs/archive/` contains old docs only.
- `FishSockTransfer/FishSockTransfer/` contains app source code only.
- Do not place guide docs inside the app source folder.
- Old React/Vite prototype files must not be treated as production SwiftUI app code.

---

## 4. Technical Baseline

- macOS 13+
- Apple Silicon first
- Swift 5.9+ / Swift 6 compatible
- SwiftUI
- MVVM + Coordinator + Engine + Service
- bundled rsync 3.4.4
- xxHash64 verification
- one source
- one destination
- one active job
- folder transfer
- speed limit
- logs
- TXT report

Out of MVP:

- queue
- multi-job
- multi-destination
- mirror copy
- cloud sync
- database/history engine
- DAM/MAM
- proxy generation
- MHL
- LTO
- AI inside app

---

## 5. Threat Model

Production storage can fail under sustained load.

Risks:

- cache exhaustion
- thermal throttling
- USB disconnect
- controller instability
- bus power drop
- I/O timeout
- write speed collapse
- operator misread

Mitigation:

- speed control
- storage validation
- progress visibility
- verification
- logs
- cancellation safety
- unambiguous final state

---

## 6. Architecture Law

Only allowed flow:

```text
SwiftUI View -> TransferViewModel -> TransferCoordinator -> Engines -> Services
```

Current engine layer:

- `RsyncEngine`
- `ProgressParser`
- `VerifyEngine`
- `ReportEngine`
- `TransferEvent`
- `VerificationEvent`

Current service layer:

- `BundledRsyncService`
- `DriveService`
- `BookmarkService`
- `LoggerService`

Forbidden:

- View calls Engine or Service
- ViewModel launches process
- Engine imports SwiftUI
- Service changes workflow state
- hidden global workflow state

---

## 7. Layer Duties

| Layer | Owns | Must Not Do |
|---|---|---|
| View | layout, rendering, user events | workflow, rsync, hashing |
| ViewModel | published UI state, bindings, formatting | filesystem, rsync, state machine |
| Coordinator | validation, orchestration, transitions, error mapping | UI rendering |
| Engine | transfer, parsing, verify, report | UI state |
| Service | OS APIs, process, bookmarks, logs | workflow decisions |
| Model | data contracts | side effects |

---

## 8. State Machine

Allowed states:

```text
ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled
```

Note: `safeToFormat` is a legacy internal state name for verified success. Operator-facing UI, logs, and reports must say SAFE TO EJECT.

Rules:

- one active state
- Coordinator owns transitions
- no added or renamed states
- no skipped validation

Safe To Eject rule:

```text
copy success AND verification pass
```

Verification none:

```text
copyComplete only
```

---

## 9. Transfer Rules

Use bundled rsync 3.4.4.

Must:

- resolve path
- validate executable
- report rsync version separately from app version
- capture stdout/stderr
- support cancellation
- emit progress
- map errors for operators
- never mutate source

Forbidden:

- silent `/usr/bin/rsync` fallback
- destructive flags
- undocumented exclusions
- fake success state

Bandwidth:

- 50 MB/s
- 120 MB/s
- 240 MB/s
- Unlimited
- custom 20...300 MB/s

Unlimited means no `--bwlimit`.

Conversion must be tested.

Audit:

- speed limiter
- `.DS_Store` hang
- progress parser
- rsync path/version

---

## 10. Verification Rules

Modes:

```text
none, random33, full
```

Algorithms:

```text
random33 -> SHA256
full -> xxHash64
```

Rules:

- `none` ends COPY COMPLETE
- `random33` samples about one third with SHA256
- `full` checks all files with xxHash64 fast non-cryptographic verification
- failed verification blocks SAFE TO EJECT
- no MD5/CRC32/MHL unless spec changes

---

## 11. UI Rules

DIT must understand app in 30 seconds.

Main UI must show:

- source
- destination
- storage readiness
- bandwidth
- verification mode
- state
- progress
- current speed
- average speed
- ETA if available
- current file if available
- logs
- start/stop/report actions
- final status

Final status must be impossible to misread.

---

## 12. Logging and Report

Logs:

- real time
- auto-scroll
- monospaced
- TXT export

Categories:

```text
INFO, WARNING, ERROR, TRANSFER, VERIFY, SYSTEM
```

Report:

```text
TXT only
```

Include:

- date/time
- app version
- rsync version
- source
- destination
- file count
- total size
- bandwidth limit
- duration
- average speed
- verification mode/result
- error count
- final state

Report must never overstate safety.

---

## 13. Performance

MainActor:

- UI updates only

Background:

- rsync
- hashing
- scanning
- logging
- reports

Targets:

- UI CPU under 5%
- memory under 300 MB
- no busy loops
- no polling loops
- no main-thread blocking

---

## 14. Development Rules

Use:

- explicit names
- small files
- guard clauses
- async/await
- actors where shared mutable state exists
- tests for engines/parsers/coordinators

Avoid:

- `Helpers.swift`
- `Utils.swift`
- vague `Manager` types
- DI frameworks
- unnecessary protocols
- god classes
- undocumented rsync flags
- silent failures

No new dependency unless it clearly reduces data-loss risk.

---

## 15. Current Audit Checklist

Verify before claiming stable:

- [ ] bundled rsync path correct
- [ ] rsync version correct
- [ ] app version separate from rsync version
- [ ] speed limiter numeric value correct
- [ ] unlimited removes bandwidth flag
- [ ] `.DS_Store` cannot hang transfer
- [ ] progress/speed/ETA credible
- [ ] cancellation creates no false success
- [ ] verification none never shows SAFE TO EJECT
- [ ] verification pass required for SAFE TO EJECT
- [ ] logs survive failure
- [ ] TXT report reflects final truth

---

## 16. Success

A first-time DIT can launch, select source, select destination, choose speed, choose verification, start transfer, and read final status without training.

If final status is unsafe, unclear, or ambiguous, the product has failed.
