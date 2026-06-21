# FST - Project Master Guideline

Version: 2.2 Architecture Locked  
Codename: FishSock Transfer / Focused Secure Transfer

## Intent

Build a safe macOS DIT media offload tool.

Workflow: SOURCE -> COPY -> VERIFY -> SAFE TO FORMAT

The app exists to prove whether source media can be erased.

Data safety beats speed, UI convenience, and clever code.

## Doctrine

Every feature must reduce media-loss risk. If not, reject.

Priority: Data Safety -> Reliability -> Repeatability -> Maintainability -> Performance -> Convenience.

Simple beats clever. Predictable beats magical. Logs beat guesses.

## Baseline

- macOS 13+, Apple Silicon first
- Swift 5.9+, SwiftUI
- MVVM + Coordinator + Engine + Service
- bundled rsync 3.4.4
- xxHash64 verification
- one source, one destination, one active job
- folder transfer, speed limit, logs, TXT report

Out of MVP: queue, multi-job, multi-destination, mirror, cloud, database, DAM/MAM, proxy, MHL, LTO, AI inside app.

## Threat Model

Production storage can fail under sustained load.

Risks: cache exhaustion, thermal throttling, USB disconnect, controller instability, bus power drop, I/O timeout, write speed collapse, operator misread.

Mitigation: speed control, validation, progress visibility, verification, logs, unambiguous final state.

## Architecture

Only allowed flow:

SwiftUI View -> TransferViewModel -> TransferCoordinator -> Engines -> Services

Engines: RsyncEngine, VerifyEngine, ReportEngine if needed.  
Services: DriveService, ShellService, LoggerService, BookmarkService, NotificationService, RsyncLocator/VersionService if needed.

Forbidden: View calls Engine/Service, ViewModel launches process, Engine imports SwiftUI, Service changes workflow state, hidden globals.

## Layer Duties

| Layer | Owns | Must not do |
|---|---|---|
| View | layout, rendering, user events | workflow, rsync, hashing |
| ViewModel | published UI state, bindings, formatting | filesystem, rsync, state machine |
| Coordinator | validation, orchestration, transitions, error mapping | UI rendering |
| Engine | transfer, verify, progress, cancel | UI state |
| Service | OS APIs, process, bookmarks, logs | workflow decisions |

## State Machine

Allowed states:

ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled

Rules: one active state; Coordinator owns transitions; no added/renamed states; no skipped validation.

SAFE TO FORMAT = copy success AND verification pass.  
Verification none = copyComplete only.

## Transfer Rules

Use bundled rsync 3.4.4.

Must resolve path, report rsync version separately from app version, capture stdout/stderr, support cancellation, emit progress, map errors for operators, and never mutate source.

No Apple `/usr/bin/rsync` fallback unless future spec allows it.

Bandwidth: 50, 120, 240 MB/s, unlimited, custom 20-300 MB/s.  
Unlimited = no `--bwlimit`. Conversion must be tested.

Audit: speed limiter, `.DS_Store` hang, progress parser, rsync path/version.

## Verification Rules

Modes: none, random33, full.  
Algorithm: xxHash64.

Rules: none ends COPY COMPLETE; random33 samples about one third; full checks all; failed verification blocks SAFE TO FORMAT; no SHA256/MD5/CRC32/MHL unless spec changes.

## UI Rules

DIT must understand app in 30 seconds.

Main UI: source, destination, bandwidth, verification mode, status, logs, start, stop, export report.

Show progress percent, current speed, average speed, ETA, current file when available, state, final status.

Final status must be impossible to misread.

## Logging and Report

Logs: real time, auto-scroll, monospaced, TXT export.

Categories: INFO, WARNING, ERROR, TRANSFER, VERIFY, SYSTEM.

Report: TXT only. Include date/time, source, destination, file count, total size, bandwidth limit, duration, average speed, verification mode/result, error count, final status, rsync version, app version.

## Performance

MainActor: UI updates only.

Background: rsync, hashing, scanning, logging, reports.

Targets: UI CPU under 5%, memory under 300 MB, no busy loops, no polling loops, no main-thread blocking.

## Development Rules

Use explicit names, small files, guard clauses, async/await, actors for shared mutable state, tests for engines/parsers/coordinators.

Avoid Helpers, Utils, Managers, DI frameworks, unnecessary protocols, god classes, undocumented flags, silent failures.

No new dependency unless it clearly reduces data-loss risk.

## Current Audit Checklist

Verify before claiming stable:

- bundled rsync path correct
- rsync version correct
- app version separate from rsync version
- speed limiter numeric value correct
- unlimited removes bandwidth flag
- `.DS_Store` cannot hang transfer
- progress/speed/ETA credible
- cancellation creates no false success
- verification none never shows SAFE TO FORMAT
- verification pass required for SAFE TO FORMAT
- logs survive failure
- TXT report reflects final truth

## Success

A first-time DIT can launch, select source, select destination, choose speed, choose verification, start transfer, and read final status without training.

If final status is unsafe, unclear, or ambiguous, the product has failed.
