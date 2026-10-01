# Destination Capacity Final Writability Freshness Repair

TASK=DESTINATION_CAPACITY_FINAL_WRITABILITY_FRESHNESS_REPAIR
START_HEAD=7d0a9deafe46be1a451ee51225e59a0dc00dfc89
ROLE=IMPLEMENTER_NOT_REVIEWER
OWNER_POLICY=APFS_STRICT_R;EXFAT_UNKNOWN_WARN_PLUS_L
BRAIN_REVIEW_STATUS=PENDING
BRAIN_CLASSIFICATION=UNSET
ACCEPTED_STATE=UNSET

## Authority and initial observations

Root AGENTS L0 and CURRENT HOT read; only latest independent-review finding consumed:
`handoffs/20261001-171946_antigravity_destination-capacity-post-implement-independent.md`,
P3_ADVISORY ADVERSARIAL_WRITABILITY. Its proposed repair is evidence; owner prompt authorizes this bounded implementation.
Git fetch succeeded; main HEAD = origin/main = START_HEAD; porcelain empty.
GitHub all-state issue search for writability returned []; relevant registry/history search found no completed repair.
Direct reads: DriveService, StorageMetadata, TransferCoordinator, canonical metadata/preflight/capacity tests,
PRD destination validation and technical-guide DriveService ownership sections.
CodeGraph unavailable; source/callers/tests inspected directly. No policy/filesystem/privacy research performed.

## Defect and test-first reproduction

Before mutation to production, added `testFreshReadOnlyEvidenceRejectsOldWritableAdmission`.
Pre-scan metadata writable=true; final metadata writable=false; capacity APFS4096 and F=R=4096.
Old validator received only final free bytes and admitted the transfer.
Canonical red test: 0 passed / 1 failed / 0 skipped, exit65;
`XCTAssertThrowsError failed: did not throw an error`.
Exact xcresult, test commands and summaries are in verification.json.
One subsequent test compile attempt failed because the new fixture used nonexistent VerificationMode.sha256;
corrected test to existing .full; production verification semantics were never changed.

## Smallest core repair

Production changes only:
- `FishSockTransfer/FishSockTransfer/Services/DriveService.swift`
- `FishSockTransfer/FishSockTransfer/Coordinators/TransferCoordinator.swift`

`TransferPreflightValidator.validate` now requires complete immutable DestinationStorageMetadata
instead of optional destinationFreeSpaceBytes. Both authoritative callers pass evidence.destination,
which is the post-scan snapshot returned by preparePreflight/assessCapacity.
Final validator guards destinationMetadata.isWritable before capacity admission, throwing existing
TransferError.destinationUnavailable: "The destination location is unavailable or cannot be written."
It takes F from that same metadata, checks assessment binding/L/F and matching filesystem identity/unit,
then applies the unchanged capacity floor gate. No fallback fabricates writable=true.
Legacy logical-only test fixtures now supply explicit unknown-filesystem writable metadata;
missing/invalid free-space fixture uses negative capacity and preserves the existing error text.

DriveService's public default construction still uses FileManager.default.
An internal DEBUG-only FileManager initializer lets tests inject deterministic destination-writability
transitions while real metadata scans, capacity queries and filesystem profiles remain in use.
No production UI or ViewModel semantics/signatures changed.

## Fresh evidence and adversarial coverage

New regression test and three additional core tests cover:
- fresh read-only final evidence, including an old passing APFS assessment, cannot authorize admission;
- fresh writable=true wins despite an earlier writable=false metadata value;
- APFS+4096 still uses R; APFS unexpected8192/exFAT512/unknown/probe-absent remain warning+L;
- F==floor admits, F==floor-1 rejects with exactly the existing floor/available error;
- stale assessment filesystem identity, allocation unit or capacity mismatches reject.

Four new service/Coordinator tests use only UUID temporary directories:
- access probe sequence [true,true,false]: initial validateDestination, pre-scan profile snapshot,
  final post-scan snapshot. Authoritative DriveService.preflight rejects final read-only;
- the same transition through programmatic Coordinator produces states exactly [validating,error],
  destination-unavailable error, no copying/copyComplete/safeToFormat and no job folder/rsync-start log;
- destination removed after its initial snapshot cannot reuse initial writable metadata;
  existing missing-capacity/profile failure semantics remain fail-closed;
- missing destination and ordinary-file destination retain destinationUnavailable semantics.

Existing pre/post-scan mount/profile consistency guards remain byte-unchanged:
volumeIdentity, filesystemIdentity and allocationUnit must all match, else destinationCapacityChanged.
No physical remount/read-only flip is claimed; the transition is deterministically injected at the
existing filesystem access boundary. Fresh profile mismatches are tested separately in final validation.
Temporary source fixture bytes and directory contents remain unchanged after admission failure;
production scan remains metadata-only/source-read-only. TearDown removes only UUID fixtures.

## Preserved policy and boundaries

L = sum eligible regular-file logical fileSize, remains SourceStorageMetadata totalSizeBytes,
TransferPreflightPlan.transferableBytes and copy/observer truth.
Validated exact machine identity apfs + public unit4096: R=sum checked per-file roundUp(size,4096),
zero size=>0; floor R; otherwise floor L with allocation warning. F>=floor (equality passes).
No formula/arithmetic/profile probe/source model modification; no arbitrary headroom.
All other tracked production paths are unchanged, including StorageMetadata, ViewModel, UI wording/layout,
PrivacyInfo.xcprivacy, Telegram redaction, rsync args, VerifyEngine, progress/ETA/observer,
TransferState ownership, report safety, SAFE TO EJECT and OpenDesign.

## Verification and limitations

verification.json records exact canonical Debug/focused/full commands, result bundles and passed/failed/skipped counts,
red regression and compile failure. Exact production/tests patches are stored as UTF-8 JSON diff fields,
with decoded diff SHA256s; no normalized/omitted patch bytes.
Full canonical suite includes existing disposable APFS/exFAT image QA; its cleanup evidence is recorded separately.
No owner media access, formatting or mutations were needed for this repair.

This reduces stale admission. It cannot reserve filesystem writability after the final check,
prevent other writers/mount changes after admission, or guarantee transfer fit. Existing failure handling
and required verification continue to control SAFE TO EJECT. Physical device remount QA, UI QA,
release build and new policy/privacy research were not executed for this bounded repair.
Worker verification is evidence only; acceptance/classification remain BRAIN-owned.

WORKER_PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_FINAL_REPAIR_ADJUDICATION
