# **VERIFY\_ENGINE\_SPEC.md**

# **FST — Verification Engine Specification**

Version: 1.0

Status: Locked

Owner:

VerifyEngine

---

# **1\. Purpose**

VerifyEngine is responsible for validating that transferred data matches source data.

VerifyEngine does not perform data transfer.

VerifyEngine establishes trust.

The engine exists to answer one question:

"Can the source media be safely erased?"

---

# **2\. Core Philosophy**

Transfer completion does not equal data integrity.

Transfer success means:

Data was moved.

Verification success means:

Data can be trusted.

Only verification may contribute to:

SAFE\_TO\_FORMAT

---

# **3\. Design Goals**

Priority Order:

1. Accuracy  
2. Reliability  
3. Determinism  
4. Transparency  
5. Performance

Verification speed is important.

Verification accuracy is mandatory.

---

# **4\. Engine Responsibilities**

VerifyEngine owns:

* File discovery  
* Source file inventory  
* Destination file inventory  
* Sampling logic  
* Hash generation  
* Hash comparison  
* Verification reporting  
* Verification statistics

VerifyEngine does not:

* Execute rsync  
* Manage UI  
* Manage workflow state  
* Generate SAFE\_TO\_FORMAT

---

# **5\. Verification Workflow**

Transfer Complete

↓

File Discovery

↓

File Selection

↓

Hash Generation

↓

Hash Comparison

↓

Verification Result

↓

TransferCoordinator

---

# **6\. Verification Modes**

enum VerificationMode {

    case none

    case random33

    case full  
}

---

# **7\. Mode Definitions**

## **None**

Purpose:

Skip verification.

Result:

COPY\_COMPLETE

Not SAFE\_TO\_FORMAT

---

## **Random 33%**

Purpose:

Daily production workflow.

Balance between:

* Speed  
* Confidence

Behavior:

Randomly select approximately 33% of transferred files.

Verify selected files only.

---

## **Full**

Purpose:

Maximum confidence.

Behavior:

Verify every transferred file.

Recommended for:

* Final deliveries  
* Master backups  
* Archive creation

---

# **8\. Verification Request**

struct VerificationRequest {

    let sourceURL: URL

    let destinationURL: URL

    let mode: VerificationMode  
}

Immutable.

Created by TransferCoordinator.

---

# **9\. Verification Result**

struct VerificationResult {

    let totalFiles: Int

    let verifiedFiles: Int

    let passedFiles: Int

    let failedFiles: Int

    let duration: TimeInterval

    let status: VerificationStatus  
}

---

# **10\. Verification Status**

enum VerificationStatus {

    case passed

    case failed

    case cancelled  
}

---

# **11\. File Discovery**

Before verification begins:

VerifyEngine must build:

Source Inventory

Destination Inventory

Each inventory contains:

* Relative Path  
* File Size  
* Modification Date

Hash generation should not begin until inventories are complete.

---

# **12\. Inventory Validation**

Before hashing:

VerifyEngine must confirm:

* File count consistency  
* Relative path consistency  
* Basic size consistency

Failure immediately triggers:

.failed

Hashing is skipped.

Reason:

No need to hash obviously mismatched datasets.

---

# **13\. Relative Path Matching**

Matching is performed using:

relative path

Example:

A001/CLIP001.mov

must exist in both:

Source

and

Destination

Absolute paths are ignored.

---

# **14\. Sampling Strategy**

Random verification must use:

True random selection.

Not:

First 33%

Last 33%

Every third file

Forbidden.

---

# **15\. Sampling Rules**

Minimum:

1 file

Always verify at least one file.

Maximum:

all files

Never exceed inventory size.

---

# **16\. Sampling Weighting**

Files should be weighted by size.

Reason:

Large media files represent the majority of transferred data.

Preferred behavior:

A 100 GB camera roll should influence sampling more than a 2 KB metadata file.

---

# **17\. Hash Algorithm**

MVP Algorithm:

xxHash64

Reason:

* Extremely fast  
* Low CPU cost  
* Excellent collision resistance for verification workflows

---

# **18\. Hash Strategy**

For each selected file:

Generate:

Source Hash

Generate:

Destination Hash

Compare:

Hash A \== Hash B

---

# **19\. Hash Mismatch Rule**

Single mismatch equals failure.

Example:

Verified Files: 100

Passed: 99

Failed: 1

Result:

.failed

SAFE\_TO\_FORMAT prohibited.

---

# **20\. Missing File Rule**

If any expected file is missing:

Verification immediately fails.

No exceptions.

---

# **21\. Size Mismatch Rule**

If file sizes differ:

Verification immediately fails.

Hash generation may be skipped.

Reason:

Mismatch already proven.

---

# **22\. Verification Events**

VerifyEngine emits:

enum VerificationEvent {

    case started

    case progress(Double)

    case currentFile(String)

    case hashGenerated(String)

    case completed(VerificationResult)

    case cancelled

    case failed(Error)  
}

Coordinator consumes events.

---

# **23\. Progress Reporting**

Progress Formula:

verifiedFiles

÷

totalFiles

Output:

0% → 100%

Updates should be smooth and predictable.

---

# **24\. Current File Reporting**

Engine should emit:

.currentFile(...)

during hashing.

Purpose:

Operator visibility.

---

# **25\. Cancellation**

Cancellation is allowed.

User presses:

STOP

Expected Result:

.cancelled

Current hash operation completes.

Next hash operation never starts.

---

# **26\. Logging Requirements**

Required Events:

Verification Started

Inventory Built

Hash Generated

Verification Passed

Verification Failed

Verification Cancelled

VerifyEngine emits logs.

LoggerService stores logs.

---

# **27\. Error Categories**

enum VerificationError {

    case sourceMissing

    case destinationMissing

    case fileCountMismatch

    case fileSizeMismatch

    case hashMismatch

    case cancelled

    case unknown  
}

---

# **28\. Concurrency Model**

Hashing must run off MainActor.

Requirements:

Task.detached

or equivalent.

No UI work inside VerifyEngine.

---

# **29\. Parallel Hashing**

MVP:

Single-threaded verification.

Reason:

Predictable behavior.

Lower complexity.

Easier debugging.

Parallel verification is reserved for future versions.

---

# **30\. Memory Rules**

Never load entire files into memory.

Use:

streamed reading

or

chunked reading

Required for:

* Large camera media  
* Long-form documentary footage  
* Multi-terabyte transfers

---

# **31\. Chunk Strategy**

Recommended:

4 MB chunks

Default.

Future configurable.

---

# **32\. Safe To Format Contract**

VerifyEngine never emits:

SAFE\_TO\_FORMAT

VerifyEngine only emits:

PASSED

FAILED

TransferCoordinator decides:

SAFE\_TO\_FORMAT

based on workflow rules.

---

# **33\. Verification Lifecycle**

Created

↓

Inventory Scan

↓

File Selection

↓

Hash Generation

↓

Comparison

↓

Completed

Alternative exits:

Failed

Cancelled

---

# **34\. Performance Targets**

Random 33% Verify:

Target:

Less than 30% of original copy duration.

Full Verify:

Target:

Less than 100% of original copy duration.

Goals only.

Not guarantees.

---

# **35\. Testing Requirements**

Unit Tests:

* Sampling  
* Inventory Building  
* Hash Comparison  
* Error Mapping

Integration Tests:

* Random Verify  
* Full Verify  
* Missing File  
* Size Mismatch  
* Hash Mismatch  
* Cancellation

---

# **36\. Trust Model**

Verification confidence levels:

NONE

↓

PARTIAL

↓

FULL

Mapping:

None

↓

No Trust

Random 33%

↓

Partial Trust

Full

↓

Maximum Trust

---

# **37\. Future Compatibility**

Reserved Features:

* xxHash128  
* BLAKE3  
* SHA-256  
* Multi-threaded Verification  
* GPU Assisted Verification  
* Full Manifest Verification

Not part of MVP.

---

# **38\. Engineering Rule**

Verification logic must remain completely independent from rsync.

Rsync moves bytes.

VerifyEngine establishes trust.

Mixing responsibilities is forbidden.

---

# **39\. Final Principle**

The most dangerous message a media transfer application can display is:

"Everything is fine."

without evidence.

VerifyEngine exists to provide that evidence.

Only when evidence exists may TransferCoordinator authorize:

SAFE\_TO\_FORMAT.

