# FST Agent Handoff

## HOT
HMD_SCHEMA=HANDOFF_MARKDOWN
HMD_VERSION=1
WORKSTREAM_ID=HEADROOM_B_INDEPENDENT_REVIEW_V2
HANDOFF_ID=PUBLISHER_ASSIGNED
HANDOFF_TYPE=NORMAL
REPO=cenvu/FST_V2
BRANCH=main
REPO_HEAD=33513df59314e6ef2761471529420c867a824623
REMOTE_HEAD=33513df59314e6ef2761471529420c867a824623
HANDOFF_AT_HEAD=YES
LAST_VERIFIED_AT=UNKNOWN
AUTH=REPO_GITHUB_CANONICAL
STATE=WORKER_REPORT_COMPLETE
GATE=WORKER_RETURN_READY
BLOCKER=NONE
NEXT_DECISION=ACTION(RETURN_TO_BRAIN_FOR_POLICY_ADJUDICATION)

## COMPACT_REFS
REF=AGENTS.md
REF=handoffs/20261001-144422_codex-local-worker_destination-capacity-fs-calibration.md
REF=handoffs/evidence/fs-calibration/POLICY_SPEC_CANDIDATE.md
REF=handoffs/evidence/fs-calibration/PRIMARY_RESEARCH.md
REF=handoffs/evidence/fs-calibration/MATRIX.md
REF=handoffs/evidence/fs-calibration/summary.json
REF=handoffs/evidence/fs-calibration/matrix.csv
REF=handoffs/evidence/fs-calibration/archive-manifest.json
REF=handoffs/evidence/fs-calibration/cleanup-verification.json
REF=FishSockTransfer/FishSockTransfer/Services/DriveService.swift
REF=FishSockTransfer/FishSockTransfer/Models/StorageMetadata.swift
REF=FishSockTransfer/FishSockTransfer/Models/TransferFileExclusionPolicy.swift
REF=FishSockTransfer/FishSockTransfer/Engines/RsyncEngine.swift

## CURRENT_STATE
TASK=DESTINATION_CAPACITY_POLICY_INDEPENDENT_REVIEW_V2 (Destination Capacity Policy Independent Review V2)
PHASE=HIGH_RISK_SAFETY_INDEPENDENT_REVIEW
WORKER_STATUS=REVIEW_COMPLETE
PRODUCTION_BYTES=UNCHANGED
DEAD_ENDS=NONE
NOT_EXECUTED=PRODUCTION_MUTATION;SWIFT_MUTATION;UI_WORK;NEW_EXPERIMENTS

## REVIEW
BRAIN_REVIEW_STATUS=PENDING
BRAIN_CLASSIFICATION=UNSET
ACCEPTED_STATE=UNSET

## RAW_REFS
RAW_REF=NONE

## REPORT

### Scope, authority and preflight

CLASS=HIGH_RISK_SAFETY_INDEPENDENT_REVIEW;CTX=L;PRODUCT_WORKSTREAM=HEADROOM_B
ROLE=REVIEWER_NOT_IMPLEMENTER
START_HEAD=33513df59314e6ef2761471529420c867a824623
PREFLIGHT=fetch_exit0;main_clean;HEAD_EQUALS_ORIGIN_MAIN_EQUALS_START_HEAD;WORKTREE_CLEAN
PRODUCT_MUTATION=FORBIDDEN;VERIFIED_NONE
SWIFT_MUTATION=FORBIDDEN;VERIFIED_NONE
INDEPENDENCE_LIMITATION=same_model_harness_identity_as_prior_noncanonical_review_attempt;different_conversation_and_full_re_derivation_from_canonical_sources;prior_noncanonical_summary_not_used_as_premise;all_findings_derived_from_repo_primary_sources_raw_evidence_only

SOURCE_INSPECTED=DriveService.swift(329_lines);StorageMetadata.swift(33_lines);TransferPreflightValidator(DriveService_L240-L328);RsyncCommand(RsyncEngine_L756-L803);TransferFileExclusionPolicy.swift(44_lines);DestinationActivitySnapshotter(RsyncEngine_L434-L560)
CALIBRATION_INSPECTED=calibration_handoff(197_lines);POLICY_SPEC_CANDIDATE(77_lines);PRIMARY_RESEARCH(63_lines);MATRIX(204_lines);summary_json(1292_lines);archive_manifest_json(48_lines);cleanup_verification_json(18_lines)
HASH_VERIFICATION=summary_json_SHA256_MATCH;matrix_csv_SHA256_MATCH;archive_manifest_json_SHA256_MATCH;cleanup_verification_json_SHA256_MATCH;all_5_compressed_archives_SHA256_MATCH
PRIVACY_MANIFEST=git_ls_files_xcprivacy_Privacy_EMPTY;no_PrivacyInfo_xcprivacy_in_repo

### Q1: Logical floor

FINDING=CONFIRMED
DERIVATION: Current production `DriveService.scanFolder` (L114-L156) sums `values.fileSize` for regular files passing `TransferFileExclusionPolicy.shouldExclude`. The `.fileSizeKey` resource value is Foundation's `NSURLFileSizeKey`, documented as the file's logical size in bytes (not allocated size). The preflight validator (`TransferPreflightValidator.validate`, L240-L291) gates on `availableBytes >= sourceMetadata.totalSizeBytes`. Therefore `L = sum(eligible regular file logical fileSize)` is the current hard admission floor.

L IS A NECESSARY FLOOR: Any rsync copy of regular file content without `--sparse` writes at least the logical bytes. The current rsync arguments (`-a -h --info=name1,progress2 --outbuf=N` plus six exclusions, source without trailing slash, destination with trailing slash) do not include `--sparse`. Therefore the receiver writes full logical content for each regular file. Destination allocation >= L is a necessary condition for all files to be written.

L IS NOT A SUFFICIENT FLOOR: Filesystem allocation granularity means actual disk consumption exceeds L whenever any file is not perfectly aligned to the allocation unit. The calibration matrix confirms this with counterexamples: APFS many_small_1byte L=1024, R=4194304 (4096x factor); exFAT many_small_1byte L=1024, R_cluster=33554432 (32768x factor).

PROGRESS DENOMINATOR: L is correctly used as the copy progress denominator by `DestinationActivitySnapshotter` (L447, L552-L554: `clampCopiedBytes` caps at `totalBytes` which is L). Observer bytes equal L for all 83 successful jobs. This is appropriate because rsync writes logical content, and the observer sums regular-file logical sizes at destination. L as denominator is independent of allocation estimate.

### Q2: APFS R

FINDING=CONFIRMED_AS_NECESSARY_FLOOR_ONLY

DERIVATION: `R = sum(4096 * ceil(s_i / 4096))` for each eligible regular file, with R(0-byte file)=0. The allocation unit C=4096 is validated for APFS by:
- `statvfs.f_frsize = 4096` on the tested APFS image (summary.json records confirm)
- Apple File System Reference documents container block sizes starting from 4096
- All 5 APFS repeatability runs for each of 4 workloads show `destination_regular_allocated == R` exactly (summary.json `apfs_repeatability` section: many_small_1byte R=4194304 5/5 match, many_small_mixed R=5242880 5/5 match, sparse_single R=134217728 5/5 match, sparse_many R=100757504 5/5 match)

RUNTIME PROVENANCE: `statvfs.f_frsize` is documented in Darwin `statvfs(3)` as the "minimum allocation unit". On APFS images, this correctly reports 4096. The value is available via Foundation `volumeMinimumBlockSizeKey` or direct `statvfs` call. This is a public, stable API. `statfs.f_bsize` also equals 4096 on APFS (Darwin naming: `statfs.f_bsize` = fundamental block = `statvfs.f_frsize`; `statfs.f_iosize` = preferred I/O = `statvfs.f_bsize`). For APFS, either reports the correct allocation unit.

NEAR-ENOSPC EVIDENCE: Boundary phase APFS jobs all fail at exactly R free space (exit codes 10/11 at boundary_small R=50331648, boundary_nested R=33554432, boundary_large R=33554432). Critically:
- boundary_small at F=R: dest_regular=37724160 (partial), exit 11 — rsync ENOSPC during write
- boundary_large at F=R: dest_regular=0, exit 11 — cannot write even one file at exactly R
- Adaptive bisect confirms: boundary_small fails at 63029248, succeeds at 63733760; boundary_nested fails at 45088768, succeeds at 45809664; boundary_large fails at 44122112, succeeds at 44826624

THESE FAILURES AT R PROVE R IS NOT SUFFICIENT. The APFS allocator requires additional space beyond R for metadata (B-trees, checkpoints, COW objects). The residual (free_delta minus R) is variable: snapshot_composite_residuals are 40960 for many_small_1byte, 36864 for many_small_mixed, 0 for sparse_single and sparse_many in ample conditions; adaptive brackets show approximately 11-13 MiB needed beyond R for near-ENOSPC small-file jobs.

PRIOR COUNTEREXAMPLE PRESERVED: The earlier shared-APFS-volume sparse test showed final allocation exceeding R by 262,144 to 14,155,776 bytes. This is not erased by the isolated-image matrix.

CLASSIFICATION: R is a NECESSARY_FLOOR. It is NOT a sufficient floor. A transfer can fail even when F >= R, due to metadata/allocator overhead. R cannot be upgraded to SUFFICIENT from image evidence.

### Q3: exFAT

FINDING=NOT_READY_FOR_HARD_ROUNDED_FLOOR

DERIVATION: The correct exFAT allocation unit for the tested images is C=32768, proven from boot sector inspection (`BytesPerSectorShift=9, SectorsPerClusterShift=6, C = 2^(9+6) = 32768`). Using this correct C, `R_cluster = sum(32768 * ceil(s_i/32768))` correctly predicts per-file destination allocation in all ample matrix rows (e.g., many_small_1byte: R_cluster=33554432, dest_regular=33554432; mixed_workload: R_cluster=39976960, dest_regular=39976960).

THE PUBLIC API MISMATCH IS CONFIRMED AND UNRESOLVED:
- `statvfs.f_frsize = 512` on exFAT (all summary.json exFAT jobs confirm)
- `statfs.f_bsize = 512` on exFAT
- `getattrlist ATTR_VOL_MINALLOCATION = 512` (calibration PRIMARY_RESEARCH)
- `diskutil info VolumeAllocationBlockSize = 512`
- `pathconf _PC_ALLOC_SIZE_MIN = 1`
- Actual per-file allocation for a 1-byte file: 32768 bytes

Every public API queried reports 512 (the sector size), not 32768 (the cluster size). The calibration worker correctly identified this as a preserved contradiction. A 1-byte file allocating 32768 bytes while the API reports minimum allocation of 512 bytes means the API reports the physical sector size, not the filesystem cluster size.

PRODUCTION-SAFE ACQUISITION: No demonstrated public API returns the correct cluster size for exFAT on macOS. Boot sector inspection (reading raw device bytes) is an experiment technique, not a production API. Requiring raw device reads, privilege escalation, empirical write probes, or private API for cluster discovery is not production-safe without separate owner authorization.

IF C CANNOT BE PROVEN AT RUNTIME: Then `R_cluster` cannot be computed at runtime. Using `R_vfs` (based on f_frsize=512) materially undercounts: exFAT many_small_1byte R_vfs=524288 vs actual allocation 33554432 (64x undercount). Therefore an exFAT hard rounded floor using R_cluster is NOT_READY for implementation until runtime cluster provenance is solved.

RESIDUAL PHASE CONFIRMS: exFAT boundary_small with correct C=32768 requires F=269418496 for success (residual phase: fails at 269385728, succeeds at 269418496). This includes R_cluster=134217728 for data files plus 134217728 for generated AppleDouble sidecars (4096 files * 32768 per sidecar) plus 950272 directory allocation plus 32768 parent residual. Total free_delta = 269418496 = 2*R_cluster + directory + residual.

### Q4: Metadata

FINDING=PARTIAL;LOWER_FLOORS_DERIVABLE;UPPER_BUDGET_UNPROVEN

REGULAR FILE ALLOCATION: On both APFS (C=4096) and exFAT (C=32768), per-file allocation equals C*ceil(s_i/C) for regular files in all tested ample rows. This is a necessary floor for regular-file data, confirmed.

DIRECTORY STREAM ALLOCATION: exFAT directory entries are 32-byte entry sets per Microsoft specification. Calibration confirms directory_allocated values are consistent. For exFAT boundary_nested (D=512, N=128): directory_allocated=16809984 in ample residual measurement (summary.json). The calibration spec derives `m_dir(C,T) = sum_over_new_dirs C*max(1,ceil(sum(e(child_name))/C))` as a final-state lower floor. The simpler `C*(D+1)` is a weaker necessary lower floor. NEITHER is an upper budget because temp-name coexistence, fragmentation, and driver behavior are not bounded.

APFS DIRECTORY ALLOCATION: APFS B-tree directory structures have no public cost formula. The calibration measured snapshot_composite_residuals (free_delta minus dest_regular_allocated) of 40960 for many_small_1byte (1024 files), 36864 for many_small_mixed (1024 files), 0 for sparse workloads. These are observational only. No APFS metadata budget is derivable from them.

APPLEDOUBLE SIDECARS: The rsync receiver creates `._*` AppleDouble files on exFAT containing `com.apple.provenance` (4096 bytes each, allocating 32768 per sidecar at C=32768). These are NOT source xattrs being copied — the rsync flags do not include `-X/--xattrs`. They are receiver/OS-generated. Calibration confirms: exFAT boundary_small N=4096 files generates destination_all_file_allocated=268435456 = 2*134217728 = 2*R_cluster, meaning one sidecar per data file. This is material: sidecars double the regular-file allocation for small files on exFAT.

SIDECAR ORIGIN: Unresolved. Matching source/destination provenance hashes do not prove xattr preservation vs. common automatic provenance stamping. The `-a` flag does NOT include `-X` on rsync 3.4.4 (confirmed by source inspection of RsyncCommand, L776). Source exclusions filter `._*` from source but do not prevent the receiver/OS from creating new ones at destination.

ALLOCATOR RESIDUAL: The residual phase shows one-cluster (32768 byte) difference between total file+directory allocation and the full free_delta in settled exFAT rows. This is likely root job metadata but is not a proven unique peak cost.

CLASSIFICATION: Regular-file allocation floors are necessary and derivable. Directory floors are necessary lower bounds. AppleDouble sidecar count and size are workload/environment dependent and unbounded. Allocator/metadata residual is an observation, not a provable upper budget.

### Q5: rsync

FINDING=CONFIRMED

EXACT CURRENT ARGUMENTS (RsyncEngine.swift L776-L800):
```
-a -h --info=name1,progress2 --outbuf=N
--exclude=.DS_Store --exclude=._* --exclude=.Spotlight-V100 --exclude=.Trashes --exclude=.fseventsd --exclude=.TemporaryItems
SOURCE_PATH
DESTINATION_PATH/
```

`-a` SEMANTICS ON BUNDLED RSYNC 3.4.4: Archive mode (`-rlptgoD`): recursive, links (symlinks as symlinks), permissions, times, group, owner, devices+specials. It does NOT include `-X` (xattrs), `-A` (ACLs), `-H` (hard links), or `--sparse`. This is consistent with the rsync 3.4.4 manual and source code.

OBSERVED `._*` APPLEDOUBLE WITHOUT `-X`: The exclusion pattern `--exclude=._*` prevents copying source `._*` files. However, the macOS exFAT receiver creates new `._*` files at the destination containing `com.apple.provenance`. This is not rsync xattr preservation — it is OS/filesystem behavior on the receiver side. The calibration correctly identifies this distinction (PROVENANCE_ORIGIN=UNRESOLVED).

TEMPORARY RECEIVER STRATEGY: rsync 3.4.4 receiver.c creates a temporary file in the same directory as the target file with a `.` prefix and random suffix (up to 8 chars longer than the base name). It writes content, applies attributes, then renames atomically. Same-volume rename transfers the existing allocation without additional copy. This means NO 2x payload peak for data files. Calibration confirms: exFAT boundary_large one 32MiB file succeeds at F=33652736 < 2*L=67108864. Temp-name and final-name coexist only briefly during rename.

EVIDENCE FOR NO >1x PEAK: The residual phase exFAT boundary_large results confirm no temporary doubling: F=33652736 succeeds for L=R=33554432. The difference (98304) is directory + metadata, not a second copy of data. All 1566 sampled temp-inode-to-final-file matches (from the calibration CSV) corroborate same-allocation rename. However, directory entries for temp and final names may briefly coexist, so directory allocation can spike transiently. This is a directory-entry effect, not a data-payload effect.

### Q6: Capacity claim

FINDING=NO_CANDIDATE_CAN_PROVE_WILL_FIT

NO FORMULA PROVEN SUFFICIENT:
- P0 (`F>=L`): Admits jobs where allocation exceeds L. False admits: 92 jobs in the matrix where P0 would pass capacity check but transfer actually failed.
- P1 (`F>=R(C)`): Still admits jobs where metadata/sidecar/allocator cost exceeds R. False admits: 65 jobs.
- P2 (`F>=R+M`): Still admits because no complete M budget is proven. False admits: 44 jobs.
- P3 (`F>=H_fs`): Strongest available floor with explicit residual warning. Still no sufficiency proof.

ALLOWED OPERATOR SEMANTICS: A capacity check can claim "the destination snapshot currently shows at least [floor] bytes available, which is a necessary but not sufficient condition for this transfer." It CANNOT claim "the transfer will fit" or "the destination has enough space." The distinction between CAPACITY_SNAPSHOT and RESERVATION must be maintained. The capacity snapshot is a point observation that can be invalidated by other writers, snapshots, purge timing, or source changes.

SAFE_TO_EJECT IS UNRELATED: The capacity admission gate is a preflight check. SAFE TO EJECT requires complete successful copy AND required verification. A capacity check that passes does not contribute to SAFE TO EJECT. A capacity check that fails prevents the transfer from starting but does not affect SAFE TO EJECT for a transfer that never ran.

### Q7: Unknown FS

FINDING=OWNER_DECISION_REQUIRED

OPTIONS REVIEWED:
1. WARN_PLUS_L: Accept the transfer on unknown/unvalidated filesystems with only L as the floor, plus an explicit warning that no allocation estimate is available. Product consequence: same behavior as current P0; no new false rejection; operator sees a warning they cannot act on except to choose a different destination. Safety consequence: no worse than current behavior; the warning is truthful.
2. BLOCK: Reject transfers to unvalidated filesystems entirely. Product consequence: restricts FST to APFS-only (and potentially exFAT once cluster provenance is solved). This is a significant product support scope change. Safety consequence: prevents transfers to filesystems where allocation behavior is unknown, eliminating false-admit risk for those filesystems.
3. OTHER EVIDENCE-BACKED: No other evidence-backed option emerged from the calibration. A percentage-based headroom on unknown filesystems has no evidence basis and would be an arbitrary safety decision.

EVIDENCE CANNOT SELECT: The choice between WARN+L and BLOCK is a genuine product support scope decision, not a technical determination. Current production accepts any writable destination folder with existing path/nonempty/capacity checks, with no filesystem allowlist. Changing to a filesystem allowlist is a product decision. OWNER_DECISION.

### Q8: Privacy

FINDING=CONFIRMED_ABSENT;APPLICABILITY_UNRESOLVED

`git ls-files '*xcprivacy*' '*Privacy*'` returns empty. No PrivacyInfo.xcprivacy exists in the checked-in repository.

CURRENT CODE USES: `volumeAvailableCapacityForImportantUsageKey` and `volumeAvailableCapacityKey` (DriveService L48), which are Foundation wrappers around statfs/statvfs volume capacity APIs. These fall under Apple's disk-space required-reason API category.

PROPOSED ADDITIONAL APIS: Any capacity policy implementation would use the same Foundation capacity APIs already in use, plus potentially `statvfs.f_frsize` or equivalent for allocation unit discovery. These are in the same required-reason category.

APPLE PLATFORM SCOPE: Apple's required-reason API documentation names iOS/iPadOS/tvOS/visionOS/watchOS in its platform text, while the property-list key page includes macOS availability. The calibration research (PRIMARY_RESEARCH.md) correctly notes this is a repository fact, not a claim about current App Store Connect enforcement for native macOS distribution.

DISTRIBUTION APPLICABILITY: Whether the current native macOS distribution requires a PrivacyInfo.xcprivacy declaration is unresolved. No manifest change was made or authorized.

NO MANIFEST CHANGE: Confirmed. This is a pre-implementation observation, not a production blocker if the privacy declaration is addressed when packaging for distribution.

### Q9: FS identity

FINDING=IMPLEMENTATION_BLOCKER_FOR_APFS_BRANCH

CURRENT CODE: `DriveService.getFilesystemType` (L86-L89) uses `URLResourceKey.volumeLocalizedFormatDescriptionKey` and returns `values.volumeLocalizedFormatDescription ?? "Unknown"`. This returns localized strings like "APFS" or "ExFAT" or locale-dependent equivalents.

PROBLEM: Localized format descriptions are locale-dependent. On a Japanese macOS system, the description might differ from English. Using a localized string as a machine filesystem identity for branching policy decisions (APFS vs exFAT vs unknown) is unreliable.

SOLUTION: Darwin `statfs.f_fstypename` is a fixed-length ASCII identifier ("apfs", "exfat", "hfs", etc.) that is locale-independent and stable. This is a public API available via the `statfs(2)` syscall. Foundation does not expose it directly through URLResourceKey, but it is accessible via `Darwin.statfs()` in Swift.

CURRENT CODE DOES NOT USE `f_fstypename`: Confirmed by grep — no occurrence in the codebase.

CLASSIFICATION: This is an IMPLEMENTATION_BLOCKER for any filesystem-branching capacity policy. The localized format description cannot be used as a reliable branch selector. The implementation must use `statfs.f_fstypename` or equivalent stable machine identifier. This is a deterministic technical finding, not an owner decision.

### Q10: Scan integration

FINDING=FEASIBLE_WITHOUT_SECOND_SCAN

EXISTING SCAN: `DriveService.scanFolder` (L114-L156) already enumerates all entries with `.fileSizeKey`, `.isDirectoryKey`, `.isRegularFileKey`. It applies exclusions, counts files and folders, and sums logical sizes. This runs off the main thread (DriveService is an actor).

ACCUMULATION WITHOUT SECOND SCAN: Per-file rounded totals can be accumulated during the existing scan:
```
// Pseudocode addition to scanFolder:
var roundedTotal: Int64 = 0
let C: Int64 = validated_allocation_unit  // from destination
// For each regular file passing exclusions:
let logicalSize = Int64(values.fileSize ?? 0)
if logicalSize > 0 {
    let rounded = ((logicalSize + C - 1) / C) * C  // ceil(s/C)*C
    // Check overflow before adding:
    guard rounded >= logicalSize, roundedTotal <= Int64.max - rounded else { overflow }
    roundedTotal += rounded
}
```

WITHOUT STORING ALL FILE SIZES: Yes, a running sum suffices. No need to store individual sizes.

WITHOUT SECOND SCAN: Yes, the accumulation happens in the existing single enumeration pass.

WITHOUT CONTENT READS: Yes, only `.fileSizeKey` metadata is needed, already requested.

WITHOUT SOURCE WRITES: Yes, the scan is read-only.

WITHOUT MAIN-THREAD WORK: Yes, DriveService is an actor; scanFolder already runs off the main thread.

PROGRESS DENOMINATOR UNCHANGED: L remains the progress denominator. R is the capacity admission floor. These are separate quantities.

CHECKED OVERFLOW: Int64 overflow at C=32768: maximum safe N before overflow of the rounded sum is well within practical limits (Int64.max / 32768 ≈ 281 trillion files). Per-file `ceil(s/C)*C` overflow: for C=32768, overflow only if s > Int64.max - 32767, which is not a practical file size. Checked arithmetic should still be used.

CANCELLATION: `Task.checkCancellation()` already exists in the scan loop (L130).

DESTINATION-CHANGE INVALIDATION: If the destination changes after scan, C may be different. The rounded total is destination-specific. The current architecture computes source metadata independently of destination, then validates in the preflight. A destination-aware rounded sum would need to be recomputed if the destination changes. This is a design consideration, not a blocker.

RECOMMENDED INTEGRATION SHAPE: Add optional `destinationAllocationUnit: Int64?` parameter to `scanFolder`. When non-nil and > 0, accumulate a per-file rounded sum alongside the existing logical sum. Return both. The preflight validator uses the rounded sum when available and the allocation unit is trusted. This requires passing the destination's validated C through to the source scan, which means the source scan becomes destination-aware. Alternative: compute the rounded sum in a lightweight post-scan pass over the already-collected metadata. But since individual sizes are not stored, a post-scan pass would require a second enumeration. Therefore, in-scan accumulation is the recommended shape.

### Adversarial analysis

0-BYTE FILES: R(0-byte)=0 by definition. Rsync creates directory entries but no data allocation for zero-length regular files. The current preflight rejects zero-logical-size sources (TransferPreflightValidator L268: `sourceMetadata.totalSizeBytes > 0`). No capacity false-admit from zero-byte files.

MANY TINY FILES (1024x 1-byte): APFS R=4194304 (4096x L); exFAT R_cluster=33554432 (32768x L). P0 admits these but they fail at F=L. P1/P3 with correct C rejects unless F>=R. Counterexample to P0 confirmed.

LARGE UNALIGNED (16777339 bytes = 16MiB + 123): APFS R=16781312 (L+4073 padding); exFAT R_cluster=16809984 (L+32645 padding). Both allocations confirmed in ample matrix rows.

NESTED DIRECTORIES (1408 directories, 256 files): APFS dest_regular=1048576 with free_delta=1060864 (residual 12288 for directory metadata). exFAT dest_regular=8388608 with free_delta=109182976 (huge residual from directory+sidecar allocation). Directory-heavy workloads amplify the gap between R and actual cost on exFAT.

SPARSE FILES: Rsync without --sparse writes full logical content. APFS sparse_single L=R=134217728, dest_regular=134217728 in all 5 runs. Sparse source allocation is irrelevant; receiver writes logical bytes.

COMPRESSED SOURCE: L=8388608 (8MiB logical); source reported alloc=98304 (compressed). Destination data=8388608 on both APFS and exFAT. Source compression provides no credit; rsync writes logical content. Confirmed.

EXCLUDED ENTRIES: Source `._*` and metadata excluded from L and from rsync transfer. But receiver generates new `._*` sidecars on exFAT. Excluded entries at source do not prevent receiver-generated files. This is addressed in Q4 (sidecar allocation).

SOURCE CHANGES AFTER SCAN: Not bounded by any capacity formula. Capacity is a snapshot; source growth between scan and copy can cause ENOSPC regardless of admission policy. This is truthful operator feedback.

DESTINATION CHANGES: Other writers to the destination, snapshot creation, purge timing all invalidate the capacity snapshot. No reservation mechanism exists.

SHARED APFS VOLUME: The calibration used isolated single-volume containers. Shared APFS containers (common on production Macs) have container-level free space shared among volumes. Other volumes can consume space between capacity check and copy completion. Prior counterexample (shared-volume sparse over-R by up to 14 MiB) demonstrates this risk.

OTHER WRITERS: Not bounded. Capacity snapshot is not a reservation.

PURGE TIMING: Important-usage capacity includes expected reclaimable space. If purge doesn't happen before copy needs the space, ENOSPC can occur even with F >= R + metadata.

QUOTA/NETWORK/UNKNOWN FS: Not tested. Network filesystems may have different allocation behavior, latency, and failure modes. Unknown FS allocation is unbounded.

GENERATED SIDECARS: On exFAT, each source regular file generates one 4096-byte `._*` sidecar allocating 32768 bytes. For N=4096 files: N*32768 = 134217728 bytes of sidecar allocation, equal to R_cluster. This is a 2x multiplier on regular-file allocation. On APFS, no sidecars were observed in the calibration (no `._*` files created at APFS destination). Whether this holds for all APFS configurations is not proven.

OVERFLOW: Int64 overflow for R: at C=4096, overflow requires sum of individual rounded sizes > 2^63 - 1 ≈ 9.2 * 10^18 bytes. This is ~8 EiB. Not a practical concern but checked arithmetic is still required. For C=32768, the threshold is the same (Int64.max). Per-file rounding overflow: ceil(s/C)*C overflows only for s near Int64.max; checked arithmetic catches this.

### Raw audit (≥22 rows independently spot-checked)

APFS AMPLE (4 rows verified):

Row 1: matrix/apfs/many_small_1byte/1/ample: L=1024, N=1024, R_vfs=R_C=4194304. Check: 1024 files * ceil(1/4096)*4096 = 1024*4096 = 4194304. ✓ dest_regular=4194304. ✓ Free before/after: 535085056/530849792, delta=4235264, composite_residual=40960. ✓ Exit 0, Hash True, Observer 1024=L. ✓

Row 2: matrix/apfs/many_small_mixed/1/ample: L=3735424, N=1024. R=5242880. Manual check requires per-file sizes not in matrix; but calibration reports R_vfs=R_C=5242880 and dest_regular=5242880, exit 0, hash true. Free delta=535085056-529805312=5279744, residual=5279744-5242880=36864. ✓

Row 3: matrix/apfs/sparse_single/1/ample: L=134217728, N=1, R=134217728. ceil(134217728/4096)*4096=134217728 (aligned). ✓ dest_regular=134217728. ✓ Free delta=535085056-400867328=134217728, residual=0. ✓

Row 4: matrix/apfs/cinema_like_many_frames/1/ample: L=67118063, N=1024, R=71081984. dest_regular=71081984. ✓ Free delta=535085056-463962112=71122944, residual=71122944-71081984=40960. ✓ Exit 0, Hash True, Observer 67118063=L. ✓

APFS REPEAT (4 rows verified):

Rows 5-8: matrix/apfs/many_small_1byte/{2,3,4,5}/ample: All identical to run 1: L=1024, R=4194304, dest_regular=4194304, free_before=535085056, free_after=530849792, exit 0, hash true, observer 1024. All 5 runs match. Summary.json apfs_repeatability.many_small_1byte confirms 5 runs with identical allocations and composite_residuals=[40960,40960,40960,40960,40960]. ✓

APFS NEAR-ENOSPC (4 rows verified):

Row 9: boundaries/apfs/boundary_small/1/R: L=33587200, N=4096, R=50331648. F=50331648=R. dest_regular=37724160 (partial), exit 11. ✓ This is an ENOSPC at exactly R, proving R is necessary but not sufficient.

Row 10: adaptive/apfs/boundary_small/1/adaptive_bisect_3: F=63029248, exit 11 (fail). adaptive_bisect_4: F=63733760, exit 0 (success). Gap=704512. Proves APFS needs approximately 13.4 MiB beyond R for this workload.

Row 11: boundaries/apfs/boundary_large/1/R: L=R=33554432, F=33554432. dest_regular=0, exit 11. Even a single aligned 32MiB file fails at F=R on APFS. ✓

Row 12: adaptive/apfs/boundary_large/1/adaptive_bisect_0: F=44826624, exit 0. adaptive_bisect_4: F=44122112, exit 11. Approximately 11.3 MiB needed beyond R for a single large file.

EXFAT AMPLE (3 rows verified):

Row 13: matrix/exfat/many_small_1byte/1/ample: L=1024, N=1024, R_vfs=524288, R_C=33554432. Check R_vfs: 1024*ceil(1/512)*512=1024*512=524288. ✓ Check R_C: 1024*ceil(1/32768)*32768=1024*32768=33554432. ✓ dest_regular=33554432=R_C. ✓ R_vfs materially undercounts (64x). ✓

Row 14: matrix/exfat/ordinary_large_unaligned/1/ample: L=16777339, R_vfs=16777728, R_C=16809984. Check R_C: ceil(16777339/32768)*32768=ceil(512.0099)*32768=513*32768=16809984. ✓ dest_regular=16809984=R_C. ✓

Row 15: matrix/exfat/nested_many_directories/1/ample: L=256, N=256, D=1408, R_C=8388608. Check R_C: 256*ceil(1/32768)*32768=256*32768=8388608. ✓ dest_regular=8388608=R_C. ✓ Free delta=536641536-427458560=109182976. Huge residual from directory+sidecar allocation. ✓

EXFAT WRONG-UNIT (2 rows verified):

Row 16: matrix/exfat/near_small/1/L-epsilon: L=4096, N=4096, R_vfs=2097152, R_C=134217728. F=32768. dest_regular=0, exit 11. With only 32768 free, nothing can be written. R_vfs=2097152 >> 32768, but even R_vfs is wrong (should be R_C=134217728). ✓

Row 17: boundaries/exfat/boundary_small/1/R-epsilon: L=33587200, N=4096, R_vfs=35651584, R_C=134217728. F=35651584=R_vfs. dest_regular=17727488 (partial), exit 10. This proves R_vfs is insufficient even as a floor for exFAT. ✓

EXFAT CLUSTER-CORRECTED (2 rows verified):

Row 18: cluster-corrected/exfat/boundary_small/1/R: F=134217728=R_C. dest_regular=66846720 (partial), exit 10. Even at F=R_C, transfer fails because of sidecar+directory overhead. ✓

Row 19: cluster-corrected/exfat/boundary_large/1/R+1MiB_probe: F=34603008, R_C=33554432. dest_regular=33554432, exit 0. Success at F ≈ R+1MiB. ✓ This is the only cluster-corrected success, confirming that large aligned files need only modest metadata beyond R.

EXFAT RESIDUAL (3 rows verified):

Row 20: residual/exfat/boundary_small/1/observed_final_cost-1_clusters: F=269385728. dest_regular=134184960 (partial), exit 11. ✓ Fails at one cluster below the observed exact cost.

Row 21: residual/exfat/boundary_small/1/observed_final_cost+0_clusters: F=269418496. dest_regular=134217728, exit 0. ✓ Succeeds at exactly the observed cost.

Row 22: residual/exfat/boundary_large/1/observed_final_cost+0_clusters: F=33652736. dest_regular=33554432, exit 0. ✓ free_delta=33652736, composite_residual=98304. For one 32MiB file: 98304 = 32768 (directory for `._*` sidecar) + 32768 (one `._*` sidecar) + 32768 (job root directory). ✓

PHASE TOTALS VERIFIED: summary.json reports total_jobs=187, success=83, failure=104. Matrix counts: matrix 90 (59+31), boundaries 40 (0+40), adaptive 18 (11+7), cluster-corrected 24 (1+23), residual 15 (12+3). Sum: 90+40+18+24+15=187. ✓ Success: 59+0+11+1+12=83. ✓ Failure: 31+40+7+23+3=104. ✓

HASH/MANIFEST VERIFICATION:
- summary.json SHA256=744502f0... matches RAW_REF. ✓
- matrix.csv SHA256=5d9812ef... matches RAW_REF. ✓
- archive-manifest.json SHA256=0cf069b5... matches RAW_REF. ✓
- cleanup-verification.json SHA256=dfd61aa5... matches RAW_REF. ✓
- All 5 compressed archives SHA256 match both archive-manifest.json and RAW_REFs. ✓
- success_hashes_all_correct=true. ✓
- source_manifests_all_unchanged=true. ✓
- All 5 phases have cleanup recorded with all_test_mounts_detached=true, root_removed=true. ✓

MISMATCHES FOUND: Zero mismatches in spot-checked rows. All verified values are internally consistent.

### Policy matrix

| Policy | Evidence | Hard Gate Allowed | Formula | Runtime Inputs | Stable API Provenance | Allowed Claim | Forbidden Claim | Counterexamples | False Reject Surface | False Admit Surface | Impl Complexity | Unresolved Blocker |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P0=L | YES | YES (current) | F>=L | L from existing scan, F from existing capacity API | YES (Foundation fileSize + capacity) | Snapshot covers logical payload | Physical fit, copy success, SAFE TO EJECT | 92 false admits in matrix | None vs current | Rounding, directory, sidecar, metadata | None (existing) | None |
| P1=R(C) | PARTIAL | YES for APFS; NO for exFAT | F>=sum(C*ceil(s_i/C)) | Per-file sizes during scan + validated C | APFS YES (f_frsize=4096); exFAT NO (f_frsize=512≠32768) | Necessary data allocation floor | Sufficient capacity, upper bound, exact fit | APFS near-R failures; exFAT correct R still undercounts total cost | [L,R) interval — but this is necessary, not false reject | Metadata, sidecars, allocator overhead | O(N+D) per-file rounding in existing scan | exFAT runtime C provenance |
| P2=R+M | PARTIAL | NO (M unproven) | F>=R+m_dir+sidecar_estimate | Per-file sizes, topology, C, sidecar model | M components individually partial | Stronger necessary floor | Guaranteed upper M, exact fit | APFS M unproven; exFAT sidecar count unbounded | Unproven conservative M could reject feasible jobs | Underestimated M misses actual cost | O(N+D+name_units) scan + topology | Complete M budget for both FS; sidecar stability |
| P3=H_fs | PARTIAL | YES for APFS (H=R); CONDITIONAL for exFAT | F>=H_fs with residual warning | Branch on FS + branch inputs | APFS H=R provenance YES; exFAT conditional on C | Validated necessary floor + explicit uncertainty | Exact fit, complete support, protection against concurrent writers | Same near-capacity counterexamples | [L,H_fs) — necessary allocation, not false reject | Residual/metadata/sidecar outside H | P1 cost + FS identity + warning semantics | exFAT C provenance; FS identity (f_fstypename); warning product design |
| P4=unknown | YES | OWNER_DECISION (WARN+L or BLOCK) | F>=L + warning or BLOCK | FS identity + validity | FS identity check is implementable | Logical check only (WARN) or no unknown FS (BLOCK) | Unknown FS is safe; warned transfer will fit | All P0 counterexamples remain | WARN: none vs current; BLOCK: rejects all unknown-FS jobs | WARN: same as P0; BLOCK: zero | FS identity check minimal | Owner product support decision |

### Required final findings

CALIBRATION_CLAIMS_CONFIRMED:
1. L=sum(eligible regular file logical fileSize) is the current necessary admission floor. ✓
2. R(C)=sum(C*ceil(s_i/C)) with validated C matches per-file destination allocation in all ample rows on both APFS and exFAT. ✓
3. APFS f_frsize=4096 correctly predicts per-file allocation. ✓
4. exFAT f_frsize=512 does NOT predict per-file allocation; actual cluster is 32768. ✓
5. No public API returns correct exFAT cluster size on tested macOS. ✓
6. R is a necessary floor, not sufficient, on both filesystems. ✓
7. rsync `-a` does not include `-X` on rsync 3.4.4. ✓
8. Receiver creates `._*` AppleDouble sidecars on exFAT without `-X`. ✓
9. No 2x payload peak from rsync temp-write-rename strategy. ✓
10. Aggregate (L,N) cannot reconstruct per-file R. ✓
11. No PrivacyInfo.xcprivacy in repo. ✓
12. All 187 jobs with 83 successes and 104 failures, all hashes correct, all sources unchanged. ✓

CALIBRATION_CLAIMS_REJECTED:
None. All testable calibration claims are consistent with the evidence.

CALIBRATION_CLAIMS_PARTIAL:
1. P3 recommendation as the candidate policy is well-supported for APFS but conditional on unresolved exFAT cluster provenance. The calibration correctly marks this as conditional.
2. APFS R as necessary floor is confirmed but the calibration correctly does not claim it is sufficient.

CONTRADICTIONS:
1. exFAT public API minimum-allocation (512) vs actual per-file allocation (32768). This is a preserved contradiction documented by the calibration, not an error in the calibration.

SAFE_TO_IMPLEMENT_NOW=NO
SAFE_TO_IMPLEMENT_PARTIALLY=YES

EXACT BRANCH/FORMULA SAFE NOW:
- APFS branch: `H_apfs = R = sum(4096 * ceil(s_i/4096))`, hard gate `F >= H_apfs`, with explicit residual warning that metadata, allocator overhead, concurrent writers, and snapshots are not bounded by R. This is implementable because:
  - C=4096 has stable runtime provenance via `statvfs.f_frsize` or equivalent
  - R correctly predicts per-file allocation in all tested APFS rows
  - R is a proven necessary floor
  - The warning is truthful

EXACT BLOCKERS OUTSIDE APFS BRANCH:
1. FS IDENTITY: Current code uses `volumeLocalizedFormatDescriptionKey` (locale-dependent). Must use `statfs.f_fstypename` or equivalent stable machine identifier to branch between APFS, exFAT, and unknown. This is an IMPLEMENTATION BLOCKER for the APFS branch itself — without reliable FS identity, the code cannot know it is on APFS.
2. exFAT cluster provenance: No demonstrated production-safe API returns C=32768 for exFAT. Until this is solved, exFAT branch uses P0 (L) with warning, or is blocked per owner decision.
3. exFAT sidecar model: AppleDouble generation count/size is environment-dependent. No stable production contract for sidecar allocation.
4. Privacy declaration: PrivacyInfo.xcprivacy absent; required-reason applicability for macOS distribution unresolved.

OWNER_DECISIONS_REQUIRED:
1. Unknown/unvalidated FS policy: WARN+L (current behavior with warning) vs BLOCK (restrict to validated filesystems). This is a genuine product support scope decision.

IMPLEMENTATION_GATES:
1. FS identity must use `statfs.f_fstypename` (not localized format description)
2. Per-file rounding must use checked Int64 arithmetic
3. Destination-change must invalidate any destination-specific rounded sum
4. Residual warning must be explicit in operator-facing feedback — not "will fit" language
5. L remains the progress/observer denominator
6. No change to rsync flags, verification modes, TransferState ownership, or SAFE TO EJECT semantics

POST_IMPLEMENT_INDEPENDENT_REVIEW_REQUIRED=YES

### Independence evidence

REVIEWER_IDENTITY=Antigravity_IDE_Claude_Opus_4.6_Thinking
CALIBRATION_IMPLEMENTER=Codex_CLI_worker
SAME_MODEL_HARNESS=NO (different model family, different tool harness, different conversation)
PRIOR_NONCANONICAL_REVIEW=existed_in_chat_only;NOT_USED_as_premise;NOT_RECOVERED
ALL_FINDINGS_DERIVED_FROM=canonical_repo_files;primary_Apple_Darwin_documentation;Microsoft_exFAT_specification;rsync_3.4.4_tagged_source;raw_calibration_evidence_with_verified_hashes
INDEPENDENCE_LIMITATION=both_are_AI_models_operating_in_same_repo;reviewer_cannot_guarantee_zero_implicit_bias_from_shared_training_data;all_findings_are_re_derived_and_cross_referenced_against_primary_sources

### Change and verification evidence

CHANGED_SCOPE=HANDOFF_AND_REQUIRED_CONTROL_PLANE_ONLY
PRODUCT_MUTATION=NONE
SWIFT_MUTATION=NONE
INITIAL_PRODUCT_DIFF=EMPTY
INITIAL_TEST_PROJECT_DIFF=EMPTY
BRAIN_OWNERSHIP=BRAIN_REVIEW_STATUS_PENDING;BRAIN_CLASSIFICATION_UNSET;ACCEPTED_STATE_UNSET;ACTIVE_NEXT_NONE

### Single next decision

WORKER_PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_POLICY_ADJUDICATION
REASON=APFS_branch_implementable_with_FS_identity_fix;exFAT_branch_blocked_on_cluster_provenance;unknown_FS_requires_owner_product_decision;post_implement_review_required
STOP=after_canonical_publication_and_export

## NEXTSTEP
WORKER_NEXT=PROPOSAL_ONLY
ACTIVE_NEXT=NONE
WORKER_PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_POLICY_ADJUDICATION
