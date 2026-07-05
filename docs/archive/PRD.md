<!-- FST / CenVu | (+84) 842 841 222 -->

# PRD - FST Focused Secure Transfer

Version: 2.2 MVP Locked  
Platform: macOS 13+  
Language: Swift 5.9+  
Framework: SwiftUI  
Architecture: MVVM + Coordinator + Engine + Service

## Mission

FST is a macOS DIT/Data Wrangler media offload app.

Workflow: COPY -> VERIFY -> SAFE TO EJECT

Purpose: let the operator know when source media is safe to erase.

FST prioritizes: Data Integrity -> Reliability -> Transparency -> Simplicity -> Performance -> Extra Features.

## Problem

Production media is copied from SSDs, NVMe enclosures, docks, card readers, and bus-powered drives.

Risks: cache exhaustion, thermal throttling, USB disconnect, controller instability, power drop, I/O timeout, sustained speed collapse.

FST reduces risk with controlled transfer speed, visible progress, verification, logs, and clear final status.

## Users

Primary: DIT, Data Wrangler, Assistant DIT.  
Secondary: Assistant Editor, PA, small production team.

Success: first-time user can select source/destination, start transfer, and understand final result without documentation.

## MVP Scope

In:

- folder source/destination
- drag/drop and picker
- security scoped bookmarks
- storage validation
- one source, one destination, one active job
- bundled rsync 3.4.4 transfer
- bandwidth control
- real-time monitoring
- cancellation
- xxHash64 verification
- logs
- TXT report
- SAFE TO EJECT gate

Out:

- queue, multi-job, multi-destination, mirrored copy
- NAS/RAID/LTO/MHL/proxy
- DAM/MAM/metadata browser/database
- cloud/team collaboration
- AI features inside app

## Technical Baseline

- Use bundled rsync 3.4.4.
- Do not fall back to Apple `/usr/bin/rsync` unless future spec allows it.
- Show/log app version and rsync version separately.
- Architecture flow: View -> ViewModel -> Coordinator -> Engine -> Service.
- No source mutation.
- No workflow in View.
- No rsync in ViewModel.
- No SwiftUI in Engine.

## Functional Requirements

### FR-001 Source Selection

Select by drag/drop or picker.

Validate: exists, folder, readable, not empty.

Reject files, missing paths, unreadable folders, empty folders, multiple sources.

### FR-002 Destination Selection

Select by drag/drop or picker.

Validate: exists, folder, writable, enough free space.

Reject multiple destinations and mirrored targets.

### FR-003 Persistent Access

Use security scoped bookmarks.

Must restore access after relaunch, handle stale bookmarks, and show clear failure if access is lost.

### FR-004 Storage Validation

Before transfer calculate source size, destination free space, and remaining free space.

Disable Start when source invalid, destination invalid, free space insufficient, or transfer active.

### FR-005 Transfer Execution

Use bundled rsync 3.4.4.

Must preserve source, capture stdout/stderr, parse progress, support cancellation, log rsync path/version, and report exit status.

Current audit: speed limiter conversion, `.DS_Store` hang, progress accuracy, rsync binary/version detection.

### FR-006 Bandwidth Control

Presets: 50, 120, 240 MB/s, unlimited.  
Custom: 20-300 MB/s.

Rules: unlimited means no `--bwlimit`; UI label must match actual limit; conversion must be tested.

### FR-007 Transfer Monitoring

Show progress percent, current speed, average speed, ETA, current file when available, and current state.

Parsing and calculations must not block MainActor.

### FR-008 Cancellation

Cancel active transfer safely.

Must terminate rsync, preserve logs, update state to cancelled, and never show SAFE TO EJECT after cancel.

### FR-009 Verification

Modes: none, random33, full.  
Algorithm: xxHash64.

Rules: random33 checks about 33% of transferred files; full checks all files; failure blocks SAFE TO EJECT; no SHA256/MD5/CRC32 in MVP.

### FR-010 SAFE TO EJECT

Allowed only when copy succeeded AND verification passed.

If verification is none: final state is COPY COMPLETE; never SAFE TO EJECT.

Absolute rule.

### FR-011 Logging

Real-time, auto-scroll, monospaced, TXT export.

Categories: INFO, WARNING, ERROR, TRANSFER, VERIFY, SYSTEM.

Must log transfer start/end/fail, verification start/end/fail, cancellation, rsync path/version, report export.

### FR-012 Transfer Report

TXT only.

Include date/time, source, destination, total size, file count, bandwidth limit, duration, average speed, verification mode/result, error count, final status, rsync version, app version.

## State Machine

Allowed states:

ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled

Only Coordinator changes state. One active state only. No new states without spec change.

## Non-Functional Requirements

Stability: target zero crashes during 8-hour transfer session.

Performance: UI CPU under 5%, memory under 300 MB, no MainActor blocking, no busy loops.

Compatibility: macOS 13 Ventura, 14 Sonoma, 15 Sequoia. Apple Silicon priority. Intel optional.

Maintainability: explicit names, small files, no god objects, no unnecessary dependencies.

## MVP Exit Criteria

MVP is complete only when:

- picker and drag/drop work
- bookmarks restore access
- storage validation blocks unsafe start
- bundled rsync path/version are correct
- app version and rsync version are separate
- speed limiter is accurate
- `.DS_Store` hang is fixed or safely mitigated
- progress is operator-trustworthy
- random33/full/none verification work
- verification none ends COPY COMPLETE
- SAFE TO EJECT cannot bypass verification
- cancellation cannot create false success
- logs and TXT report reflect final truth
- production-scale transfer test passes without crash
