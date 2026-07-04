<!-- FST / CenVu | (+84) 842 841 222 -->

# FST Technical Guide

Version: 2026-06-21
Status: Current Project Source of Truth
Applies To: Codex, Claude, ChatGPT, human contributors

---

## 0. Mission

FST exists to answer one operational question:

Can the source media be safely formatted?

Workflow:

SOURCE -> COPY -> VERIFY -> SAFE TO FORMAT

Priority order:

1. Data Safety
2. Reliability
3. Repeatability
4. Maintainability
5. Performance
6. Convenience

Do not add features that do not reduce media-loss risk.

---

## 1. Current Project Reality

Use the current Xcode project structure as ground truth.

Visible source tree:

```text
FishSockTransfer/
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

  Assets.xcassets
  FishSockTransferApp.swift
  rsync
```

Do not invent folders that are not in the current project unless explicitly requested.

Do not move files during debugging unless the task is file-structure cleanup.

---

## 2. Architecture

Locked architecture:

```text
SwiftUI Views
  -> TransferViewModel
    -> TransferCoordinator
      -> Engines
        -> Services
          -> Foundation / macOS APIs
```

Allowed dependency direction only:

```text
View -> ViewModel -> Coordinator -> Engine -> Service
```

Forbidden:

- View -> Engine
- View -> Service
- Engine -> ViewModel
- Engine -> View
- Service -> ViewModel
- Coordinator -> SwiftUI

Layer ownership:

| Layer | Owns | Must Not Do |
|---|---|---|
| Views | Layout, rendering, user actions | rsync, hashing, scanning, workflow decisions |
| ViewModel | Published UI state, bindings, formatting | process execution, verification, state transitions |
| Coordinator | workflow, validation, state transitions, report trigger | SwiftUI rendering, shell details |
| Engines | transfer, parsing, verification, reporting | UI state, SwiftUI imports |
| Services | macOS/system wrappers | workflow decisions |
| Models | immutable data contracts | side effects |

Only `TransferCoordinator` may change `TransferState`.

---

## 3. Current File Ownership

### Coordinators

`TransferCoordinator.swift`

Owns:

- input validation
- start/cancel workflow
- transfer state transitions
- orchestration: validate -> copy -> verify -> report
- SAFE TO FORMAT gate

Must not:

- parse rsync lines directly if `ProgressParser` owns it
- update SwiftUI directly
- hide rsync/version failures

### Engines

`RsyncEngine.swift`

Owns:

- transfer execution
- rsync argument creation
- process lifecycle
- stdout/stderr streaming
- cancellation
- mapping rsync exit codes to typed errors/events

`ProgressParser.swift`

Owns:

- parsing rsync progress output
- percent
- current speed
- ETA
- current file when available

Parser must tolerate malformed/partial lines and never crash.

`VerifyEngine.swift`

Owns:

- source/destination inventory
- random 33% selection
- full verification
- xxHash64 generation/comparison
- verification events/results

`ReportEngine.swift`

Owns:

- plain TXT report generation only
- formatting `TransferReport`

`TransferEvent.swift`

Owns:

- structured transfer events leaving `RsyncEngine`

`VerificationEvent.swift`

Owns:

- structured verification events leaving `VerifyEngine`

### Models

`RsyncBandwidthLimit.swift`

Owns:

- presets: 50 MB/s, 120 MB/s, 240 MB/s, Unlimited
- custom range: 20 MB/s to 300 MB/s
- conversion to rsync `--bwlimit` value

Critical:

- rsync `--bwlimit` expects KiB/s style values, not raw MB/s labels.
- UI label must not equal process argument unless converted.

`TransferFileExclusionPolicy.swift`

Owns:

- safe exclusion rules
- current audit focus: `.DS_Store` hang prevention

Rules:

- Excluding OS metadata is allowed only if documented.
- Never exclude camera/media files by extension without explicit approval.

`StorageMetadata.swift`

Owns:

- source size
- destination free space
- remaining free space
- file count if implemented

### Services

`BundledRsyncService.swift`

Owns:

- locating bundled rsync binary
- validating executable permission
- validating rsync version
- providing canonical rsync path to `RsyncEngine`

Critical:

- Production transfer must use bundled rsync 3.4.4.
- Silent fallback to `/usr/bin/rsync` is forbidden.
- If bundled rsync is missing, not executable, or wrong version: fail fast with a clear error.

`DriveService.swift`

Owns:

- folder validation
- source readability
- destination writability
- source size
- destination free space
- mounted volume metadata when needed

`BookmarkService.swift`

Owns:

- security scoped bookmarks
- restore folder access after relaunch
- start/stop access scope

`LoggerService.swift`

Owns:

- thread-safe logs
- categories
- TXT export support if not delegated to `ReportEngine`

---

## 4. State Machine

Allowed states:

```swift
enum TransferState {
    case ready
    case validating
    case copying
    case verifying
    case copyComplete
    case safeToFormat
    case error
    case cancelled
}
```

Required flow:

```text
ready
  -> validating
    -> copying
      -> verifying
        -> safeToFormat
```

Verification disabled:

```text
copying -> copyComplete
```

Failure exits:

```text
validating -> error
copying -> error | cancelled
verifying -> error | cancelled
```

Rules:

- One active state only.
- No state mutation outside `TransferCoordinator`.
- No automatic reset after terminal states.
- New transfer must explicitly return to `ready`.

Terminal states:

- `copyComplete`
- `safeToFormat`
- `error`
- `cancelled`

---

## 5. SAFE TO FORMAT Gate

Absolute rule:

```text
SAFE TO FORMAT = copy success AND verification success
```

If verification mode is `none`:

```text
Final state = copyComplete
Never safeToFormat
```

Forbidden:

- operator bypass
- warning override
- auto-approve
- treating rsync success as data integrity

Rsync moves data.

VerifyEngine establishes trust.

TransferCoordinator authorizes SAFE TO FORMAT.

---

## 6. Rsync Engine Spec

Production rsync strategy:

```text
Use bundled rsync 3.4.4 via BundledRsyncService.
Do not silently fallback to /usr/bin/rsync.
```

Required flags:

```text
-a
-h
--info=progress2
```

Optional:

```text
--bwlimit=<converted_limit>
```

Exclusion policy:

```text
Use only documented exclusions from TransferFileExclusionPolicy.
Audit .DS_Store behavior.
Do not invent extra exclusions.
```

Process rules:

- one `Process` per transfer
- no process reuse
- stream stdout and stderr continuously
- never block MainActor
- never call `waitUntilExit()` on UI thread
- cleanup pipes and handlers after completion/cancel/failure

Event output only:

```swift
enum TransferEvent {
    case started
    case progress(Double)
    case speed(Double)
    case averageSpeed(Double)
    case eta(TimeInterval?)
    case currentFile(String)
    case log(String)
    case completed(TransferResult)
    case cancelled
    case failed(Error)
}
```

Exact enum may differ in code. Preserve existing API unless refactor is requested.

Exit code handling:

| Code | Meaning | Expected Handling |
|---:|---|---|
| 0 | success | completed |
| 11 | I/O error | user-facing storage error |
| 12 | protocol/data stream error | transfer failed |
| 20 | interrupted | cancelled if user initiated |
| 23 | partial transfer | failed; never safeToFormat |
| 24 | vanished source file | failed unless policy explicitly allows |
| 30 | timeout | failed |

Never expose raw code alone to operator.

Bad:

```text
rsync exit 23
```

Good:

```text
Transfer incomplete. Some files were not copied. Do not format source media.
```

---

## 7. Progress Parser Rules

Input example:

```text
1,245,890,560 48% 120.34MB/s 0:01:30
```

Extract:

- transferred bytes if available
- percent
- current speed
- ETA

Parser must:

- handle commas
- handle spaces
- handle partial lines
- ignore malformed lines safely
- never crash
- never block transfer

Audit priorities:

1. Progress must reflect real rsync output.
2. Current speed must not be confused with average speed.
3. ETA must be optional when unknown.
4. UI must not fake 100% until process exit is confirmed.

---

## 8. Bandwidth Limiter Rules

UI presets:

- 50 MB/s
- 120 MB/s
- 240 MB/s
- Unlimited

Custom range:

- 20 MB/s to 300 MB/s

Rules:

- Unlimited means no `--bwlimit` flag.
- Preset label must convert correctly to rsync argument.
- Validate conversion in unit tests.
- Do not throttle verification unless explicitly specified.

Audit:

- Confirm whether code uses MB/s decimal or MiB/s binary.
- Document the chosen conversion.
- Be consistent in UI, logs, report, and command argument.

Recommended for FST:

```text
Display MB/s to operator.
Convert to KiB/s for rsync --bwlimit.
```

---

## 9. Verification Engine Spec

Verification modes:

```swift
enum VerificationMode {
    case none
    case random33
    case full
}
```

Mode behavior:

| Mode | Behavior | Final Success State |
|---|---|---|
| none | skip hashing | copyComplete |
| random33 | verify approx. 33% | safeToFormat if passed |
| full | verify all files | safeToFormat if passed |

Verification must:

- build source inventory
- build destination inventory
- compare relative paths
- compare file sizes before hashing
- hash selected files with xxHash64
- fail on first proven mismatch or report all mismatches if already implemented
- never load full files into memory
- run off MainActor

Random 33%:

- minimum 1 file
- never exceed inventory
- must not mean first third / last third / every third file
- size-weighted sampling is preferred if already implemented clearly

Critical:

- VerifyEngine must not emit `safeToFormat`.
- It emits pass/fail/cancel.
- Coordinator decides final state.

---

## 10. Report Rules

MVP report format:

```text
TXT only
```

Report must include:

- date/time
- app version
- bundled rsync version
- source path
- destination path
- total size
- file count
- transfer duration
- average speed
- bandwidth limit
- verification mode
- verification result
- error count
- final state

Rules:

- App version and rsync version are separate fields.
- Do not display rsync version as app version.
- Report must never claim SAFE TO FORMAT unless state is `safeToFormat`.

---

## 11. UI Guidelines

Single-window operational tool.

Current views:

- `ContentView`
- `SourceCardView`
- `DestinationCardView`
- `StorageAnalysisView`
- `TransferControlsView`
- `TerminalLogsView`
- `FolderPicker`
- `Color+State`

UI priority:

1. Source
2. Destination
3. Storage readiness
4. Bandwidth
5. Verification mode
6. Current state
7. Logs
8. Final result

Must display during transfer:

- state
- progress
- current speed
- average speed
- ETA if available
- current file if available
- logs

Button rules:

- Start enabled only when validation passes.
- Stop enabled only during copy/verify.
- Stop requires confirmation.
- Export report only when report exists or terminal state is reached.

Status colors:

| State | Color Intent |
|---|---|
| ready | neutral |
| validating | neutral/blue |
| copying | blue |
| verifying | orange |
| copyComplete | neutral/success-muted |
| safeToFormat | green |
| error | red |
| cancelled | yellow |

UI must not show SAFE TO FORMAT before coordinator state is `safeToFormat`.

---

## 12. Coding Standards

Core rules:

- Simple > clever.
- Explicit > magic.
- Readable > abstract.
- Reliability > convenience.
- No business logic in Views.
- No workflow logic in ViewModels.
- No SwiftUI in Engines.
- No silent failures.

Swift:

- macOS 13+
- Swift 5.9+
- Swift 6 compatible
- prefer `async/await`
- use `actor` for shared mutable engine state when useful
- avoid `DispatchQueue` unless required for legacy APIs

Error handling:

Forbidden:

```swift
try?
catch {}
url!
```

Allowed only when justified and safe.

Preferred:

```swift
guard let value else {
    logger.error("Missing required value")
    return
}
```

Naming:

Good:

- `sourceFolderURL`
- `destinationFolderURL`
- `transferCoordinator`
- `bundledRsyncService`

Bad:

- `src`
- `dest`
- `mgr`
- `helper`

File rules:

- one primary type per file
- no `Helpers.swift`
- no `Utils.swift`
- no vague `Manager.swift`

---

## 13. Logging Rules

Required logs:

- app launch
- rsync path resolved
- rsync version detected
- source selected
- destination selected
- validation started
- validation failed
- validation passed
- transfer started
- transfer progress milestones if useful
- transfer cancelled
- transfer completed
- transfer failed
- verification started
- verification passed
- verification failed
- report generated

Categories:

- info
- warning
- error
- transfer
- verify
- system

Logs must be operator-readable.

---

## 14. Security and Source Safety

FST must never modify source media.

Forbidden on source:

- delete
- rename
- move
- metadata write
- hidden cleanup
- quarantine changes

Security scoped bookmarks:

- required for persisted folder access
- access must be started before filesystem operations
- access must be stopped after use when appropriate

---

## 15. Current Audit Checklist

Use this checklist before asking Codex to write more code.

### Rsync detection

- [ ] Bundled rsync exists in app/project.
- [ ] `BundledRsyncService` resolves correct path.
- [ ] Version check confirms 3.4.4.
- [ ] No silent fallback to `/usr/bin/rsync`.
- [ ] Failure message is clear.

### Speed limiter

- [ ] Unlimited omits `--bwlimit`.
- [ ] 50/120/240 MB/s convert correctly.
- [ ] Custom 20-300 MB/s clamps or rejects correctly.
- [ ] Logs/report show chosen limit.

### `.DS_Store` hang

- [ ] Exclusion policy is explicit.
- [ ] `.DS_Store` handling is tested.
- [ ] Exclusion does not remove media files.
- [ ] Parser does not stall on repeated metadata output.

### Progress accuracy

- [ ] Parser handles `--info=progress2` output.
- [ ] UI progress reaches 100% only after process success.
- [ ] Current speed and average speed are separate.
- [ ] ETA can be nil/unknown.

### Pipeline validation

- [ ] ready -> validating -> copying works.
- [ ] copy success + verify none -> copyComplete.
- [ ] copy success + verify pass -> safeToFormat.
- [ ] copy failure -> error.
- [ ] verify failure -> error.
- [ ] cancel during copy -> cancelled.
- [ ] cancel during verify -> cancelled.

### Report integrity

- [ ] App version is app version.
- [ ] Rsync version is rsync version.
- [ ] Final state matches coordinator state.
- [ ] Report never overstates safety.

---

## 16. Test Requirements

Minimum unit tests:

- `ProgressParserTests`
- `RsyncBandwidthLimitTests`
- `TransferStateTests`
- `TransferCoordinatorTests`
- `VerifyEngineTests`
- `ReportEngineTests`
- `BundledRsyncServiceTests`

Minimum integration/manual tests:

- small folder transfer
- folder with `.DS_Store`
- large media-like file transfer
- bandwidth-limited transfer
- unlimited transfer
- cancel transfer
- missing source
- destination disconnect if safe test rig available
- verification none
- random 33%
- full verify

---

## 17. AI Agent Operating Rules

Before code:

1. Identify phase.
2. Identify exact file(s).
3. State layer ownership.
4. Inspect existing code.
5. Modify smallest safe surface.
6. Add/update tests.
7. Report changed files and verification commands.

Do not:

- rewrite architecture
- generate whole app scaffold
- add queue/multi-destination/cloud/database
- introduce new dependencies
- change file structure without instruction
- hide uncertainty

When unsure:

Stop and ask.

---

## 18. Deprecated or Not Current

These older assumptions are no longer source-of-truth:

- `/usr/bin/rsync` as production transfer engine
- MVVM-only architecture
- queue system in near roadmap
- multi-destination MVP
- history database MVP
- APFS analysis as higher priority than transfer pipeline correctness

Current priority:

```text
Rsync correctness -> speed limiter -> progress accuracy -> verification -> SAFE TO FORMAT -> report integrity -> UI polish
```

---

## 19. Final Rule

When two implementations compete:

Choose the one easier to debug at 3:00 AM on set with a producer standing behind the DIT.

Never choose clever over safe.
