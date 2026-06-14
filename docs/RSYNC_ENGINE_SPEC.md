# **RSYNC\_ENGINE\_SPEC.md**

# **FST — Rsync Engine Specification**

Version: 1.0

Status: Locked

Owner:

RsyncEngine

---

# **1\. Purpose**

RsyncEngine is responsible for executing, monitoring and controlling all file transfer operations within FST.

RsyncEngine is the transport layer of the application.

It does not:

* Manage UI  
* Manage workflow  
* Manage verification  
* Manage application state

Its sole responsibility is reliable file transfer.

---

# **2\. Design Principles**

RsyncEngine must be:

* Deterministic  
* Observable  
* Cancelable  
* Recoverable  
* UI Independent

The engine should expose structured events rather than raw terminal output.

---

# **3\. Engine Responsibilities**

RsyncEngine owns:

* rsync command construction  
* process launch  
* stdout monitoring  
* stderr monitoring  
* progress parsing  
* throughput parsing  
* ETA parsing  
* process cancellation  
* exit code handling  
* event emission

---

# **4\. Engine Boundaries**

Input:

TransferRequest

Output:

TransferEvent

The engine must never communicate directly with:

SwiftUI

Views

ViewModels

Only TransferCoordinator may consume engine events.

---

# **5\. Rsync Version Strategy**

FST MVP uses:

/usr/bin/rsync

Reason:

* Always available  
* No dependency management  
* Maximum compatibility

MVP does not bundle custom rsync binaries.

Future support may allow:

rsync 3.2+

but is out of scope.

---

# **6\. Supported Command Format**

Base Command:

/usr/bin/rsync

Required Flags:

\-a  
\-h  
\--info=progress2

Optional:

\--bwlimit

Generated Example:

/usr/bin/rsync \\  
\-a \\  
\-h \\  
\--info=progress2 \\  
\--bwlimit=120000 \\  
"/Source/" \\  
"/Destination/"

---

# **7\. TransferRequest**

struct TransferRequest {

    let sourceURL: URL

    let destinationURL: URL

    let bandwidthLimitKB: Int?

}

Rules:

Immutable.

Validated before reaching engine.

---

# **8\. Process Creation**

Implementation:

Process()

Configuration:

process.executableURL

process.arguments

process.standardOutput

process.standardError

Requirements:

* One Process per transfer  
* No shared Process instances  
* No process reuse

---

# **9\. Pipe Architecture**

RsyncEngine owns:

stdoutPipe

stderrPipe

Purpose:

Capture output independently.

Requirements:

* Non-blocking  
* Continuous streaming  
* Auto cleanup

---

# **10\. Data Flow**

Rsync

↓

stdout/stderr

↓

Pipe

↓

Parser

↓

TransferEvent

↓

TransferCoordinator

Coordinator never sees raw rsync output.

---

# **11\. Event Model**

enum TransferEvent {

    case started

    case progress(Double)

    case speed(Double)

    case eta(TimeInterval)

    case currentFile(String)

    case log(String)

    case completed

    case cancelled

    case failed(Error)  
}

Only events leave the engine.

---

# **12\. Progress Parsing**

Input Example:

12,451,023,872  48%  118.34MB/s  0:03:12

Extract:

48%  
118.34 MB/s  
3m 12s

Parser must tolerate:

* malformed lines  
* partial lines  
* truncated lines

Parser must never crash.

---

# **13\. Current File Detection**

rsync occasionally emits file names.

Example:

A001\_C004\_0614AB.mov

Engine should emit:

.currentFile(...)

when possible.

Failure to detect current file must not impact transfer.

---

# **14\. Throughput Tracking**

Track:

Current Speed

Average Speed

Formula:

bytesTransferred / elapsedTime

Average speed is calculated internally.

Not parsed from rsync.

Reason:

More reliable reporting.

---

# **15\. ETA Calculation**

Preferred Source:

rsync ETA

Fallback:

remainingBytes

÷

averageSpeed

ETA should remain stable.

Avoid excessive fluctuations.

---

# **16\. Logging Rules**

All significant events must emit logs.

Examples:

Transfer Started

Transfer Cancelled

Transfer Completed

Transfer Failed

Logs are consumed by LoggerService.

RsyncEngine does not store logs.

---

# **17\. Exit Code Handling**

Capture:

process.terminationStatus

Always.

Never ignore exit codes.

---

# **18\. Exit Code Mapping**

Common rsync codes:

0  Success

1  Syntax Error

11 I/O Error

12 Protocol Error

20 User Interrupt

23 Partial Transfer

24 Source Files Vanished

30 Timeout

Mapped into:

TransferError

before leaving the engine.

---

# **19\. User Interrupt**

If user presses:

STOP

Engine performs:

process.terminate()

Expected Result:

TransferEvent.cancelled

Not:

TransferEvent.failed

---

# **20\. Force Stop Protection**

Never use:

SIGKILL

unless process becomes unresponsive.

Preferred:

terminate()

Graceful shutdown first.

---

# **21\. Process Cleanup**

Required after:

* completion  
* cancellation  
* failure

Cleanup:

close pipes

release process

release handlers

Memory leaks are unacceptable.

---

# **22\. Concurrency Model**

RsyncEngine must never execute on MainActor.

Requirements:

Task.detached

or equivalent background execution.

UI updates occur elsewhere.

---

# **23\. Error Categories**

enum TransferError {

    case processLaunchFailed

    case sourceUnavailable

    case destinationUnavailable

    case insufficientSpace

    case rsyncExit(Int32)

    case interrupted

    case timeout

    case unknown  
}

---

# **24\. Engine Lifecycle**

Created

↓

Configured

↓

Started

↓

Running

↓

Completed

Alternative exits:

Cancelled

Failed

Engine instance is discarded after transfer.

Never reused.

---

# **25\. Recovery Behavior**

Engine should fail fast.

Examples:

Missing Source

↓

Stop Immediately

Drive Removed

↓

Stop Immediately

No retry logic in MVP.

Retries belong to Coordinator.

---

# **26\. Performance Targets**

Transfer overhead:

\< 2% CPU

Memory:

\< 50 MB

No polling loops.

No busy waiting.

No timer-based parsing.

Everything should be event-driven.

---

# **27\. Thread Safety**

Engine must be thread-safe.

Shared mutable state should be minimized.

Prefer:

actor

for mutable transfer state.

Recommended:

actor RsyncEngine

---

# **28\. Testing Requirements**

Unit Tests:

* Progress Parser  
* ETA Parser  
* Exit Code Mapping  
* Event Generation

Integration Tests:

* Small Transfer  
* Large Transfer  
* Cancellation  
* Drive Disconnect

---

# **29\. Future Compatibility**

Reserved Features:

* Multiple Destinations  
* Queue System  
* Parallel Verification  
* Rsync 3.2 Support

Current MVP must not implement these.

Architecture should allow them.

---

# **30\. Engineering Rule**

The engine must never assume:

"Transfer completed means data is safe."

Transfer completion only means:

Data movement finished.

Data trust is determined by VerifyEngine.

Only VerifyEngine may contribute to:

SAFE\_TO\_FORMAT

Never RsyncEngine.

---

# **31\. Final Principle**

RsyncEngine moves data.

VerifyEngine establishes trust.

TransferCoordinator decides workflow.

UI communicates outcome.

Each layer has one responsibility.

No layer may assume the responsibility of another.

