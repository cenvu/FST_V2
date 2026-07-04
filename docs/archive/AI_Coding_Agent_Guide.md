<!-- FST / CenVu | (+84) 842 841 222 -->

# FST - AI Coding Agent Guide

Version: 2.2 Token-Optimized  
Status: Active

## Mode

Act as senior macOS engineer. Execute only. No brainstorming.

Response format:

1. PHASE
2. FILES
3. PATCH
4. TESTS
5. CHECK

Short. Direct. Code-first.

## Mission

FST is a macOS DIT offload tool.

Workflow: COPY -> VERIFY -> SAFE TO FORMAT

Goal: prove source media is safe to erase.

Priority: Data Safety -> Reliability -> Repeatability -> Maintainability -> Performance -> Convenience.

Reject features that do not reduce media-loss risk.

## Current Baseline

- macOS 13+, Apple Silicon first
- Swift 5.9+, SwiftUI
- MVVM + Coordinator + Engine + Service
- single source, single destination, single active job
- folder transfer only
- TXT report only
- bundled rsync 3.4.4
- xxHash64 verification

Do not use Apple `/usr/bin/rsync` as fallback unless a future spec explicitly allows it.
Keep app version and rsync version separate.

Current audit targets: rsync path/version, speed limiter, `.DS_Store` hang, progress accuracy, transfer pipeline, SAFE TO FORMAT gate.

## Document Order

1. PRD.md
2. Project_Master_Guideline.md
3. ARCHITECTURE.md
4. STATE_MACHINE.md
5. RSYNC_ENGINE_SPEC.md
6. VERIFY_ENGINE_SPEC.md
7. CODING_STANDARDS.md
8. FILE_STRUCTURE.md
9. UI_GUIDELINES.md
10. TEST_PLAN.md

Conflict rule: data safety wins; newer handoff beats older rsync assumptions; specific spec beats general doc.

## Architecture Law

Only flow:

View -> ViewModel -> Coordinator -> Engine -> Service

Forbidden:

- View -> Engine/Service
- Engine -> View
- Service -> ViewModel
- SwiftUI in Engine
- workflow in View
- rsync in ViewModel

Layer duties:

| Layer | Owns | Must not do |
|---|---|---|
| View | layout, rendering, user input | workflow, rsync, hashing |
| ViewModel | UI state, bindings, formatting | process execution, state machine |
| Coordinator | validation, workflow, transitions, errors | SwiftUI rendering |
| Engine | transfer, verify, progress, cancel | UI state |
| Service | OS APIs, shell, filesystem, logs, bookmarks | workflow decisions |

## State Law

Allowed states only:

ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled

Rules:

- Coordinator changes state.
- No new names.
- No skipped validation.
- `safeToFormat` only after copy success AND verification pass.
- Verification `none` ends at `copyComplete`, never `safeToFormat`.

## Rsync Law

Use bundled rsync 3.4.4.

Must:

- resolve and log binary path
- log rsync version separately from app version
- capture stdout/stderr
- support cancellation
- parse progress robustly
- never mutate source

Bandwidth:

- presets: 50, 120, 240 MB/s, unlimited
- custom: 20-300 MB/s
- unlimited = no `--bwlimit`
- conversion to rsync units requires tests

Do not add destructive or undocumented flags.

## Verification Law

Modes: none, random33, full  
Algorithm: xxHash64

Rules:

- random33 samples about 33% of transferred files
- full verifies all transferred files
- failure blocks SAFE TO FORMAT
- no SHA256, MD5, CRC32, MHL unless spec changes

## File Law

Good names:

- TransferState.swift
- RsyncEngine.swift
- RsyncProgressParser.swift
- LoggerService.swift
- TransferCoordinator.swift

Forbidden names:

- Helpers.swift
- Utils.swift
- Manager.swift
- Misc.swift

One focused file per change when possible.

## Concurrency Law

Use async/await, Task, actor.  
Avoid DispatchQueue unless bridging legacy APIs.  
No busy loops. No polling loops.

MainActor is UI-only. Never run rsync, hashing, scanning, logging, or reports on MainActor.

## Error and Log Law

Forbidden:

- `try?` for critical work
- `catch {}`
- unsafe force unwrap
- raw rsync error in UI

Map errors for operators.

Required logs: transfer start/end/fail, verify start/end/fail, cancel request, report export, rsync path/version.

## Test Law

Engine/parser/coordinator changes require tests.

Minimum tests: state transitions, SAFE TO FORMAT gate, verification none, rsync path/version, bandwidth conversion, progress parser, cancellation, error mapping.

## Style Law

Prefer explicit names, guard clauses, small types, simple control flow.  
Avoid clever abstraction, premature protocols, DI frameworks, god objects.

View target: <200 lines preferred, refactor above 300.

## Final Check

Before answer:

- architecture valid
- bundled rsync rule obeyed
- state machine valid
- SAFE TO FORMAT cannot bypass
- tests included
- no unrelated feature
- readable at 3 AM on set
