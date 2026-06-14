# **ARCHITECTURE.md**

# **FST — Technical Architecture**

Version: 1.0

Status: Architecture Locked

---

# **1\. Architecture Goals**

The architecture must prioritize:

1. Reliability  
2. Maintainability  
3. Testability  
4. Simplicity

The architecture must avoid:

* Massive ViewModels  
* Business Logic inside Views  
* Tight Coupling  
* Shared Mutable State  
* UI-dependent Core Logic

---

# **2\. Architectural Overview**

FST follows a layered architecture.

SwiftUI Views  
        ↓  
TransferViewModel  
        ↓  
TransferCoordinator  
        ↓  
 ┌───────────────┬───────────────┐  
 │               │               │  
RsyncEngine   VerifyEngine   ReportEngine  
 │               │               │  
 └───────────────┴───────────────┘  
        ↓  
Services  
        ↓  
Foundation / macOS APIs

---

# **3\. Layer Responsibilities**

## **UI Layer**

Purpose:

Render application state.

Contains:

* ContentView  
* SourceView  
* DestinationView  
* StatusView  
* LogsView  
* SettingsView

Responsibilities:

* User interaction  
* Display state  
* Trigger ViewModel actions

Must NOT:

* Execute rsync  
* Access filesystem directly  
* Run verification  
* Parse logs

---

# **4\. ViewModel Layer**

## **TransferViewModel**

Purpose:

Expose state to SwiftUI.

Responsibilities:

* Observable state  
* UI bindings  
* User actions

Example:

final class TransferViewModel: ObservableObject

Owns:

* sourceURL  
* destinationURL  
* bandwidthLimit  
* verificationMode  
* transferState  
* progress  
* speed  
* eta  
* logs

Must NOT:

* Execute business logic  
* Execute shell commands  
* Perform verification

Everything beyond UI state belongs elsewhere.

---

# **5\. Coordinator Layer**

## **TransferCoordinator**

This is the brain of the application.

Purpose:

Control workflow.

Responsibilities:

* Validate input  
* Start transfer  
* Monitor transfer  
* Start verification  
* Generate report  
* Manage state transitions

Example workflow:

Validate

↓

Copy

↓

Verify

↓

Generate Report

↓

Safe To Format

Only TransferCoordinator may transition application states.

---

# **6\. Engine Layer**

Engine layer contains pure business logic.

No UI dependencies.

No SwiftUI imports.

No AppKit imports.

---

# **7\. RsyncEngine**

Purpose:

Execute and monitor rsync.

Responsibilities:

* Build command arguments  
* Launch Process  
* Read stdout  
* Read stderr  
* Parse progress  
* Parse speed  
* Parse ETA  
* Cancel process

Input:

TransferRequest

Output:

TransferEvent

---

# **8\. TransferRequest**

struct TransferRequest {

    let sourceURL: URL

    let destinationURL: URL

    let bandwidthLimit: Int?

}

Immutable.

Created by Coordinator.

---

# **9\. TransferEvent**

enum TransferEvent {

    case started

    case progress(Double)

    case speed(String)

    case eta(String)

    case log(String)

    case completed

    case failed(Error)

}

Used to communicate with Coordinator.

---

# **10\. Rsync Process Lifecycle**

State Flow:

Create Process

↓

Attach Pipes

↓

Launch

↓

Read Output

↓

Parse Events

↓

Emit Events

↓

Exit

↓

Cleanup

Rules:

* Never block Main Thread  
* Never call waitUntilExit() on UI thread  
* Always cleanup pipes

---

# **11\. Output Parsing**

Preferred rsync flag:

\--info=progress2

Example:

1,245,890,560 48% 120.34MB/s 0:01:30

Extract:

* Progress  
* Throughput  
* ETA

Parser must tolerate malformed lines.

Parser must never crash.

---

# **12\. VerifyEngine**

Purpose:

Validate copied data.

Independent from rsync.

Responsibilities:

* File discovery  
* Sampling  
* Hash generation  
* Hash comparison

Input:

VerificationRequest

Output:

VerificationResult

---

# **13\. Verification Modes**

enum VerificationMode {

    case none

    case random33

    case full  
}

---

# **14\. Random Verification Strategy**

Steps:

1. Scan copied files  
2. Build file list  
3. Randomly select 33%  
4. Generate xxHash64  
5. Compare source vs destination

Requirements:

* Truly random selection  
* Stable execution  
* Deterministic result reporting

---

# **15\. ReportEngine**

Purpose:

Generate transfer reports.

Output:

TXT

Future:

PDF support is intentionally excluded.

Responsibilities:

* Build report model  
* Format text  
* Save file

---

# **16\. Service Layer**

Services wrap macOS APIs.

Services contain no business logic.

---

# **17\. DriveService**

Purpose:

Filesystem operations.

Responsibilities:

* Folder validation  
* Size calculation  
* Free space calculation  
* Path checks

Examples:

folderExists()

calculateSize()

freeSpace()

---

# **18\. ShellService**

Purpose:

Launch shell processes.

Responsibilities:

* Process creation  
* Pipe management  
* Output streaming

Used by:

* RsyncEngine

Never used directly by UI.

---

# **19\. LoggerService**

Purpose:

Centralized logging.

Responsibilities:

* Store logs  
* Categorize logs  
* Export logs

Categories:

info

warning

error

transfer

verify

system

Thread-safe.

---

# **20\. SecurityBookmarkService**

Purpose:

Persistent folder access.

Responsibilities:

* Save bookmark  
* Restore bookmark  
* Resolve bookmark

Required for:

* Source Folder  
* Destination Folder

Must support:

* App relaunch  
* macOS sandbox rules

---

# **21\. State Machine**

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

Rules:

Only TransferCoordinator may change state.

---

# **22\. Concurrency Model**

MainActor:

* UI updates only

Background:

* rsync  
* hashing  
* scanning  
* report generation

Never perform:

* File hashing  
* Directory traversal  
* Process execution

on MainActor.

---

# **23\. Error Handling Strategy**

Low-level errors:

POSIX

Process

Filesystem

must be mapped into:

UserFacingError

Example:

Instead of:

Exit Code 23

Display:

Destination drive disconnected.

---

# **24\. Dependency Rules**

Allowed Direction:

View  
 ↓  
ViewModel  
 ↓  
Coordinator  
 ↓  
Engine  
 ↓  
Service

Never:

Service → ViewModel

Engine → View

Coordinator → SwiftUI

Dependencies flow downward only.

---

# **25\. Testing Strategy**

Unit Tests:

* Parser  
* Verification  
* Coordinator  
* State Machine

Integration Tests:

* Rsync execution  
* Verification workflow  
* Report generation

Manual Tests:

* SSD copy  
* HDD copy  
* Drive disconnect  
* Transfer cancel  
* Low free space

---

# **26\. Future Extension Points**

Reserved for:

* Multiple destinations  
* Queue system  
* MHL generation  
* LTO workflows

These features must be implemented without changing the core architecture.

The architecture should remain stable after MVP release.

