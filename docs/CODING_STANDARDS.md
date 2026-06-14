# **CODING\_STANDARDS.md**

# **FST — Engineering Standards**

Version: 1.0

Status: Locked

Applies To:

* Human Developers  
* Claude  
* Codex  
* Future Contributors

---

# **1\. Core Philosophy**

FST is a reliability-first application.

The codebase must prioritize:

1. Readability  
2. Predictability  
3. Maintainability  
4. Reliability

Over:

* Cleverness  
* Abstraction  
* Design Patterns  
* Shorter Code

The simplest solution that is easy to understand is preferred.

---

# **2\. Golden Rules**

## **Rule \#1**

If a junior developer cannot understand the code within 30 seconds:

Rewrite it.

---

## **Rule \#2**

Avoid unnecessary abstractions.

Do not create protocols, generics, factories, builders, or dependency injection containers unless they solve a real problem.

---

## **Rule \#3**

Prefer explicit code over magic.

Bad:

magicManager.execute()

Good:

rsyncEngine.startTransfer(request)

---

## **Rule \#4**

Business logic must never live inside SwiftUI Views.

Views render state.

Nothing more.

---

## **Rule \#5**

ViewModels are not Coordinators.

ViewModels expose state.

Coordinators manage workflows.

---

# **3\. Swift Version**

Minimum:

Swift 5.9

Supported:

Swift 6 Compatible

Avoid using APIs that require macOS 15 unless absolutely necessary.

Target compatibility:

macOS 13+

---

# **4\. File Organization**

Every file should contain one primary type.

Good:

TransferCoordinator.swift

RsyncEngine.swift

LoggerService.swift

Bad:

Helpers.swift

Utils.swift

Extensions.swift

---

# **5\. Folder Structure**

FST

├── App  
│  
├── Views  
│  
├── ViewModels  
│  
├── Coordinators  
│  
├── Engines  
│  
├── Services  
│  
├── Models  
│  
├── Utilities  
│  
├── Resources  
│  
└── Tests

Never create arbitrary folders.

---

# **6\. Naming Conventions**

Use clear names.

Prefer:

transferCoordinator

verificationMode

sourceFolderURL

Avoid:

coord

vm

src

dest

Names must communicate intent.

---

# **7\. Type Naming**

Classes:

TransferCoordinator

RsyncEngine

LoggerService

Enums:

TransferState

VerificationMode

Structs:

TransferRequest

VerificationResult

Protocols:

TransferReporting

HashGenerating

Only create protocols when multiple implementations are expected.

---

# **8\. SwiftUI Standards**

Views should remain lightweight.

Target:

Less than 200 lines per View.

If a View exceeds:

300 lines

Refactor.

---

# **9\. ViewModel Standards**

ViewModels:

Allowed:

* UI state  
* Bindings  
* Formatting

Forbidden:

* Process execution  
* Hash generation  
* Filesystem scanning  
* rsync logic

Example:

Good:

viewModel.progress

Bad:

viewModel.startRsync()

---

# **10\. Coordinator Standards**

Coordinators own workflows.

Example:

Validate

↓

Copy

↓

Verify

↓

Generate Report

↓

Safe To Format

Workflow decisions belong here.

Nowhere else.

---

# **11\. Service Standards**

Services wrap system APIs.

Examples:

DriveService

LoggerService

BookmarkService

Services do not contain workflow logic.

Services do not update UI.

---

# **12\. Engine Standards**

Engines contain core business logic.

Examples:

RsyncEngine

VerifyEngine

ReportEngine

Requirements:

* No SwiftUI  
* No AppKit  
* No UI state

Engines should be reusable.

---

# **13\. Concurrency Standards**

Use:

async/await

Prefer:

Task

Avoid:

DispatchQueue.main.async

unless absolutely required.

---

# **14\. Main Thread Rules**

MainActor is reserved for:

* UI updates  
* ObservableObject updates

Never execute:

* rsync  
* hashing  
* scanning  
* file traversal

on MainActor.

---

# **15\. Error Handling**

Never ignore errors.

Bad:

try? save()

Bad:

catch {}

Good:

do {

    try save()

} catch {

    logger.error(error)

}

Every failure must be traceable.

---

# **16\. Logging Standards**

All critical operations must be logged.

Required:

* Transfer Started  
* Transfer Completed  
* Transfer Failed  
* Verify Started  
* Verify Completed  
* Verify Failed

Log levels:

info

warning

error

debug

---

# **17\. Force Unwrap Policy**

Never use:

\!

unless mathematically guaranteed.

Forbidden:

url\!

Preferred:

guard let url else {

    return  
}

---

# **18\. Optional Handling**

Prefer:

guard

over deeply nested:

if let

Maximum nesting depth:

3 levels

If deeper:

Refactor.

---

# **19\. Magic Numbers**

Never hardcode unexplained values.

Bad:

if size \> 52428800

Good:

let minimumFreeSpaceMB \= 50

---

# **20\. Constants**

Centralize shared constants.

Example:

enum AppConstants {

    static let defaultVerifyRatio \= 0.33

}

Avoid duplicated values.

---

# **21\. State Management**

Application state must flow:

Coordinator

↓

ViewModel

↓

View

Never:

View

↓

Engine

Never:

View

↓

Service

---

# **22\. Dependency Direction**

Allowed:

Views

↓

ViewModels

↓

Coordinators

↓

Engines

↓

Services

Dependencies only flow downward.

Reverse dependencies are forbidden.

---

# **23\. Testing Requirements**

Every Engine requires:

* Unit Tests

Every Coordinator requires:

* Unit Tests

Every Parser requires:

* Unit Tests

Minimum coverage target:

70%

---

# **24\. Rsync Standards**

Always use:

\--info=progress2

Never parse UI strings.

Parse machine-readable output whenever possible.

Parser failures must never crash the application.

---

# **25\. Verification Standards**

Verification logic must remain independent of rsync.

Copy and Verify are separate responsibilities.

Never mix them.

---

# **26\. Security Standards**

Source media is always read-only.

FST must never:

* Rename source files  
* Delete source files  
* Move source files  
* Modify source metadata

The application exists to protect source media.

---

# **27\. Performance Standards**

Target:

UI CPU Usage:

\< 5%

Memory:

\< 300 MB

Normal transfer operation:

No UI stutter.

No blocking calls.

No polling loops.

---

# **28\. Code Review Checklist**

Before merging:

* Does it increase reliability?  
* Does it reduce readability?  
* Does it introduce unnecessary abstraction?  
* Does it violate architecture?  
* Does it run on macOS 13?  
* Does it preserve source media safety?

If any answer is problematic:

Do not merge.

---

# **29\. AI Code Generation Rules**

Applicable to:

* Claude  
* Codex  
* ChatGPT  
* Future AI Tools

Generated code must:

* Follow architecture  
* Follow naming conventions  
* Avoid unnecessary abstractions  
* Avoid dependency injection frameworks  
* Avoid third-party libraries unless approved

Generated code is never trusted until reviewed.

---

# **30\. Final Rule**

When faced with two solutions:

Choose the one that is easier to debug at 3:00 AM on a film set.

Not the one that looks more impressive on GitHub.

