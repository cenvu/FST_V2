<!-- FST / CenVu | (+84) 842 841 222 -->

# FST — Technical Architecture

Version: 2.0  
Status: Architecture Locked  
Target: macOS 13+  
Language: Swift 5.9+ / Swift 6 compatible  
Architecture: MVVM + Coordinator + Engine + Service  
Core Engine: Bundled rsync 3.4.4

---

## 1. Mission

FST exists to answer one field question:

**Is the source media safe to erase?**

Workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT
```

Architecture must protect:

1. Data Safety
2. Reliability
3. Repeatability
4. Maintainability
5. Performance

Reject clever code that weakens field debugging.

---

## 2. Locked Scope

MVP supports:

- Single source
- Single destination
- Single active transfer job
- Folder-based copy
- Speed limit control
- Verification
- TXT report
- SAFE TO EJECT gate

MVP forbids:

- Multi-job queue
- Multi-destination copy
- Cloud sync
- MHL/LTO
- DAM/MAM features
- Proxy generation
- AI features inside app
- Database/history engine

---

## 3. Layer Map

```text
SwiftUI Views
    -> TransferViewModel
        -> TransferCoordinator
            -> RsyncEngine
            -> VerifyEngine
            -> ReportEngine
                -> Services
                    -> Foundation / macOS APIs
```

Dependency rule:

```text
View -> ViewModel -> Coordinator -> Engine -> Service
```

Reverse dependency is forbidden.

---

## 4. Layer Orders

### Views

Own:

- Layout
- Rendering
- User input
- Drag/drop UI

Never:

- Execute rsync
- Parse rsync output
- Hash files
- Scan directories
- Touch filesystem directly
- Change TransferState directly

### TransferViewModel

Own:

- `@Published` UI state
- UI formatting
- Button enable/disable state
- Calls into Coordinator

Never:

- Execute workflow
- Run Process
- Verify files
- Generate reports
- Contain transfer business rules

### TransferCoordinator

Own:

- Workflow orchestration
- Validation
- State transition
- Error mapping
- Report trigger
- SAFE TO EJECT decision

Only Coordinator may change `TransferState`.

### Engines

Own business execution.

Must be:

- UI-free
- SwiftUI-free
- AppKit-free unless explicitly justified
- Testable
- Async-safe

### Services

Wrap system APIs only.

Never own workflow policy.

---

## 5. Core Components

### Models

Required:

- `TransferState`
- `VerificationMode`
- `TransferRequest`
- `TransferResult`
- `TransferEvent`
- `VerificationRequest`
- `VerificationResult`
- `LogEntry`
- `TransferReport`
- `UserFacingError`

Model rules:

- Prefer immutable structs
- No SwiftUI imports
- No Process execution
- No filesystem side effects

---

## 6. TransferState

Allowed states only:

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

Rules:

- No extra states
- No rename
- No skipped terminal decision
- Coordinator owns transitions

State flow:

```text
ready
 -> validating
 -> copying
 -> verifying
 -> safeToFormat
```

If verification is disabled:

```text
ready -> validating -> copying -> copyComplete
```

Failure path:

```text
any active state -> error | cancelled
```

---

## 7. SAFE TO EJECT Gate

Absolute rule:

```text
SAFE_TO_EJECT = copy succeeded AND verification passed
```

If verification mode is `none`:

```text
Final state = copyComplete
Never safeToFormat
```

No shortcut.  
No manual override.  
No auto-approve.

---

## 8. RsyncEngine

Purpose:

- Execute bundled rsync
- Stream output
- Parse progress
- Emit transfer events
- Support cancellation

Required rsync source:

```text
App Bundle rsync 3.4.4
```

Forbidden default:

```text
/usr/bin/rsync
```

`/usr/bin/rsync` is allowed only as an explicit diagnostic fallback, never silent production fallback.

Required behavior:

- Detect bundled rsync path
- Verify rsync executable exists
- Verify rsync version
- Log detected path and version separately from app version
- Fail clearly if bundled rsync is missing or invalid

Required flags:

```text
-a
-h
--info=progress2
```

Optional flag:

```text
--bwlimit=<KB_PER_SECOND>
```

Do not add undocumented flags.

---

## 9. Speed Limiter Rule

UI speed unit:

```text
MB/s
```

Rsync `--bwlimit` unit:

```text
KB/s
```

Conversion:

```text
bwlimitKB = selectedMBps * 1024
```

Presets:

- 50 MB/s -> 51200 KB/s
- 120 MB/s -> 122880 KB/s
- 240 MB/s -> 245760 KB/s
- Unlimited -> no `--bwlimit`

Custom range:

```text
20...300 MB/s
```

Reject invalid values before launching rsync.

---

## 10. Rsync Output Parser

Input example:

```text
1,245,890,560 48% 120.34MB/s 0:01:30
```

Extract:

- Progress percent
- Current speed
- ETA
- Current file when available

Parser rules:

- Tolerate malformed lines
- Never crash on unknown output
- Ignore noise safely
- Unit-test progress lines
- Unit-test `.DS_Store` cases
- Unit-test localized or partial output where possible

---

## 11. `.DS_Store` Hang Watch

Known audit item:

- Investigate transfer stalls around `.DS_Store`
- Determine whether stall is parser issue, rsync output issue, filesystem lock, permission issue, or UI update issue

Rules:

- Do not hide `.DS_Store` failures silently
- Do not special-case skip unless verified safe
- Log current file and last parsed rsync line
- Keep cancellation responsive during stall

---

## 12. Rsync Process Lifecycle

Flow:

```text
resolve bundled rsync
 -> build validated args
 -> create Process
 -> attach stdout/stderr pipes
 -> launch
 -> stream output async
 -> parse events
 -> await exit
 -> map status
 -> cleanup
```

Rules:

- Never block MainActor
- Never call `waitUntilExit()` on UI thread
- Always close pipes
- Always terminate child process on cancel
- Always log exit status
- Map technical failure to `UserFacingError`

---

## 13. TransferEvent

Recommended shape:

```swift
enum TransferEvent {
    case started
    case progress(percent: Double)
    case speed(current: String, average: String?)
    case eta(String)
    case currentFile(String)
    case log(String)
    case completed(TransferResult)
    case failed(UserFacingError)
    case cancelled
}
```

Event rules:

- Engine emits events
- Coordinator interprets events
- ViewModel displays derived state
- View renders only

---

## 14. VerifyEngine

Purpose:

- Discover files
- Select verification set
- Hash source and destination
- Compare hashes
- Return result

Algorithm:

```text
xxHash64
```

Modes:

```swift
enum VerificationMode {
    case none
    case random33
    case full
}
```

Rules:

- `none` skips VerifyEngine and ends as `copyComplete`
- `random33` samples approximately 33% of files
- `full` verifies all files
- No SHA256, MD5, CRC32 unless future spec approves
- Hashing never runs on MainActor

---

## 15. Random Verification

Required:

- Build full file list
- Select around 33%
- Report selected count and total count
- Compare matching relative paths
- Fail if destination file is missing
- Fail if hash mismatch

Reporting must be deterministic even if selection is random.

Minimum report fields:

- Mode
- Total files
- Checked files
- Passed count
- Failed count
- Missing count
- Duration

---

## 16. ReportEngine

Output:

```text
TXT only
```

No PDF.  
No database.  
No history engine in MVP.

Report includes:

- Date/time
- App version
- Bundled rsync version
- Rsync path
- Source path
- Destination path
- File count
- Total size
- Bandwidth limit
- Transfer duration
- Average speed
- Verification mode
- Verification result
- Error count
- Final state

---

## 17. Services

### DriveService

Own:

- Folder existence
- Read/write permission check
- Source size
- Destination free space
- Mounted volume information

Never:

- Decide workflow state
- Launch rsync

### ShellService

Own:

- Process creation
- Pipe streaming
- Exit code collection

Used by:

- RsyncEngine only

### LoggerService

Own:

- Thread-safe logs
- Log categories
- TXT export support

Required categories:

```text
INFO, WARNING, ERROR, TRANSFER, VERIFY, SYSTEM
```

### BookmarkService

Own:

- Security-scoped bookmark save
- Resolve bookmark
- Start/stop access

Required for:

- Source folder
- Destination folder

### VersionService

Own:

- App version
- Build number
- Bundled rsync version

Rule:

```text
App version != rsync version
```

Never display rsync version as app version.

---

## 18. Storage Validation

Before transfer:

- Source exists
- Source is readable
- Source is folder
- Source is not empty
- Destination exists
- Destination is writable
- Destination is folder
- Destination free space >= source size

If validation fails:

- Do not start rsync
- Set user-facing error
- Log technical details

---

## 19. Concurrency

Use:

- `async/await`
- `Task`
- `actor` when shared mutable state exists

Avoid:

- `DispatchQueue` unless required by legacy API

MainActor only:

- Published UI updates
- View rendering

Never on MainActor:

- rsync
- hashing
- directory traversal
- report generation
- pipe reading

---

## 20. Error Strategy

Never show raw technical errors as final user message.

Bad:

```text
rsync exit code 23
```

Good:

```text
Some files could not be copied. Check the log before formatting the source.
```

Log both:

- User-facing message
- Technical diagnostic detail

Required mappings:

- Missing bundled rsync
- Invalid rsync version
- Permission denied
- Destination disconnected
- Not enough space
- Hash mismatch
- Verification missing file
- Transfer cancelled

---

## 21. Testing

Unit tests required for:

- Rsync path detection
- Rsync version parsing
- Speed limiter conversion
- Progress parser
- TransferState transitions
- SAFE TO EJECT gate
- Verification sampling
- Hash comparison
- Error mapping

Integration tests required for:

- Rsync dry-run or fixture execution
- Cancel transfer
- Verification workflow
- TXT report generation

Manual field tests required for:

- SSD copy
- HDD copy
- NVMe enclosure copy
- Low free space
- Drive disconnect
- `.DS_Store` stall reproduction
- Long transfer session

---

## 22. Current Audit Priorities

Codex must prioritize these before new features:

1. Bundled rsync detection and version accuracy
2. App version vs rsync version separation
3. Speed limiter correctness
4. `.DS_Store` hang investigation
5. Progress reporting accuracy
6. Transfer pipeline validation
7. Cancellation safety
8. SAFE TO EJECT enforcement

No feature work may bypass these.

---

## 23. Build / Platform

Target:

- macOS 13+
- Apple Silicon first
- Intel optional unless explicitly required

Swift:

- Swift 5.9+ baseline
- Swift 6 compatible code preferred

Dependencies:

- Foundation
- SwiftUI
- AppKit where UI/macOS integration requires it
- UniformTypeIdentifiers
- Approved xxHash implementation only

No dependency injection framework.  
No third-party UI framework.

---

## 24. AI Agent Rules

Before coding, agent must report:

```text
PHASE:
FILES:
TARGET:
RISK:
TEST:
```

When modifying code:

- Touch minimum files
- Preserve architecture boundary
- Include tests for engine/parser/coordinator changes
- No placeholder business logic
- No TODO replacing required implementation
- No silent fallback to system rsync

When uncertain:

- Stop before destructive change
- Ask only if blocking
- Prefer safe partial fix over broad rewrite

---

## 25. V1 Worklog Integration

Legacy V1 status:

- Prototype completed
- Initial SwiftUI project built
- Dashboard UI launched
- Core structure exists

Legacy roadmap is no longer source of truth.

Superseded items:

- `/usr/bin/rsync` production engine
- MVVM-only architecture
- Database/history in early roadmap
- Queue/multi-destination before MVP safety completion

Current implementation order:

1. Fix rsync engine foundation
2. Fix speed limiter
3. Fix parser/progress
4. Validate cancellation
5. Add verification
6. Enforce SAFE TO EJECT
7. Generate TXT report
8. Polish UI only after pipeline is reliable

---

## 26. Final Rule

At 3:00 AM on set, with a producer behind the operator:

Choose the code path that is easiest to inspect, explain, cancel, and verify.

Data safety beats speed.  
Reliability beats cleverness.  
Architecture beats convenience.
