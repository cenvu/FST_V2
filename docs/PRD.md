# **PRD.md**

# **FST — Focused Secure Transfer**

Version: 1.0

Status: MVP Scope Locked

Target Platform: macOS 13+

Language: Swift 5.9+

Framework: SwiftUI

Architecture: MVVM \+ Coordinator \+ Service Layer \+ Engine Layer

Core Technology: Native rsync Wrapper

---

# **1\. Product Overview**

FST (Focused Secure Transfer) is a macOS application designed for Digital Imaging Technicians (DITs), Data Wranglers, and media management professionals working in film, television, commercial, and documentary production environments.

The primary purpose of FST is to provide a reliable and transparent folder-based media offload workflow using rsync while allowing operators to control transfer speed in order to reduce the risk of storage-related failures.

FST is intentionally focused on one mission:

COPY → VERIFY → SAFE TO FORMAT

The application is not intended to be a media asset manager, production database, or project management tool.

---

# **2\. Problem Statement**

Modern production workflows frequently rely on portable SSDs, NVMe enclosures, USB-C docks, and bus-powered storage devices.

Although these devices often advertise high peak transfer speeds, they may experience:

* Write cache exhaustion  
* Thermal throttling  
* Controller instability  
* USB disconnects  
* Sustained write degradation  
* Read and write I/O errors

Most existing copy tools prioritize maximum transfer speed.

FST prioritizes transfer reliability and operator confidence.

The goal is not to achieve the fastest transfer.

The goal is to determine when media is safe to erase.

---

# **3\. Product Vision**

Enable any DIT to safely offload media with minimal training and maximum confidence.

A first-time user should be able to:

1. Launch the application  
2. Select a source folder  
3. Select a destination folder  
4. Configure transfer speed  
5. Start the transfer  
6. Receive a clear final result

Without consulting documentation.

---

# **4\. Product Principles**

Every feature must answer the following question:

"Does this reduce the risk of media loss?"

If the answer is no, the feature should not be included.

Development priorities:

1. Data Integrity  
2. Reliability  
3. Transparency  
4. Simplicity  
5. Performance  
6. Additional Features

---

# **5\. Target Users**

## **Primary Users**

* Digital Imaging Technicians (DIT)  
* Data Wranglers  
* Assistant DITs

## **Secondary Users**

* Assistant Editors  
* Production Assistants  
* Small Production Teams

---

# **6\. User Goals**

## **Goal 1**

Safely copy media from a source folder to a destination folder.

## **Goal 2**

Control transfer speed to improve storage stability.

## **Goal 3**

Verify transferred media.

## **Goal 4**

Know with certainty when source media can be erased.

---

# **7\. In Scope**

The MVP includes:

* Folder-based transfer  
* Transfer speed limiting  
* Transfer verification  
* Real-time transfer monitoring  
* Transfer logging  
* TXT report generation  
* Safe-to-format workflow

---

# **8\. Out of Scope**

The following features are explicitly excluded from MVP:

* Transfer queues  
* Multiple simultaneous jobs  
* Multiple destinations  
* Mirrored transfers  
* NAS management  
* RAID management  
* MHL generation  
* LTO workflows  
* Proxy generation  
* Asset management  
* Metadata browsing  
* Cloud synchronization  
* Team collaboration  
* AI-assisted workflows  
* Production database features

---

# **9\. Functional Requirements**

## **FR-001 Source Selection**

The application shall allow users to select a source folder.

Supported methods:

* Drag and drop  
* Folder picker

Requirements:

* Source must exist  
* Source must be readable  
* Source must be a folder  
* Source cannot be empty

---

## **FR-002 Destination Selection**

The application shall allow users to select a destination folder.

Supported methods:

* Drag and drop  
* Folder picker

Requirements:

* Destination must exist  
* Destination must be writable  
* Destination must be a folder

---

## **FR-003 Persistent Folder Access**

The application shall maintain folder access across launches using Security Scoped Bookmarks.

Requirements:

* Restore access after relaunch  
* Restore previously selected locations  
* Respect macOS security requirements

---

## **FR-004 Storage Validation**

Before starting a transfer, the application shall calculate:

* Source size  
* Available destination space  
* Remaining free space after transfer

The transfer shall not begin if sufficient space is unavailable.

---

## **FR-005 Transfer Execution**

The application shall execute transfers using:

/usr/bin/rsync

Required arguments:

\-a

\-h

\--info=progress2

Optional arguments:

\--bwlimit

The application shall not modify source files.

---

## **FR-006 Bandwidth Control**

The application shall support transfer speed limiting.

Presets:

* 50 MB/s  
* 120 MB/s  
* 240 MB/s  
* Unlimited

Custom Range:

20 MB/s to 300 MB/s

Purpose:

* Reduce storage stress  
* Prevent cache saturation  
* Improve transfer stability

---

## **FR-007 Transfer Monitoring**

The application shall display:

* Progress percentage  
* Current transfer speed  
* Average transfer speed  
* Estimated time remaining  
* Current file being processed

Updates should occur in near real time.

---

## **FR-008 Transfer Cancellation**

The application shall allow users to cancel active transfers.

Requirements:

* Terminate rsync safely  
* Preserve logs  
* Update status immediately

---

## **FR-009 Verification**

The application shall support three verification modes.

### **None**

No verification performed.

Final result:

COPY COMPLETE

### **Random Verify**

Default mode.

Approximately 33% of transferred files are randomly selected and verified.

### **Full Verify**

All transferred files are verified.

Verification algorithm:

xxHash64

---

## **FR-010 Safe To Format**

SAFE TO FORMAT is the highest confidence state in the application.

SAFE TO FORMAT shall only appear when:

* Copy completed successfully  
* Verification completed successfully

If verification is disabled:

Final state shall be:

COPY COMPLETE

SAFE TO FORMAT shall not be displayed.

---

## **FR-011 Real-Time Logging**

The application shall provide:

* Real-time logs  
* Auto-scrolling  
* Monospaced formatting  
* TXT export

Log categories:

* INFO  
* WARNING  
* ERROR  
* TRANSFER  
* VERIFY  
* SYSTEM

---

## **FR-012 Transfer Report**

The application shall generate a plain text transfer report.

The report shall contain:

* Date  
* Time  
* Source path  
* Destination path  
* Total size  
* File count  
* Transfer duration  
* Average speed  
* Verification mode  
* Verification result  
* Error count  
* Final status

---

# **10\. Transfer State Machine**

The application shall support the following states:

READY

COPYING

VERIFYING

SAFE\_TO\_FORMAT

COPY\_COMPLETE

ERROR

CANCELLED

Only one state may be active at a time.

---

# **11\. User Workflow**

Launch Application

↓

Select Source Folder

↓

Select Destination Folder

↓

Select Transfer Speed

↓

Select Verification Mode

↓

Validate Storage

↓

Start Transfer

↓

Copy Media

↓

Verify Media

↓

Display Result

↓

Export Report

↓

End

---

# **12\. Non-Functional Requirements**

## **Stability**

The application should complete multi-hour transfers without crashing.

Target:

0 crashes during an 8-hour continuous transfer session.

---

## **Performance**

UI operations shall remain responsive during transfer operations.

Target:

* UI CPU usage below 5%  
* Memory usage below 300 MB during normal operation

---

## **Compatibility**

Supported Operating Systems:

* macOS 13 Ventura  
* macOS 14 Sonoma  
* macOS 15 Sequoia

Supported Hardware:

* Apple Silicon M1  
* Apple Silicon M2  
* Apple Silicon M3  
* Apple Silicon M4

Intel support is optional.

---

# **13\. Success Criteria**

A first-time DIT should be able to:

1. Launch FST  
2. Select a source folder  
3. Select a destination folder  
4. Start a transfer

Within 30 seconds and without assistance.

If the workflow requires explanation, the user experience should be simplified.

---

# **14\. MVP Exit Criteria**

The MVP is considered complete when:

* Folder selection is functional  
* Drag and drop is functional  
* rsync transfers are stable  
* Bandwidth limiting functions correctly  
* Random verification functions correctly  
* Full verification functions correctly  
* Real-time logging functions correctly  
* TXT report export functions correctly  
* SAFE TO FORMAT workflow is fully implemented  
* The application successfully completes production-scale transfer testing without crashes

Only then may the project proceed to Version 2 planning.

