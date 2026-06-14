# **FST — AI Coding Agent Guide**

Version: 1.0

Status: Locked

Applies To:

* ChatGPT Codex  
* Claude Opus  
* Claude Sonnet  
* GPT-5  
* Cursor  
* Windsurf  
* Future AI Coding Agents

---

# **1\. Mission**

You are contributing to FST.

FST is a professional macOS transfer verification tool for DIT workflows.

Its purpose is:

COPY

↓

VERIFY

↓

SAFE TO FORMAT

FST is not:

* Hedge Clone  
* Media Asset Manager  
* Project Manager  
* File Browser  
* DAM  
* MAM

Do not introduce unrelated functionality.

---

# **2\. Read Documentation First**

Before generating code, always follow:

Priority Order:

PRD.md

↓

ARCHITECTURE.md

↓

STATE\_MACHINE.md

↓

RSYNC\_ENGINE\_SPEC.md

↓

VERIFY\_ENGINE\_SPEC.md

↓

CODING\_STANDARDS.md

↓

FILE\_STRUCTURE.md

↓

UI\_GUIDELINES.md

Documentation is the source of truth.

Generated code must conform to documentation.

Documentation always wins.

---

# **3\. Architecture Rules**

FST uses:

MVVM

\+

Coordinator

\+

Engine Layer

\+

Service Layer

Never bypass architecture.

Forbidden:

View → Engine

View → Service

Engine → View

Service → ViewModel

Allowed:

View

↓

ViewModel

↓

Coordinator

↓

Engine

↓

Service

---

# **4\. Responsibility Rules**

Each layer has exactly one responsibility.

---

Views

Allowed:

* Layout  
* Rendering  
* User interaction

Forbidden:

* Business logic  
* rsync logic  
* Hash generation  
* File scanning

---

ViewModels

Allowed:

* UI State  
* Published Properties  
* Formatting

Forbidden:

* Workflow logic  
* Process execution

---

Coordinator

Allowed:

* Workflow orchestration  
* State transitions  
* Validation  
* Report generation

Forbidden:

* SwiftUI  
* UI rendering

---

Engines

Allowed:

* Transfer logic  
* Verification logic

Forbidden:

* UI state  
* SwiftUI imports

---

Services

Allowed:

* System API wrappers

Forbidden:

* Workflow logic

---

# **5\. File Creation Rules**

When creating new files:

Place them in the correct folder.

Examples:

RsyncEngine.swift

→ Engines/

LoggerService.swift

→ Services/

TransferState.swift

→ Models/

Never create:

Helpers.swift

Utils.swift

Manager.swift

Misc.swift

Forbidden.

---

# **6\. Code Generation Strategy**

Generate code incrementally.

Preferred:

One file at a time.

Example:

Step 1

Create TransferState.swift

Step 2

Create VerificationMode.swift

Step 3

Create TransferRequest.swift

Avoid generating entire application scaffolds in one response.

---

# **7\. SwiftUI Rules**

Views should remain small.

Target:

\< 200 lines

Maximum:

300 lines

After that:

Refactor.

---

# **8\. Concurrency Rules**

Preferred:

async/await

Preferred:

Task

Preferred:

actor

Avoid:

DispatchQueue

unless required for legacy APIs.

---

# **9\. MainActor Rules**

MainActor is reserved for:

UI updates only

Never execute:

rsync

hashing

verification

directory scanning

on MainActor.

---

# **10\. Rsync Rules**

Use:

/usr/bin/rsync

Required Flags:

\-a  
\-h  
\--info=progress2

Optional:

\--bwlimit

Do not invent additional flags.

Do not optimize without specification.

---

# **11\. Verification Rules**

Verification uses:

xxHash64

Modes:

None

Random 33%

Full

Do not introduce:

SHA256

MD5

CRC32

unless explicitly requested in future versions.

---

# **12\. SAFE TO FORMAT Rules**

Critical Rule:

SAFE\_TO\_FORMAT appears only when:

Copy Success

AND

Verification Passed

Never bypass this rule.

Never create shortcuts.

Never auto-approve.

---

# **13\. State Machine Rules**

Follow:

STATE\_MACHINE.md

Exactly.

Current states:

ready

validating

copying

verifying

copyComplete

safeToFormat

error

cancelled

Do not create additional states.

Do not rename states.

---

# **14\. Error Handling Rules**

Never expose raw rsync errors to users.

Bad:

Exit Code 23

Good:

Destination drive disconnected.

Map technical errors into operator-friendly messages.

---

# **15\. Logging Rules**

All major actions must generate logs.

Required:

Transfer Started

Transfer Completed

Transfer Failed

Verification Started

Verification Completed

Verification Failed

---

# **16\. Dependency Rules**

Dependencies only flow downward.

Allowed:

View

↓

ViewModel

↓

Coordinator

↓

Engine

↓

Service

Reverse dependencies forbidden.

---

# **17\. Third-Party Libraries**

MVP Policy:

No third-party dependencies.

Use:

Foundation

SwiftUI

AppKit

UniformTypeIdentifiers

Only.

Exception:

xxHash implementation.

Must be approved.

---

# **18\. Code Style Rules**

Prefer:

guard

over:

if let

when appropriate.

Prefer:

explicit names

over:

abbreviations

Bad:

src

dest

mgr

Good:

sourceFolderURL

destinationFolderURL

transferCoordinator

---

# **19\. Optional Rules**

Avoid:

\!

Forbidden unless mathematically guaranteed.

Preferred:

guard let

---

# **20\. Error Rules**

Never use:

try?

for critical operations.

Never use:

catch {}

All failures must be logged.

---

# **21\. Performance Rules**

Target:

UI CPU \< 5%

Engine CPU \< 25%

Memory \< 300 MB

No busy loops.

No polling loops.

No timer-based file scanning.

Prefer event-driven architecture.

---

# **22\. Test Rules**

Every generated Engine requires:

Unit Tests

Every generated Parser requires:

Unit Tests

Every generated Coordinator requires:

Unit Tests

Do not generate production code without tests.

---

# **23\. Refactoring Rules**

Before introducing abstraction:

Ask:

Is there a real duplication problem?

If not:

Do not abstract.

Prefer:

simple explicit code

over:

generic reusable framework

---

# **24\. Code Review Checklist**

Before proposing code:

Verify:

□ Matches PRD

□ Matches Architecture

□ Matches State Machine

□ Runs on macOS 13+

□ No business logic in Views

□ No SwiftUI in Engines

□ No unnecessary abstraction

□ No third-party dependencies

□ Thread-safe

□ Testable

---

# **25\. Generation Workflow**

Preferred workflow:

Read Spec

↓

Generate Model

↓

Generate Service

↓

Generate Engine

↓

Generate Coordinator

↓

Generate ViewModel

↓

Generate View

↓

Generate Tests

Never reverse this order.

---

# **26\. What Success Looks Like**

A new DIT should be able to:

1. Open FST  
2. Select Source  
3. Select Destination  
4. Press Start  
5. Receive SAFE TO FORMAT

Without reading documentation.

Every line of generated code should contribute toward that goal.

---

# **27\. Final Rule**

When faced with two implementations:

Choose the implementation that is easier to debug at 3:00 AM on a film set with a producer standing behind the operator.

Not the implementation that appears more sophisticated.

