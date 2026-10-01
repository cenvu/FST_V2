# Destination capacity policy specification candidate

TASK=DESTINATION_CAPACITY_FS_CALIBRATION
PRODUCT_WORKSTREAM=HEADROOM_B
OWNER_DECISION_B=B_FILESYSTEM_WORKLOAD_AWARE;ACKNOWLEDGED
STATUS=RECOMMENDED_CANDIDATE_ONLY;NOT_ACCEPTED;NO_IMPLEMENTATION
BRAIN_CLASSIFICATION=UNSET
ACCEPTED_STATE=UNSET
ACTIVE_NEXT=NONE

## Decision supported by the evidence

Per-file rounding can provide a stronger **necessary admission floor** than aggregate logical bytes on a validated filesystem/allocator profile. It cannot establish sufficient capacity, an exact job peak, or permission to eject. **The proposed universal estimator using `f_frsize` as the actual allocation granularity fails on tested macOS exFAT.** `getattrlist(ATTR_VOL_MINALLOCATION)` and `diskutil info` also report 512 bytes for the observed 32 KiB clusters. `_PC_ALLOC_SIZE_MIN` returns 1 on both tested filesystems. These public signals do not solve cluster discovery here.

The recommended candidate is P3 with a P4 branch: use a validated data floor where its inputs are trustworthy; keep metadata and allocator uncertainty explicit. exFAT cluster-based formulas remain conditional research specifications until runtime unit provenance is solved. No change to the application's filesystem acceptance boundary is authorized by this report. A product choice to block unsupported calibration profiles requires owner/BRAIN adjudication.

## Quantities that must stay distinct

| Quantity | Definition | Meaning |
|---|---|---|
| TRANSFER_PAYLOAD_LOGICAL | `L = sum(s_i)` for eligible regular-file logical sizes after existing exclusions | Current copy/progress denominator; source allocation, compression and xattrs are not payload credits |
| DATA_ALLOCATION_FLOOR | `R(C) = sum(C * ceil(s_i/C))`, with `R(0-byte file)=0` | Necessary data allocation under a validated uncompressed whole-unit write model; no metadata or exact-fit assurance |
| FILESYSTEM_METADATA_RESIDUAL | Directory streams, entries, receiver-generated AppleDouble files, allocator slack, extents/COW/checkpoints, parent growth and transient effects | Filesystem/workload/state dependent; a measured delta is not a guaranteed upper budget |
| AVAILABLE_CAPACITY_SNAPSHOT | Existing positive important-usage value, otherwise nonnegative ordinary capacity | Point observation, including expected purgeable capacity where supplied |
| RESERVATION | `NONE` | Other writers, shared volumes, snapshots, purge timing and source changes can invalidate the observation |
| GUARANTEE_EXACT_FIT | `NO` | No sufficient universal admission rule was proven |

Do not substitute either `statvfs.f_bsize` or `statfs.f_iosize` for `C`. Darwin `statfs.f_bsize` equals `statvfs.f_frsize`, but neither predicts tested exFAT clusters. The calibration records `R_vfs` separately from `R_cluster` to preserve this failed hypothesis.

An aggregate `L,N` pair cannot reconstruct per-file rounding: at `C=4096`, files `[4096,4096]` and `[1,8191]` both have `L=8192,N=2`, but `R=8192` and `R=12288`. A future implementation must compute the sum during a destination-aware source scan or preserve sufficient size distribution. It must not estimate `R` from a total alone.

## Filesystem metadata mechanism

For a conventional exFAT entry with `u` UTF-16 filename units, the minimal entry-set size is `e(u)=32*(2+ceil(u/15))`. For each **new** directory including the destination job root, a final-state directory lower floor is:

`m_dir(C,T) = sum_over_new_directories C*max(1,ceil(sum(e(child_name))/C))`.

The simpler `C*(D+1)` is a weaker necessary directory floor. Neither includes parent growth, fragmentation from temporary entries, vendor entries or additional receiver-generated files. Final names alone do not bound the temporary entry layout: rsync temp names may be longer and coexist with entries involved in rename. These formulas are final-state lower floors, **not upper metadata budgets**. A mandatory end-marker allowance must not be invented when an entirely full directory can terminate implicitly.

The tested exFAT receiver environment creates `._*` AppleDouble files containing `com.apple.provenance`. These are separate allocated files; they can materially exceed directory overhead. Source exclusions do not stop the destination filesystem/environment from creating them. This is not permission to count all source xattr/resource-fork bytes as transfer payload. The upstream receiver omits xattr preservation under the current flags; the origin and production-app variability of provenance generation remain unresolved. Sample counts/sizes are not a stable worst-case contract.

APFS provides no public formula here for an upper budget covering B-tree layout, allocation strategy, checkpoints, extents and usable allocator capacity. A sample minimum/maximum free delta or ENOSPC residual cannot be promoted into `M`, a percentage, or a guarantee.

## P0–P4 evaluation

`F` below is the existing selected capacity snapshot. Each policy applies only after all existing source/path/fresh-job/nonempty checks. False rejection means rejecting a job that would actually finish under otherwise identical conditions. Probability and workload prevalence are unknown. Intervals describe potential extra rejection, not measured rates.

| Policy | Formula and inputs | Public/stable provenance and tested scope | Permitted hard claim | Claim prohibited | Counterexamples / false admits | Potential false rejection interval | Complexity / scan and performance cost | Failure mode / fallback |
|---|---|---|---|---|---|---|---|---|
| P0 | `F>=L`; current eligible logical total, selected capacity | Foundation sizes/capacity; current APFS and exFAT matrices | Observed snapshot covers logical regular payload | Physical fit, copy success, reservation, SAFE TO EJECT | Small-file rounding, directory-heavy jobs, APFS ENOSPC with positive advertised space, exFAT generated metadata | No added interval versus current gate; future reclaim or unmodeled compression can still defeat a snapshot rejection | Existing metadata scan `O(N+D)`; no content read needed | Current handling of unknown capacity blocks; unknown FS accepted if other checks pass |
| P1 | `F>=R(C)`; each size and validated actual unit | APFS `f_frsize=4096` matched image allocation; exFAT `C=32768` proven from **image boot sector**, not a demonstrated reliable production API | Prevents admission below the model's necessary data allocation | R is an upper bound, exact peak, or sufficient capacity | APFS near-R fails; prior APFS sparse over-R allocation; exFAT `R_vfs` materially undercounts; correct `R_cluster` still omits AppleDouble/directories | Additional `[L,R)`; within a fixed validated uncompressed model this is necessary allocation, so no rounding-only false reject. Outside the model the claim is unavailable | Destination-aware rounding in existing scan `O(N+D)`, checked arithmetic; aggregate-only model must change or rescan | Missing/invalid unit, FS change or unsupported profile => explicit unknown-unit branch; do not guess from I/O size |
| P2 | `F>=R+M_mechanism`; sizes, C, names/topology, destination state, generated metadata and peak model | exFAT directory lower floors are spec-derived; full upper budget and runtime C unresolved; APFS full M unresolved | With proven components, excludes additional known necessary allocation | Guaranteed upper M from one successful run, sample maximum, fixed fraction, arbitrary reserve | exFAT `R+C*(D+1)` misses generated sidecars and entry growth; APFS measured usable-space residual; final allocation can miss temp peak | Potential `[L,R+M)`; a true necessary floor has no model-internal false rejects, an unproven conservative upper budget can reject feasible jobs in `[R,R+M)` | Topology/name accounting `O(N+D+name_units)`; stream per-parent totals `O(D)` memory; public source metadata only. Destination layout/peak modeling adds substantial complexity | Missing mechanism or budget proof => cannot advertise P2 as sufficient. No default numeric M |
| P3 | Validated `H_fs`, hard `F>=H_fs`; disclose unresolved residual separately. Candidate APFS `H=R`; conditional exFAT `H=R+m_dir` once C provenance is approved | Platform-bounded APFS evidence; exFAT conditional on trustworthy runtime cluster input. Machine FS identity should use public `statfs.f_fstypename`, not localized display text | Stronger necessary admission floor; residual remains uncertain | Exact physical fit, complete official FS support, protection against concurrent writers | Same near-capacity APFS and exFAT counterexamples above; warnings cannot prevent ENOSPC | `[L,H_fs)`; warning alone adds no rejection beyond the floor | P1/P2 source scan costs according to branch; warning semantics require separate product authorization | Unsupported/unknown unit routes to P4. Source scan error/overflow cannot silently become zero. No progress denominator change |
| P4 | Unknown FS or untrusted C: candidate `F>=L` plus explicit uncertainty warning; alternative owner choice blocks | Existing app accepts any writable destination folder; no universal allocator proof or allowlist is established | Logical capacity check only | Unknown FS is safe, unsupported FS is officially prohibited, or warned transfer will fit | All P0 allocator/metadata cases remain possible | Warn+L: no extra interval. Block: rejects every otherwise feasible unknown-profile job, including `F>=L` | Existing scan plus identity/validity checks; minimal cost; no source content scan | **Owner/BRAIN decision needed** between WARN+current_L and BLOCK. Worker recommends warning fallback to avoid silently changing product support; current_L without uncertainty disclosure provides no new safety information |

P3's residual warning is a policy proposal, not a UI patch. The selected candidate does not accept P2 as a complete sufficient estimator. Positive API values do not authorize bypassing errors or verification.

## Runtime implementation requirements for independent review

1. Identify filesystem and mount/volume identity with stable OS interfaces. Retain the human-readable format separately. Refresh capacity immediately before the existing gate; this still provides no reservation.
2. Obtain a validated allocation unit for the recognized filesystem/OS profile. Preserve the proven exFAT mismatch. Reading an image boot sector is an experiment technique; requiring raw physical-media access, privileged tools, or an empirical destination write probe would be new runtime behavior requiring its own authorized design and validation.
3. Accumulate eligible per-file sizes with checked signed-64-bit arithmetic and cancellation, off the UI thread. Validate nonnegative values, positive C and overflow. Maintain existing source read-only behavior and exclusions. A destination change invalidates any destination-specific sum.
4. Account for the newly created job root (`D+1`). For a richer directory floor, collect parent/name topology during the existing metadata enumeration. Regular-file counts alone miss directory entries and other rsync archive objects. Symlinks/special files, long/colliding names and FS limits require separate failure analysis; headroom cannot make an unsupported object transferable.
5. Keep `L` as transfer payload and observer/progress total. Do not use allocation or free-space deltas as completion evidence. A zero-logical-only source remains blocked by the current preflight even though standalone rsync can copy its entries in the experiment.
6. Keep rsync flags, verification modes, TransferState ownership, report safety and SAFE TO EJECT unchanged. Runtime ENOSPC, cancellation, source growth and competing writers require truthful failure handling and source-retention advice. Runtime free-space monitoring could aid operator feedback only under a separately authorized task; it cannot prove integrity or reserve capacity.

## Unresolved safety and product gaps

- No trustworthy stable runtime exFAT cluster acquisition was demonstrated from the requested public minimum-unit APIs. The on-disk experiment has correct C; a production app cannot inherit that evidence as an API guarantee.
- APFS R matched all ample fresh-image samples in this matrix, including five runs per sparse/small workload, but the prior sparse counterexamples and this task's near-ENOSPC failures prohibit calling R an upper bound or sufficient floor.
- Generated AppleDouble allocation and directory fragmentation are workload dependent. The receiver environment is terminal research on macOS 15.7.7, not a signed packaged FST runtime equivalence proof.
- Filler targets that were unattainable or missed are recorded using actual free space; they do not count as exact target measurements. Supplemental aligned workloads cover the required representable points. Adaptive search brackets remain observations, without monotonic or portable allocator guarantees.
- Source changes after scanning, snapshot/purge timing, APFS multi-volume competition, physical external-device allocation/fragmentation, other OS versions, HFS+, unknown/network filesystems, quotas and file-size/name/object limits are not proven by isolated images.
- Privacy declaration is absent in the checked-in repo; packaging/distribution applicability is unresolved. No manifest was changed.

WORKER_PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_INDEPENDENT_POLICY_ADJUDICATION
