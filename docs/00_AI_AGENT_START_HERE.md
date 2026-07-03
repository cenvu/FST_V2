# FST AI Agent Start Here

Version: 2026-06-30  
Status: First file to read  
Applies To: Codex, Claude, ChatGPT, human contributors

---

## Mission

You are working on FST: FishSock Transfer / Focused Secure Transfer.

FST is a native macOS DIT/Data Wrangler media offload app.

Operational question:

```text
Can the source media be safely ejected and handed off?
```

FST does not format cards or media. It provides copy and verification evidence for operator handoff.

Workflow:

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

## Start Here: FST_AI

For current AI-assisted development workflow, use:

- `FST_AI/README.md`
- `FST_AI/memory/current-priority.md`
- `FST_AI/memory/project-baseline.md`
- `FST_AI/memory/agent-roles.md`
- `FST_AI/standards/safety-first.md`
- `FST_AI/standards/agent-boundaries.md`
- `FST_AI/workflows/`
- `FST_AI/prompts/`
- `FST_AI/skills/`

`FST_AI/` defines the active agent model:

- Mi / Command Center: Technical Lead, Safety Gate, Prompt Architect, Workflow Router.
- Codex: Main Core Coding Agent, Secondary Reviewer.
- Claude: Main QA, Main Code Reviewer, Main Safety Reviewer, Secondary Coding Agent.
- Antigravity / Gemini Pro: Main UI Coding Agent for SwiftUI/UI/UX.

Use `FST_AI/` for current routing, prompt templates, skill playbooks, QA templates, and UI design guidance.

Do not use older agent routing if it conflicts with `FST_AI/`.

---

## Current Release Snapshot

- Version: v1.2 build 20260703
- Package: `dist/FishSockTransfer-v1.2-b20260703-local-macOS13_5plus-arm64.zip`
- Platform: macOS 13.5+, Apple Silicon arm64 only
- Package type: local owner-side ad-hoc build
- Signing: ad-hoc signed, not notarized, not Developer ID signed
- Scope: one source -> one destination -> one active job
- Workflow: SOURCE -> COPY -> VERIFY -> SAFE TO EJECT
- Transfer engine: bundled rsync 3.4.4 only

FST does not format media and does not eject media.

v1.2 is the Runtime Copy Progress / Operator Progress release. The destination activity observer may improve UI visibility when rsync output is delayed, but it is operator truth only. Rsync remains authoritative for transfer lifecycle and exit status. Verification, report generation, and the SAFE TO EJECT gate remain authoritative for safety.

Agent division:

- Mi / Command Center: technical lead and safety gate
- Codex: core engineer
- Claude: primary QA/code/safety reviewer
- Antigravity / Gemini Pro: UI implementation

Do not include dropped or deprecated agent workflows unless the user explicitly asks.

---

## Required Read Order

Read only active docs first:

```text
1. docs/00_AI_AGENT_START_HERE.md
2. docs/01_PRD.md
3. docs/02_FST_TECHNICAL_GUIDE.md
4. docs/03_PROJECT_MASTER_GUIDELINE.md
5. Existing Swift code
```

Ignore:

```text
docs/archive/
```

unless the user explicitly asks for historical context.

---

## Current Repository Layout

Expected top-level layout:

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
  prototype/ or archive/react-prototype/ optional
  README.md
```

Rules:

- Active docs live in `FST_V2/docs/`.
- Swift app code lives in `FST_V2/FishSockTransfer/FishSockTransfer/`.
- Do not put docs inside the app source folder.
- Do not treat old React/Vite prototype files as production app code.

---

## Current Project Reality

Use the current Xcode project structure as ground truth.

Current active app source tree:

```text
FishSockTransfer/FishSockTransfer/
  Assets.xcassets/
  Coordinators/
    TransferCoordinator.swift
  Engines/
    ProgressParser.swift
    ReportEngine.swift
    RsyncEngine.swift
    TransferEvent.swift
    VerificationEvent.swift
    VerifyEngine.swift
  Models/
    LogEntry.swift
    RsyncBandwidthLimit.swift
    StorageMetadata.swift
    TransferFileExclusionPolicy.swift
    TransferReport.swift
    TransferRequest.swift
    TransferResult.swift
    TransferState.swift
    VerificationMode.swift
    VerificationRequest.swift
    VerificationResult.swift
  Services/
    BookmarkService.swift
    BundledRsyncService.swift
    DriveService.swift
    LoggerService.swift
  ViewModels/
    TransferViewModel.swift
  Views/
    Color+State.swift
    ContentView.swift
    DestinationCardView.swift
    FolderPicker.swift
    SourceCardView.swift
    StorageAnalysisView.swift
    TerminalLogsView.swift
    TransferControlsView.swift
  FishSockTransferApp.swift
  rsync
```

Do not invent new folders unless the task is explicit file-structure cleanup.

---

## Non-Negotiable Rules

### Architecture

Only dependency flow:

```text
View -> ViewModel -> Coordinator -> Engine -> Service
```

Forbidden:

- View calls Engine or Service
- ViewModel launches rsync
- Engine imports SwiftUI
- Service changes TransferState
- Coordinator renders UI

### State Machine

Allowed states only:

```text
ready, validating, copying, verifying, copyComplete, safeToFormat, error, cancelled
```

Note: `safeToFormat` is a legacy internal state name only. Operator-facing UI, logs, and reports must say `SAFE TO EJECT` for verified success.

Rules:

- Only `TransferCoordinator` changes state.
- No new states.
- No skipped validation.
- Verification `none` ends at `copyComplete`.
- `safeToFormat` requires copy success AND verification pass.

### Rsync

Use bundled rsync 3.4.4 only for production transfer.

Must:

- Resolve bundled rsync path.
- Validate executable permission.
- Log rsync path.
- Log rsync version separately from app version.
- Fail fast if bundled rsync is missing or wrong.

Forbidden:

- Silent fallback to `/usr/bin/rsync`.
- Silent fallback to Homebrew, MacPorts, or any non-bundled rsync.
- Destructive rsync flags.
- Source mutation.

### Bandwidth

UI uses MB/s labels.

Rsync `--bwlimit` uses KiB/s-style values.

Rules:

- 50 MB/s -> 51200
- 120 MB/s -> 122880
- 240 MB/s -> 245760
- Unlimited -> omit `--bwlimit`
- Custom allowed range: 20...300 MB/s
- Conversion requires tests.

### Verification

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

- `none` means copy-only success: TRANSFER COMPLETE, not SAFE TO EJECT.
- `random33` verifies about one third of files with SHA256.
- `full` verifies all files with xxHash64 fast non-cryptographic verification.
- Any verification failure blocks SAFE TO EJECT.
- No MD5, CRC32, MHL in MVP unless spec changes.

---

## Current Audit Targets

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

## Response Protocol For Coding Agents

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

Before editing code:

```text
1. Inspect existing files.
2. Identify owning layer.
3. Patch smallest safe surface.
4. Add or update tests.
5. Provide verification command.
```

Forbidden:

- whole-app rewrite
- new architecture
- queue/multi-destination/cloud/database
- TODO placeholder replacing required logic
- silent error swallowing
- code without tests for engine/parser/coordinator changes

---

## Final Rule

At 3:00 AM on set, with a producer behind the DIT:

Choose the implementation that is easiest to inspect, explain, cancel, and verify.

Data safety beats everything.
