# FST Product Specification

Version: 2026-10-03
Status: Current Product Scope
Platform: macOS 13.5+  
Language: Swift 5.9+ / Swift 6 compatible  
Framework: SwiftUI  
Architecture: MVVM + Coordinator + Engine + Service

---

## 1. Product Mission

FST is a native macOS media offload application for DITs, Data Wranglers, and production crews.

It exists to answer one question:

```text
Can the source media be safely ejected and handed off?
```

FST does not format cards or media. It provides copy and verification evidence for operator handoff.

Workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT / OPERATOR HANDOFF
```

Product priority:

```text
Data Integrity -> Reliability -> Transparency -> Simplicity -> Performance -> Extra Features
```

FST is not a DAM, MAM, cloud sync app, project manager, media browser, database.

---

## 2. Field Problem

Production media is commonly copied from camera cards, SSDs, NVMe enclosures, USB-C docks, card readers, and bus-powered drives.

Common risks:

- write cache exhaustion
- thermal throttling
- USB disconnects
- controller instability
- bus power drop
- read/write I/O errors
- sustained write collapse
- operator misread of final status

FST reduces risk through:

- controlled transfer speed
- explicit storage validation
- real-time progress and logs
- verification
- cancellation safety
- clear final state
- TXT transfer report

---

## 3. Target Users

Primary:

- DIT
- Data Wrangler
- Assistant DIT

Secondary:

- Assistant Editor
- Production Assistant
- small production team

Success:

A first-time operator can launch FST, select source, select destination, choose speed, choose verification mode, start transfer, and understand the final result without documentation.

---

## 4. Product Scope

### In Scope

- one source folder
- one destination folder
- one active job
- drag/drop and folder picker
- security-scoped bookmarks
- storage validation
- bundled rsync 3.4.4 transfer
- bandwidth control
- real-time monitoring
- cancellation
- SHA256 sample verification and xxHash64 full verification
- logs
- TXT report
- SAFE TO EJECT only after successful copy and required verification

### Out of Scope

- transfer queue
- multiple simultaneous jobs
- multiple destinations
- mirrored copy
- NAS/RAID/LTO/MHL/proxy workflows
- DAM/MAM features
- metadata browser
- history database
- cloud/team collaboration

---

## 5. Current Technical Baseline

Current release:

- Version: v1.4.0 display 1.4.0 build 20261003
- Apple Silicon package: `FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-arm64.zip`
- Intel package: `FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-x86_64.zip`
- Package type: separate architecture-specific ZIPs
- Platform: macOS 13.5+, Apple Silicon arm64 and Intel x86_64 (separate packages)
- Signing: ad-hoc signed, not notarized, not Developer ID signed
- Scope: one source, one destination, one active job
- Successful verified copy: SAFE TO EJECT; copy-only success: TRANSFER COMPLETE

Current repository structure expects:

```text
FST_V2/
  docs/
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
```

Production transfer uses bundled rsync 3.4.4.

Rules:

- Do not silently fallback to Apple `/usr/bin/rsync`.
- Do not silently fallback to Homebrew, MacPorts, or any non-bundled rsync.
- Display/log app version and rsync version separately.
- Use dependency flow: View -> ViewModel -> Coordinator -> Engine -> Service.
- Never mutate source media.
- Never run rsync, hashing, scanning, or report generation on MainActor.

Notification delivery and observer metrics are estimates/visibility tools. They must never mark copy success, verification success, or SAFE TO EJECT.

---

## 6. Functional Requirements

### FR-001 Source Selection

User can select source by drag/drop or folder picker.

Validation:

- exists
- is folder
- readable
- not empty
- single source only

Reject:

- files
- missing paths
- unreadable folders
- empty folders
- multiple sources

### FR-002 Destination Selection

User can select destination by drag/drop or folder picker.

Validation:

- exists
- is folder
- writable
- sufficient free space
- single destination only

Reject:

- multiple destinations
- mirrored destinations
- unwritable destinations
- destinations with insufficient free space

### FR-003 Persistent Access

Use security-scoped bookmarks.

Must:

- save source and destination access
- restore after relaunch
- handle stale bookmarks
- show clear failure if access is lost

### FR-004 Storage Validation

Before transfer calculate:

- source size
- destination free space
- remaining free space after copy

Start is disabled when:

- source invalid
- destination invalid
- destination space insufficient
- transfer already active

### FR-005 Transfer Execution

Use bundled rsync 3.4.4 through `BundledRsyncService`.

Must:

- resolve bundled binary path
- validate executable permission
- validate rsync version
- capture stdout and stderr
- drain stdout and stderr continuously during copy
- parse progress
- support cancellation
- log path/version
- report exit status
- preserve source media

Runtime requirements:

- bundled rsync 3.4.4 path/version detection is required
- app version and rsync version must remain separate
- speed limiter conversion must remain tested
- `.DS_Store` handling must not stall transfer
- progress/log streaming must remain realtime

### FR-006 Bandwidth Control

Presets:

- 50 MB/s
- 75 MB/s
- 100 MB/s
- 125 MB/s
- 150 MB/s
- 175 MB/s
- 200 MB/s
- Unlimited

NO CUSTOM BANDWIDTH CONTROL.

Rules:

- Unlimited omits `--bwlimit`.
- UI label must match actual limit.
- Convert UI MB/s to rsync argument consistently.
- Conversion requires tests.

### FR-007 Transfer Monitoring

Display:

- transfer state
- progress percent
- current speed
- average speed
- ETA if known
- current file if available
- logs

Progress must be based on real rsync output and process status. Do not fake success.

High-File-Count / CinemaDNG Behavior:
- FST must remain readable for cinema jobs containing roughly 40k–50k files.
- DNG/CinemaDNG frame churn should be suppressed from compact Current Item presentation.
- Video/clip-style media and useful clip-level RAW may remain eligible for compact current-item display.
- Exact media-extension policy is an implementation decision requiring real production samples (do not invent taxonomy without evidence).
- Advanced/technical surfaces may expose exact current filenames.

ETA requirements:
- ETA should respond to transfer conditions and remain an estimate.
- Normal estimation warm-up <= 120 seconds.
- Adaptation <= 10 seconds after a material sustained throughput change.
- Never show per-file ETA as whole-job ETA.
- Never leave stale ETA presented as current.
- ETA must never determine transfer success or SAFE TO EJECT.
- Preferred display: ~18 min remaining. Warm-up display: Estimating...
- If unable to estimate, use a truthful degraded state (e.g. ETA unavailable) rather than indefinite Estimating.

### FR-008 Cancellation

User can cancel active copy or verification.

Must:

- terminate rsync safely
- preserve logs
- set state to `cancelled`
- never show SAFE TO EJECT after cancel
- keep UI responsive

### FR-009 Verification

Presentation labels:
- COPY ONLY — Fastest
- SAMPLE 33% — Balanced
- FULL 100% — Verify all files

Backend Modes:

```text
none, random33, full
```

Algorithms:

```text
random33 -> SHA256
full -> xxHash64
```

Rules:

- `none` skips hashing and ends at TRANSFER COMPLETE.
- `random33` verifies about one third of transferred files with SHA256.
- `full` verifies all transferred files with xxHash64 fast non-cryptographic verification.
- Any failure blocks SAFE TO EJECT.
- No MD5, CRC32, or MHL verification.

### FR-010 SAFE TO EJECT

Absolute rule:

```text
SAFE TO EJECT = copy success AND verification success
```

If verification mode is `none`:

```text
Final state = TRANSFER COMPLETE
Never SAFE TO EJECT
```

No operator override. No warning bypass. No auto-approval.

Final status labels:

- Copy-only success with verification disabled = TRANSFER COMPLETE
- Verified success = SAFE TO EJECT
- Verification failure = MANUAL CHECK REQUIRED
- Transfer, preflight, or rsync failure = TRANSFER ERROR
- Cancelled = CANCELLED

Error Presentation (Two-layer model):
- Layer 1: human-readable problem/action.
- Layer 2: technical detail / diagnostic code + route to Technical Log.
- Warnings and blocking errors must appear inline on Transfer.
- Do not hide blocking information behind tabs.

### FR-011 Logging

Required:

- real-time logs
- auto-scroll
- monospaced display
- TXT export
- UI Technical Logs hide DIAG entries by default
- Show Diagnostics reveals full diagnostic logs

Categories:

```text
INFO, WARNING, ERROR, TRANSFER, VERIFY, SYSTEM
```

Must log:

- app launch
- source selected
- destination selected
- rsync path/version
- validation start/pass/fail
- transfer start/end/fail
- cancellation
- verification start/pass/fail
- report export

### FR-012 Transfer Report

TXT only.

Must include:

- date/time
- app version
- bundled rsync version
- source path
- destination path
- total size
- file count
- bandwidth limit
- copy duration
- verify duration, or N/A when verification is disabled
- total duration
- copy average speed
- verification mode
- verification result
- error count
- final state
- FULL TECHNICAL LOG section when logs are available

Report must never claim SAFE TO EJECT unless Coordinator state is the internal legacy `safeToFormat` state.

---

## 7. State Machine

Allowed states:

```text
ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled
```

Note: `safeToFormat` is a legacy internal state name for verified success. It must not be displayed to operators; use SAFE TO EJECT in UI, logs, reports, and docs.

Rules:

- Only `TransferCoordinator` changes state.
- One active state only.
- No new states without spec update.
- No skipped validation.

Success flows:

```text
ready -> validating -> copying -> verifying -> safeToFormat
ready -> validating -> copying -> copyComplete  // verification none
```

Failure flows:

```text
validating -> error
copying -> error | cancelled
verifying -> error | cancelled
```

---

## 8. Non-Functional Requirements

Stability:

- target zero crashes during 8-hour transfer session

Performance:

- UI CPU below 5%
- memory below 300 MB during normal operation
- no MainActor blocking
- no busy loops
- no polling loops for parsing

Compatibility:

- Current v1.4.0: macOS 13.5+, Apple Silicon arm64 and Intel x86_64 in separate ZIPs
- Each architecture requires its matching bundled rsync 3.4.4 runtime
- Never achieve Intel support by silent fallback

Maintainability:

- explicit names
- small files
- no god objects
- no unnecessary dependencies
- no undocumented transfer behavior

---

## 9. Acceptance Criteria

The product must meet these requirements:

- picker and drag/drop work
- bookmarks restore access
- storage validation blocks unsafe start
- bundled rsync path/version are correct
- app version and rsync version are separate
- speed limiter is accurate
- metadata-only folders cannot stall transfer
- progress, speed and ETA reflect the transfer
- cancellation cannot create false success
- verification none ends TRANSFER COMPLETE
- random33 verification works
- full verification works
- SAFE TO EJECT cannot bypass verification
- logs and TXT report reflect the final result
- production-scale transfer test passes without crash

---

## 10. Final Product Rule

If the final status is ambiguous, unsafe, or misleading, the product has failed.
