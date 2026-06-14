# **STATE\_MACHINE.md**

# **FST — Transfer State Machine Specification**

Version: 1.0

Status: Locked

Owner:

TransferCoordinator

---

# **1\. Purpose**

This document defines the complete transfer lifecycle of FST.

The state machine exists to guarantee:

* Predictable behavior  
* Safe workflow execution  
* Consistent UI updates  
* Reliable error handling

Every transfer operation must follow this state machine.

No exceptions.

---

# **2\. Core Principle**

At any given moment:

The application may exist in one and only one state.

Multiple active states are forbidden.

Example:

Valid:

COPYING

Invalid:

COPYING \+ VERIFYING

---

# **3\. State Overview**

READY

↓

VALIDATING

↓

COPYING

↓

VERIFYING

↓

SAFE\_TO\_FORMAT

Alternative exits:

ERROR

CANCELLED

COPY\_COMPLETE

---

# **4\. State Definitions**

## **READY**

Purpose:

Idle application state.

Requirements:

* No active process  
* No verification running  
* UI editable

Allowed Actions:

* Select Source  
* Select Destination  
* Change Bandwidth  
* Change Verification Mode  
* Start Transfer

---

## **VALIDATING**

Purpose:

Validate transfer requirements.

Checks:

* Source exists  
* Source readable  
* Source not empty  
* Destination exists  
* Destination writable  
* Sufficient free space

UI:

Locked

Allowed Actions:

None

Duration:

Typically less than 2 seconds

---

## **COPYING**

Purpose:

Execute rsync transfer.

Active Components:

* TransferCoordinator  
* RsyncEngine  
* LoggerService

UI:

Partially Locked

Allowed Actions:

* Cancel

Forbidden Actions:

* Change Source  
* Change Destination  
* Change Verify Mode  
* Change Bandwidth

---

## **VERIFYING**

Purpose:

Validate transferred media.

Active Components:

* TransferCoordinator  
* VerifyEngine  
* LoggerService

UI:

Locked

Allowed Actions:

* Cancel

---

## **COPY\_COMPLETE**

Purpose:

Copy completed successfully.

Verification skipped.

Requirements:

Verification Mode \= None

Important:

This state is NOT SAFE TO FORMAT.

---

## **SAFE\_TO\_FORMAT**

Purpose:

Highest confidence state.

Requirements:

Copy Success

AND

Verification Success

This state is the final success state.

---

## **ERROR**

Purpose:

Terminal failure state.

Requirements:

Transfer failed

OR

Verification failed

OR

Validation failed

---

## **CANCELLED**

Purpose:

Operator terminated workflow.

Requirements:

User initiated cancellation.

---

# **5\. State Diagram**

READY  
  │  
  ▼  
VALIDATING  
  │  
  ├─────────────► ERROR  
  │  
  ▼  
COPYING  
  │  
  ├─────────────► ERROR  
  │  
  ├─────────────► CANCELLED  
  │  
  ▼  
VERIFYING  
  │  
  ├─────────────► ERROR  
  │  
  ├─────────────► CANCELLED  
  │  
  ▼  
SAFE\_TO\_FORMAT

Verification disabled:

COPYING  
  │  
  ▼  
COPY\_COMPLETE

---

# **6\. TransferState Definition**

enum TransferState {

    case ready

    case validating

    case copying

    case verifying

    case copyComplete

    case safeToFormat

    case error(Error)

    case cancelled  
}

---

# **7\. State Ownership**

Only:

TransferCoordinator

may mutate:

TransferState

No other component may change application state.

Forbidden:

ViewModel

RsyncEngine

VerifyEngine

View

changing state directly.

---

# **8\. Start Transfer Flow**

Current State:

READY

User presses:

START

Flow:

READY

↓

VALIDATING

↓

COPYING

---

# **9\. Validation Failure Flow**

Current State:

VALIDATING

Failure:

Destination Full

Transition:

VALIDATING

↓

ERROR

Example Message:

Not enough free space available.

---

# **10\. Copy Success Flow**

Current State:

COPYING

Verification Enabled:

COPYING

↓

VERIFYING

Verification Disabled:

COPYING

↓

COPY\_COMPLETE

---

# **11\. Verify Success Flow**

Current State:

VERIFYING

Transition:

VERIFYING

↓

SAFE\_TO\_FORMAT

Requirements:

All sampled hashes match.

---

# **12\. Verify Failure Flow**

Current State:

VERIFYING

Transition:

VERIFYING

↓

ERROR

Example:

Hash mismatch detected.

SAFE TO FORMAT must never appear.

---

# **13\. Cancellation Flow**

Cancellation is allowed during:

* COPYING  
* VERIFYING

User presses:

STOP

Transition:

COPYING

↓

CANCELLED

or

VERIFYING

↓

CANCELLED

---

# **14\. Drive Disconnect Flow**

Example:

Destination SSD disconnected.

Transition:

COPYING

↓

ERROR

Error Category:

.driveDisconnected

---

# **15\. Source Disconnect Flow**

Example:

Source card removed.

Transition:

COPYING

↓

ERROR

Error Category:

.sourceUnavailable

---

# **16\. State Entry Actions**

Each state performs entry actions.

Example:

COPYING

Entry:

logger.info("Transfer Started")

VERIFYING

Entry:

logger.info("Verification Started")

SAFE\_TO\_FORMAT

Entry:

logger.info("Verification Passed")

---

# **17\. State Exit Actions**

COPYING Exit:

stopProgressTimer()

VERIFYING Exit:

flushVerificationCache()

ERROR Exit:

No action.

Terminal state.

---

# **18\. UI Lock Matrix**

| Action | Ready | Validating | Copying | Verifying |
| ----- | ----- | ----- | ----- | ----- |
| Select Source | Yes | No | No | No |
| Select Destination | Yes | No | No | No |
| Change Speed | Yes | No | No | No |
| Change Verify Mode | Yes | No | No | No |
| Start Transfer | Yes | No | No | No |
| Stop Transfer | No | No | Yes | Yes |

---

# **19\. Error Categories**

enum TransferError {

    case sourceNotFound

    case sourceUnreadable

    case destinationNotFound

    case destinationNotWritable

    case insufficientSpace

    case rsyncFailed

    case verificationFailed

    case sourceDisconnected

    case destinationDisconnected

    case cancelled  
}

---

# **20\. Terminal States**

Terminal States:

COPY\_COMPLETE

SAFE\_TO\_FORMAT

ERROR

CANCELLED

No automatic transitions occur after entering a terminal state.

User must explicitly start a new transfer.

---

# **21\. Recovery Rules**

After terminal state:

COPY\_COMPLETE

SAFE\_TO\_FORMAT

ERROR

CANCELLED

Allowed Transition:

READY

Triggered by:

NEW TRANSFER

button.

---

# **22\. Safe To Format Rule**

This is the most important rule in the application.

SAFE\_TO\_FORMAT may only occur when:

Copy Success \= TRUE

AND

Verify Success \= TRUE

There are no exceptions.

No warnings.

No overrides.

No operator bypass.

---

# **23\. Engineering Rule**

If a future feature requires modifying this state machine:

The state diagram must be updated before code is written.

State Machine is the source of truth.

Code must follow the State Machine.

Never the opposite.

