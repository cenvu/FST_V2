# **FST — FOCUSED SECURE TRANSFER**

## **Project Master Guideline**

Version: 2.0

Status: Architecture Locked

Target Platform: macOS 13+

Language: Swift 5.9+

Framework: SwiftUI

Architecture:

MVVM \+ Coordinator \+ Engine \+ Service

Core Engine:

Native rsync Wrapper

Primary Objective:

Provide the safest possible folder-based media offload workflow for Digital Imaging Technicians.

---

# **Core Mission**

FST exists for one reason:

To help a DIT confidently determine when media is safe to erase.

The application does not exist to copy files.

The application exists to verify that copied data is trustworthy.

The workflow is:

SOURCE

↓

COPY

↓

VERIFY

↓

SAFE TO FORMAT

---

# **Product Philosophy**

Every feature must answer:

“Does this reduce the risk of media loss?”

If the answer is no:

Do not build it.

---

# **Real World Problem**

Modern SSDs and portable NVMe drives frequently exhibit:

* Write cache exhaustion  
* Thermal throttling  
* USB controller instability  
* Power delivery fluctuations  
* I/O timeout errors

In many cases these failures occur during sustained unrestricted transfers.

FST is designed specifically to mitigate these risks through controlled bandwidth management and transparent transfer visibility.

---

# **Design Goals**

Priority Order:

1. Data Integrity  
2. Reliability  
3. Transparency  
4. Simplicity  
5. Performance  
6. Features

If a feature compromises simplicity or reliability:

Reject it.

---

# **Target Users**

Primary:

* DIT  
* Data Wrangler  
* Assistant DIT

Secondary:

* Assistant Editor  
* Production Assistant  
* Small Production Teams

---

# **MVP Scope**

## **Source Selection**

Supported:

* Folder Drag & Drop  
* Folder Picker

Requirements:

* Source must be a directory  
* Source must be readable  
* Source cannot be empty

Not Supported:

* Entire Volume Copy  
* Multiple Sources  
* Batch Jobs

Reason:

Media cards are typically copied per card or per camera roll.

Single-job workflow minimizes operator error.

---

## **Destination Selection**

Supported:

* Folder Drag & Drop  
* Folder Picker

Requirements:

* Destination must be writable  
* Destination must have sufficient free space

Not Supported:

* Multiple Destinations  
* Mirrored Copy  
* Queue System

Reason:

Single destination significantly reduces workflow complexity and failure scenarios.

---

# **Folder Permissions**

FST must use:

Security Scoped Bookmarks

Goals:

* Survive application restart  
* Maintain folder access  
* Respect macOS sandbox rules

---

# **Storage Validation**

Before transfer begins:

FST must calculate:

* Source Size  
* Destination Free Space  
* Remaining Free Space After Copy

Transfer cannot begin when:

Destination Free Space \< Source Size

The Start button remains disabled.

---

# **Transfer Engine**

Engine:

/usr/bin/rsync

Required Arguments:

\-a

\-h

–info=progress2

Optional Arguments:

–bwlimit

Recommended Internal Flags:

–delete excluded

–checksum disabled during copy

Reason:

Maximum compatibility with macOS bundled rsync.

---

# **Bandwidth Control**

Purpose:

Prevent drive cache saturation.

Prevent thermal throttling.

Improve stability on budget SSDs and HDDs.

Presets:

50 MB/s

120 MB/s

240 MB/s

Unlimited

Custom Range:

20 MB/s → 300 MB/s

Implementation:

rsync –bwlimit

Unlimited:

No bandwidth restriction.

---

# **Transfer Monitoring**

The engine must provide:

* Progress Percentage  
* Current Throughput  
* Average Throughput  
* Estimated Remaining Time  
* Current File Name

All values must update in real time.

---

# **Verification Philosophy**

Verification is not optional from a workflow perspective.

Verification determines trust.

---

# **Verification Modes**

## **None**

Copy only.

Result:

COPY COMPLETE

Never SAFE TO FORMAT.

---

## **Random Verify**

Default Mode

Randomly sample approximately 33% of transferred files.

Verify using xxHash64.

Purpose:

Balance speed and confidence.

Recommended for daily production work.

---

## **Full Verify**

Verify every transferred file.

Purpose:

Maximum confidence.

Recommended for final archive deliveries.

---

# **Safe To Format Logic**

SAFE TO FORMAT appears only when:

Copy Status \= Success

AND

Verification Status \= Passed

If either condition fails:

SAFE TO FORMAT must never appear.

This rule is absolute.

---

# **Transfer States**

READY

COPYING

VERIFYING

SAFE TO FORMAT

ERROR

CANCELLED

---

# **Logging System**

Goals:

Provide complete operational transparency.

Requirements:

* Real Time  
* Auto Scroll  
* Monospace Font  
* Export TXT

Log Categories:

INFO

WARNING

ERROR

TRANSFER

VERIFY

SYSTEM

---

# **Transfer Report**

Format:

TXT

Purpose:

Human readable transfer record.

Report Contents:

Transfer Date

Source Path

Destination Path

Total Files

Total Size

Bandwidth Limit

Transfer Duration

Verification Mode

Verification Result

Error Count

Final Status

Operator Notes (Future)

---

# **User Interface Principles**

A DIT should understand the application within 30 seconds.

If explanation is required:

The UI has failed.

---

# **UI Layout**

Top Section

Source Folder

Destination Folder

Middle Section

Bandwidth Control

Verification Mode

Transfer Status

Bottom Section

Real Time Logs

Start Button

Stop Button

Export Report Button

---

# **System Architecture**

SwiftUI Views

↓

TransferViewModel

↓

TransferCoordinator

↓

RsyncEngine

VerifyEngine

↓

DriveService

ShellService

LoggerService

---

# **Layer Responsibilities**

## **TransferViewModel**

Owns:

* UI State  
* Bindings  
* Published Properties

Must not:

* Execute rsync  
* Execute verification  
* Access filesystem directly

---

## **TransferCoordinator**

Owns:

* Workflow orchestration  
* Validation  
* State transitions  
* Error handling

Acts as the central brain of the application.

---

## **RsyncEngine**

Owns:

* Process launch  
* Output parsing  
* Progress extraction  
* Throughput calculation  
* Cancellation

Must remain independent of UI.

---

## **VerifyEngine**

Owns:

* File sampling  
* xxHash generation  
* Hash comparison  
* Verification reporting

Must remain independent of rsync.

---

## **LoggerService**

Owns:

* Thread-safe logging  
* Log persistence  
* TXT export

---

# **Performance Rules**

Main Thread:

UI Updates Only

Background Threads:

* rsync  
* hashing  
* filesystem scanning  
* report generation  
* logging

No blocking operations are permitted on the main thread.

---

# **Development Rules**

Simple \> Clever

Readable \> Smart

Reliable \> Feature Rich

Maintainable \> Complex

Predictable \> Automated

Every new dependency must justify its existence.

Every new feature must reduce risk.

---

# **Definition of Success**

A first-time DIT must be able to:

1. Launch FST  
2. Select Source Folder  
3. Select Destination Folder  
4. Press Start

Without training.

Without documentation.

Without asking for help.

And confidently receive:

SAFE TO FORMAT

within a workflow that feels obvious and trustworthy.

If that goal is not achieved:

The feature, workflow, or interface must be simplified.

