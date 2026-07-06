<!-- FST / CenVu | (+84) 842 841 222 -->

# FST Agent Instructions

Version: 2026-06-30  
Status: Active root instruction file  
Applies to: Codex, ChatGPT, Claude, and human contributors

---

## Project

FST / FishSock Transfer is a native macOS DIT/Data Wrangler media offload app.

The app exists to answer one operational question:

```text
Can the source media be safely ejected and handed off?
```

FST does not format cards or media. It provides copy and verification evidence for operator handoff.

Required workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT / OPERATOR HANDOFF
```

Priority order:

```text
Data Safety -> Reliability -> Repeatability -> Maintainability -> Performance -> Convenience
```

Current release safety priority:

```text
Data Safety -> Reliability -> Truthful Operator Feedback -> Speed -> Convenience
```

Do not add features that do not reduce media-loss risk.

---

## FST_AI Agent Workflow Layer

`FST_AI/` is the primary internal AI Engineering System for this project.

Before doing non-trivial work, agents must read the relevant files in `FST_AI/`.

Required handover startup:

- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/WORK_HISTORY.md`
- `AGENTS.md`
- `docs/00_AI_AGENT_START_HERE.md`

If docs conflict, use this priority:
1. `AGENTS.md`
2. `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
3. `docs/00_AI_AGENT_START_HERE.md`
4. `FST_AI/memory/WORK_HISTORY.md`
5. older archived docs

After meaningful work, propose a `FST_AI/memory/WORK_HISTORY.md` update. If the baseline changes, also propose a `FST_AI/memory/COMMAND_CENTER_HANDOVER.md` update. Meaningful work includes source, safety policy, report wording/schema, release/package/tag/GitHub Release, architecture, routing, or source-of-truth docs changes.

Minimum reading:

- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/WORK_HISTORY.md`
- `FST_AI/README.md`
- `FST_AI/memory/current-priority.md`
- `FST_AI/memory/agent-roles.md`
- `FST_AI/standards/safety-first.md`
- `FST_AI/standards/agent-boundaries.md`
- `FST_AI/standards/minimal-safe-change.md`

For core logic work, also read:

- `FST_AI/roles/codex-core-engineer.md`
- `FST_AI/roles/claude-primary-reviewer.md`
- relevant skills under `FST_AI/skills/`

For UI work, also read:

- `FST_AI/roles/antigravity-gemini-ui-engineer.md`
- `FST_AI/design-system/MASTER.md`
- relevant design-system page override under `FST_AI/design-system/pages/`
- relevant UI skills under `FST_AI/skills/`

## Current Agent Roles

- Mi / Command Center: Technical Lead, Safety Gate, Prompt Architect, Workflow Router.
- Codex: Main Core Coding Agent, Secondary Reviewer.
- Claude: Main QA, Main Code Reviewer, Main Safety Reviewer, Secondary Coding Agent.
- Antigravity / Gemini Pro: Main UI Coding Agent for SwiftUI/UI/UX.

## Routing Rules

Core logic:

- Codex implements.
- Claude reviews.
- Mi performs final safety gate.

UI:

- Antigravity / Gemini Pro implements.
- Claude or Mi reviews UI state/safety risk.
- Mi performs final safety gate.

Safety-critical changes:

- Codex implements the smallest safe change.
- Claude performs primary safety review.
- Mi decides accept/revise/reject/runtime QA.

## Non-Negotiable Safety Rules

- Source media is treated as read-only.
- FST must never mutate, delete, rename, chmod, chown, or format source media.
- FST must use bundled rsync 3.4.4 only.
- Apple rsync fallback is not allowed.
- Destructive rsync behavior is not allowed.
- Long-running copy/verify/report work must not block the UI.
- SAFE TO EJECT must never be true after failed, cancelled, incomplete, or uncertain copy/verify state.

---

## Current Release State

- Current version: v1.3.4 display 1.3.4 build 20260706
- Current package: `dist/FishSockTransfer-v1.3.4-b20260706-local-macOS13_5plus-arm64.zip`
- Platform: macOS 13.5+, Apple Silicon arm64 only
- Package type: local owner-side ad-hoc build
- Signing: ad-hoc signed, not notarized, not Developer ID signed
- Scope: one source -> one destination -> one active job
- Manual update check: GitHub release check from Technical Logs footer, user-triggered only
- Notification MVP: Telegram best-effort notifications only, with v1.3.3 packaged-network entitlement fix
- Transfer engine: bundled rsync 3.4.4 only
- Operator-facing verified success: SAFE TO EJECT
- Release theme: Detailed TXT Report V1 hardening and safety wording cleanup

FST does not format media and does not eject media.

Agent division:

- Mi / Command Center: technical lead and safety gate
- Codex: core engineer
- Claude: primary QA/code/safety reviewer
- Antigravity / Gemini Pro: UI implementation

Do not reintroduce dropped or deprecated agent workflows unless the user explicitly asks.

---

## Required Reading

Before editing code, read these active docs in order:

```text
1. docs/00_AI_AGENT_START_HERE.md
2. docs/01_PRD.md
3. docs/02_FST_TECHNICAL_GUIDE.md
4. docs/03_PROJECT_MASTER_GUIDELINE.md
5. Existing Swift code relevant to the task
```

Ignore `docs/archive/` unless the user explicitly asks for historical context.

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

- Active documentation lives in `docs/`.
- Swift app code lives in `FishSockTransfer/FishSockTransfer/`.
- Do not put project guides inside the app source folder.
- Do not treat old React, Vite, AI Studio, or prototype files as production app code.
- Do not invent new folders unless the task explicitly requests file-structure cleanup.

---

## Architecture Rules

Allowed dependency flow only:

```text
SwiftUI View -> TransferViewModel -> TransferCoordinator -> Engines -> Services
```

Forbidden:

- View calls Engine or Service directly.
- ViewModel launches rsync, hashes files, or owns workflow transitions.
- Engine imports SwiftUI.
- Service changes `TransferState`.
- Coordinator renders UI.
- Hidden global workflow state.

Layer ownership:

| Layer | Owns | Must Not Do |
|---|---|---|
| Views | layout, rendering, user actions | rsync, hashing, workflow decisions |
| ViewModel | published UI state, bindings, formatting | process execution, filesystem work, state machine ownership |
| Coordinator | validation, orchestration, state transitions, Safe To Eject gate | SwiftUI rendering, low-level shell details |
| Engines | transfer, progress parsing, verification, report generation | UI state, SwiftUI imports |
| Services | macOS APIs, bookmarks, rsync lookup, logging wrappers | workflow decisions |
| Models | data contracts | side effects |

Only `TransferCoordinator` may change `TransferState`.

---

## State Machine

Allowed states only:

```text
ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled
```

Note: `safeToFormat` is a legacy internal state name only. UI, logs, reports, and docs for operators must use `SAFE TO EJECT`, not formatting language.

Success flows:

```text
ready -> validating -> copying -> verifying -> safeToFormat
ready -> validating -> copying -> copyComplete
```

Rules:

- Verification `none` ends at `copyComplete`.
- `safeToFormat` requires copy success and verification pass.
- No skipped validation.
- No new or renamed states without explicit spec update.
- No automatic reset after terminal states unless explicitly implemented and reviewed.

Terminal states:

```text
copyComplete, safeToFormat, error, cancelled
```

---

## Rsync Rules

Production transfer must use bundled rsync 3.4.4 only.

Must:

- Resolve the bundled rsync path through `BundledRsyncService`.
- Validate executable permission.
- Validate rsync version.
- Log rsync path.
- Log rsync version separately from app version.
- Fail fast if bundled rsync is missing, not executable, or wrong version.

Forbidden:

- Silent fallback to `/usr/bin/rsync`.
- Silent fallback to Homebrew, MacPorts, or any non-bundled rsync.
- Destructive rsync flags.
- Source mutation.
- Fake success based only on UI progress.

Required production flags:

```text
-a
-h
--info=progress2
```

Optional:

```text
--bwlimit=<converted_limit>
```

---

## Bandwidth Rules

UI labels are MB/s.

Rsync `--bwlimit` must receive converted KiB/s-style values.

Required conversions:

```text
50 MB/s  -> 51200
120 MB/s -> 122880
240 MB/s -> 245760
Unlimited -> omit --bwlimit
```

Custom range:

```text
20...300 MB/s
```

Conversion must be covered by tests.

---

## Verification Rules

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

- `none` means copy-only success: TRANSFER COMPLETE, not SAFE TO EJECT.
- `random33` verifies about one third of files with SHA256, with a minimum of one file when files exist.
- `full` verifies all files with xxHash64 fast non-cryptographic verification.
- Compare relative paths and file sizes before hashing.
- Any verification failure blocks SAFE TO EJECT.
- Verify off the MainActor.
- Do not add MD5, CRC32, MHL, database, queue, or multi-destination behavior unless the spec changes.

`VerifyEngine` emits verification result. `TransferCoordinator` decides final state.

---

## Source Safety

FST must never modify source media.

Forbidden on source:

- delete
- rename
- move
- metadata write
- hidden cleanup
- quarantine changes
- destructive rsync operation

If there is uncertainty, fail safely and tell the operator not to erase or reuse the source.

---

## Current Audit Priority

Fix before feature expansion:

```text
1. Bundled rsync path/version accuracy
2. App version vs rsync version separation
3. Speed limiter correctness
4. .DS_Store hang investigation
5. Progress reporting accuracy
6. Transfer pipeline validation
7. Cancellation safety
8. Safe To Eject enforcement
9. TXT report truthfulness
```

---

## Coding Rules

Use:

- simple, explicit Swift
- clear names
- small changes
- guard clauses
- async/await where appropriate
- tests for engines, parsers, coordinators, bandwidth conversion, verification, and reports

Avoid:

- broad rewrites
- clever abstractions
- new dependencies
- vague `Manager`, `Helper`, or `Utils` files
- silent `catch {}`
- unsafe `try?`
- force unwraps unless impossible to fail and documented
- TODO placeholders replacing required logic

Never run rsync, hashing, scanning, or report generation on the MainActor.

---

## Required Agent Response Format

Every coding response must use:

```text
PHASE:
FILES:
LAYER CHECK:
PATCH:
TESTS:
VERIFY:
```

Keep responses short. Code first. No speculative redesign.

Before editing:

```text
1. Inspect existing files.
2. Identify the owning layer.
3. Patch the smallest safe surface.
4. Add or update tests when changing engine/parser/coordinator/report behavior.
5. Provide a verification command or manual verification step.
```

---

## Forbidden Scope Creep

Do not add unless explicitly requested:

- transfer queue
- multi-destination copy
- mirrored copy
- NAS, RAID, LTO, MHL, proxy workflow
- cloud sync
- DAM/MAM
- history database
- AI features inside the app
- React/Vite frontend revival
- Node/Gemini/AI Studio deployment workflow

---

## Final Rule

At 3:00 AM on set, with a producer behind the DIT, choose the implementation that is easiest to inspect, explain, cancel, and verify.

Data safety beats everything.
