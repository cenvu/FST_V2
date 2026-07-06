# FST Command Center Handover

## Project Identity

FST / FishSock Transfer is a native macOS SwiftUI app for DIT / Data Wrangler media offload workflows.

Primary workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT DESTINATION
```

FST helps operators collect copy and verification evidence for destination handoff. It does not format, erase, reuse, or eject source media.

Primary users:
- DIT
- Data Wrangler
- Assistant DIT
- Assistant Editor / small production teams

## Current Baseline After v1.3.4

Current repository baseline:
- Version: v1.3.4 build 20260706
- Tag: v1.3.4-b20260706
- HEAD on main: f0d0cbf
- GitHub Release: published with zip + checksum assets
- Release theme: Detailed TXT Report V1 hardening and safety wording cleanup

v1.3.4 is not a transfer/verify/hash/rsync/Telegram/update-check logic release.

v1.3.3 remains the packaged build network permission / sandbox outbound entitlement hotfix for manual GitHub update-check and Telegram HTTPS workflows.

Package state:
- `dist/FishSockTransfer-v1.3.4-b20260706-local-macOS13_5plus-arm64.zip`
- SHA256: `a8487b89d4f3545f6cdd6f3e2aabe132c81657b108768924fde0923c9dda7826`
- Local owner-side ad-hoc package
- Not Developer ID signed
- Not notarized
- macOS 13.5+
- Apple Silicon arm64 only

## Core Workflow

Current MVP workflow:

```text
one source -> one destination -> one active job -> copy -> verify -> report -> SAFE TO EJECT DESTINATION when verified
```

Verification `none` is copy-only and must end as transfer complete, not verified SAFE TO EJECT.

## Safety Philosophy

Priority:

```text
Data Safety > Reliability > Repeatability > Maintainability > Performance > Convenience
```

Rules:
- Source media is read-only.
- FST must never mutate source media.
- Copy success alone is not verified success.
- UI estimates must never decide safety.
- Final wording must not imply permission to erase, format, or reuse source media.

Approved operator wording:
- SAFE TO EJECT
- SAFE TO EJECT DESTINATION

Forbidden unless explicitly requested and policy-reviewed:
- SAFE TO FORMAT
- Source Format Authorization

## Current MVP Scope

In scope:
- Single source
- Single destination
- Single active job
- Folder transfer
- Bundled rsync 3.4.4 only
- Bandwidth limiting
- Runtime progress/log visibility
- Destination observer fallback metrics
- Verification modes: none, random33, full
- Detailed TXT Report V1
- Telegram best-effort notifications
- Manual GitHub release update-check
- Local Apple Silicon package workflow

Deferred:
- Multi-destination
- Queue / multi-job engine
- Database/history engine
- Cloud sync
- LTO/MHL/NAS/RAID workflow
- PDF report
- Report viewer
- Full manifest unless explicitly approved
- Major UI redesign
- Intel/universal package support

## Latest Release State

Version metadata:
- `MARKETING_VERSION = 1.3.4`
- `CURRENT_PROJECT_VERSION = 20260706`
- Package script `APP_VERSION = 1.3.4`
- Package script `BUILD_NUMBER = 20260706`
- Technical Logs footer badge: `v1.3.4`

GitHub Release:
- Tag: `v1.3.4-b20260706`
- Name: `FST v1.3.4 build 20260706`
- Assets:
  - `FishSockTransfer-v1.3.4-b20260706-local-macOS13_5plus-arm64.zip`
  - `SHA256SUMS-v1.3.4.txt`

Release rule:
- A git tag alone is not a downloadable release.
- Release is complete only when GitHub Release has zip + checksum assets and those assets are verified.

## Architecture Overview

Allowed flow:

```text
SwiftUI Views -> TransferViewModel -> TransferCoordinator -> Engines -> Services
```

Key ViewModels:
- `TransferViewModel`: UI state, bindings, progress presentation, Telegram settings/status, log presentation
- `TechnicalLogsUpdateViewModel`: manual GitHub update-check state

Key Coordinators:
- `TransferCoordinator`: workflow/state transitions, validation, copy/verify/report orchestration
- `NotificationCoordinator`: Telegram notification policy/throttling/delivery status

Key Engines:
- `RsyncEngine`: bundled rsync execution, process lifecycle, stdout/stderr streaming, cancellation, progress events
- `ProgressParser`: rsync output framing and progress/speed/ETA/current-file parsing
- `VerifyEngine`: inventory, sample/full verification, SHA256/xxHash64 hashing, verification events
- `ReportEngine`: Detailed TXT Report V1 generation and saving

Key Services:
- `BundledRsyncService`: bundled rsync path/version/executable validation
- `DriveService`: source/destination validation and storage metadata
- `BookmarkService`: security-scoped bookmarks
- `LoggerService`: logging wrapper
- `TelegramNotificationService`: Telegram HTTP API and Keychain token storage
- `AppUpdateService`: manual GitHub release check

## Transfer Flow

Transfer starts from `TransferViewModel.startTransfer()` and enters `TransferCoordinator.startTransfer(...)`.

Coordinator flow:
1. Validate source/destination/preflight.
2. Resolve and validate bundled rsync 3.4.4.
3. Run copy through `RsyncEngine`.
4. Stream stdout/stderr and structured transfer events.
5. Transition to verify or copy-complete depending on verification mode.
6. Generate terminal report.

Rsync rules:
- Use bundled rsync 3.4.4 only.
- No Apple `/usr/bin/rsync` fallback.
- No Homebrew/MacPorts fallback.
- No destructive source-mutation flags.
- Optional bandwidth limit must use converted rsync values.

Progress:
- Rsync progress is parsed from streamed output.
- Parser handles carriage return, newline, and CRLF records.
- Destination observer metrics can provide UI feedback when rsync output is delayed.

Safety boundary:
- Rsync lifecycle/exit status decides copy truth.
- Destination observer metrics never decide copy success.

## Verify Flow

Verification modes:
- `none`: copy-only; not verified SAFE TO EJECT
- `random33`: sample verification with SHA256
- `full`: full verification with xxHash64

Verification checks:
- Build source/destination inventory.
- Compare relative paths and file sizes.
- Hash selected/all eligible files according to mode.
- Emit verification progress/log events.
- Support cancellation.

Verify ETA:
- Approximate UI feedback only.
- Must never decide verification success or final safety.

## Report System

Detailed TXT Report V1 is current MVP evidence output.

v1.3.4 hardening:
- Clearer report sections
- Bilingual disclaimer near top
- Active report output avoids obsolete format-safety wording
- Verified success wording clarified as SAFE TO EJECT DESTINATION
- Report filenames/job IDs no longer use source name
- Operator-facing rsync detail reduced to rsync 3.4.4
- Technical log sharing note included
- Report wording safety tests updated

Report policy:
- FST reports copy and verification results only.
- Decisions to erase, format, or reuse source media remain the user's responsibility.
- Report generation must not contradict UI terminal state.
- Report logic is safety-relevant.

## UI / Operator Runtime Feedback

Runtime feedback includes:
- Source/destination cards
- Storage analysis
- Transfer controls
- Copy progress
- Verify progress
- Current item
- Speed
- Elapsed time
- ETA
- Technical logs
- App version / bundled rsync / license footer
- Manual update-check status
- Telegram notification status

Truth separation:
- Safety truth = copy success + verify result + report/final state.
- Transfer truth = bundled rsync lifecycle/exit/stderr/cancel/failure.
- Operator truth = UI progress, destination observer, speed, ETA, current item, verify ETA, logs, Telegram/update-check visibility.

Operator truth must never affect safety truth.

## Packaging and Release Pipeline

Correct release pipeline:

```text
commit -> build/test -> package -> validate package -> runtime QA -> checksum -> tag -> push main/tag -> GitHub Release -> upload zip/checksum -> verify assets
```

Standard package script:

```bash
bash scripts/package-local-arm64.sh
```

Package validation includes:
- Info.plist version/build
- macOS minimum
- app/rsync executability
- bundled rsync 3.4.4
- arm64 architecture
- dylib presence/architecture/loader paths
- ad-hoc codesign structure
- zip AppleDouble safety
- required zip entries

## Source-of-Truth Docs

Read first:
- `AGENTS.md`: root agent rules, current release state, architecture/safety law
- `FST_AI/memory/TASK_REGISTRY.md`: task repetition guard
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`: current Command Center baseline
- `FST_AI/memory/WORK_HISTORY.md`: append-only compact work history
- `docs/00_AI_AGENT_START_HERE.md`: active entry point
- `docs/01_PRD.md`: product mission and MVP scope
- `docs/02_FST_TECHNICAL_GUIDE.md`: technical architecture and safety rules
- `docs/03_PROJECT_MASTER_GUIDELINE.md`: doctrine and boundaries
- `README.md`: user-facing overview
- `CHANGELOG.md`: release summary
- `docs/releases/README.md`: release-note index
- `docs/releases/release-notes-v1.3.4.md`: latest release note
- `FST_AI/README.md`: AI engineering system

Historical material:
- Do not treat deleted, archived, old React/Vite, or web prototype files as production SwiftUI app code.

## AI Agent Workflow

Roles:
- Mi / ChatGPT Command Center: Technical Lead, Safety Gate, Prompt Architect, workflow router
- Codex: core engineering, release engineering, repo audits, small safe changes
- Antigravity: main SwiftUI/UI implementation
- Gemini Pro: small UI/ViewModel experiments when routed
- Claude: QA/safety review and second opinion

Roo/RooCode is dropped unless explicitly reintroduced.

Role source of truth:
- `FST_AI/roles/` is the only active role-doc home.
- Do not create `FST_AI/agents/` unless Mi explicitly changes the structure.

Routing:
- Core logic: Codex implements, Claude reviews, Mi gates.
- UI: Antigravity/Gemini implements, Claude or Mi reviews, Mi gates.
- Safety-critical: smallest safe Codex change, Claude review, Mi final decision.

## Standard Checks

```bash
git diff --check
```

```bash
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' build
```

```bash
xcodebuild test -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -destination 'platform=macOS'
```

```bash
bash scripts/package-local-arm64.sh
```

## Known Risks / Gaps

MVP-critical:
- Do not regress bundled rsync-only execution.
- Do not allow copy-only success to appear verified.
- Do not let UI observer metrics influence safety.
- Do not reintroduce obsolete format-safety wording.
- Runtime QA still needed for real media/failure/cancel cases.

High priority:
- Maintain GitHub Release asset + checksum discipline.
- Preserve v1.3.3 entitlement behavior for networked update/Telegram flows.
- Keep Detailed TXT Report V1 truthful and consistent with terminal state.
- Verify packaged app behavior on another Apple Silicon Mac.
- Continue destination existing-folder policy review.

Medium priority:
- Improve runtime QA matrix and evidence capture.
- Tighten docs around release asset workflow.
- Review source/destination permission UX.
- Continue UI clarity polish without touching safety logic.

Deferred:
- Multi-destination
- Queue system
- Advanced manifest
- Major UI redesign
- Performance tuning unless blocking reliability
- Developer ID signing/notarization until user decides distribution path

## Recommended Next Batches

1. Release QA Evidence Batch: verify v1.3.4 GitHub zip/checksum download, unzip, launch on second Apple Silicon Mac, and document results.
2. Runtime Failure/Cancel QA Batch: test copy fail, verify fail, cancellation during copy, cancellation during verify.
3. Destination Existing-Folder Policy Batch: define no-unsafe-merge/overwrite rules.
4. Report V1 Evidence Review Batch: review report contents for operator sufficiency and final decision wording.
5. Permission UX Batch: review bookmark/access failures and operator messaging.
6. Packaging Automation Batch: make checksum/release asset verification harder to skip.
7. Docs Cleanup Batch: inventory old/prototype folders before archiving.
8. UI Clarity Batch: polish operator state/warnings without touching core safety logic.
9. Signing/Notarization Decision Batch: decide whether to add Developer ID signing and notarization.
10. Performance Observation Batch: measure many-small-files and slow-device behavior before optimizing.

## Rules for Future Assistants

- Never mutate source media.
- Never reintroduce SAFE TO FORMAT or Source Format Authorization wording unless explicitly requested and policy-reviewed.
- Use SAFE TO EJECT / SAFE TO EJECT DESTINATION for operator-facing output.
- Never let UI estimates, destination observer metrics, speed, ETA, current item, or Verify ETA affect copy success, verify success, report truth, or SAFE TO EJECT.
- Never use Apple/System/Homebrew rsync fallback.
- Git tag alone is not a downloadable release.
- Release is complete only after GitHub Release has zip + checksum assets.
- Do not delete ambiguous repo folders without inventory and user approval.
- Always separate safety truth, transfer truth, and operator truth.
- Always prioritize data safety over convenience/speed.
- For release tasks, include checksum and GitHub Release asset upload.

## Required Agent Startup

Before making changes, every AI agent must read:
- `FST_AI/memory/TASK_REGISTRY.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/WORK_HISTORY.md`
- `AGENTS.md`
- `docs/00_AI_AGENT_START_HERE.md`

If docs conflict, use this priority:
1. `AGENTS.md`
2. `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
3. `docs/00_AI_AGENT_START_HERE.md`
4. `FST_AI/memory/TASK_REGISTRY.md`
5. `FST_AI/memory/WORK_HISTORY.md`

Before executing a task, check:
- `FST_AI/memory/TASK_REGISTRY.md`
- `FST_AI/memory/WORK_HISTORY.md`

If a substantially similar task already exists, ask whether to rerun it, continue it, or review previous output.

After meaningful work, agents must propose an update to:
- `FST_AI/memory/WORK_HISTORY.md`
- `FST_AI/memory/TASK_REGISTRY.md`

If baseline changes, agents must also propose an update to:
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`

Meaningful work includes:
- source code changes
- safety policy changes
- report wording/schema changes
- release/package/tag/GitHub Release changes
- architecture changes
- workflow/AI-agent routing changes
- docs cleanup that changes source-of-truth status

## Compact Memory Version

FST / FishSock Transfer is a native macOS SwiftUI DIT/Data Wrangler app for one-source, one-destination, one-job media offload. Core workflow: SOURCE -> COPY -> VERIFY -> SAFE TO EJECT DESTINATION. Priority is Data Safety > Reliability > Repeatability > Maintainability > Performance > Convenience. FST does not format, erase, reuse, or eject source media; it reports copy and verification evidence for operator judgment.

Current baseline after v1.3.4: branch `main`, HEAD `f0d0cbf`, tag `v1.3.4-b20260706`, GitHub Release has zip + checksum. Version metadata: `MARKETING_VERSION=1.3.4`, `CURRENT_PROJECT_VERSION=20260706`, package script `APP_VERSION=1.3.4`, `BUILD_NUMBER=20260706`. Package is local owner-side ad-hoc signed, not Developer ID signed, not notarized, Apple Silicon arm64 only, macOS 13.5+. v1.3.3 remains the network permission / sandbox outbound entitlement hotfix. v1.3.4 is Detailed TXT Report V1 hardening: clearer sections, bilingual disclaimer near top, active output avoids obsolete format-safety wording, final verified success clarified as SAFE TO EJECT DESTINATION, report filenames/job IDs no longer use source name, operator-facing rsync detail reduced to rsync 3.4.4, technical log sharing note, and wording tests.

Architecture: SwiftUI Views -> TransferViewModel -> TransferCoordinator -> Engines -> Services. `TransferCoordinator` owns workflow/state transitions. `RsyncEngine` owns bundled rsync execution/streaming/cancel. `ProgressParser` handles rsync output framing. `VerifyEngine` owns inventory/hash verification. `ReportEngine` owns TXT report generation. `BundledRsyncService` must validate bundled rsync 3.4.4; Apple/System/Homebrew fallback is forbidden. Telegram and update-check are visibility-only.

Safety model: safety truth is copy success + verification result + report/final state. Transfer truth is bundled rsync lifecycle, exit status, stderr, cancellation/failure. Operator truth is UI progress, destination observer metrics, speed, ETA, current item, verify ETA, logs, Telegram/update-check visibility. Destination observer and verify ETA are UI-only and must never decide copy success, verify success, report result, or SAFE TO EJECT. Verification modes: `none` copy-only; `random33` sample SHA256; `full` xxHash64 full verification.

AI roles: Mi/Command Center is technical lead/safety gate/prompt architect. Codex handles core engineering, release engineering, repo audits. Antigravity handles SwiftUI/UI. Gemini Pro can do small UI/ViewModel experiments if routed. Claude reviews QA/safety. Roo/RooCode is dropped unless reintroduced. `FST_AI/roles/` is the only active role-doc home. Agents check `TASK_REGISTRY.md` and `WORK_HISTORY.md` before repeated tasks. Standard checks: `git diff --check`; Xcode Debug build; full `xcodebuild test`; `bash scripts/package-local-arm64.sh`. Next priorities: second-Mac package QA, failure/cancel QA, destination existing-folder policy, report evidence review, permission UX, release automation, docs cleanup, UI clarity, signing/notarization decision.
