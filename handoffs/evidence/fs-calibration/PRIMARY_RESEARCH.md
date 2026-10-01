# Primary research and repository anchors

TASK=DESTINATION_CAPACITY_FS_CALIBRATION
START_HEAD=c74178a8c406fc134432055b51af5bd5325bf30e
RESEARCH_BEFORE_EXPERIMENT=YES
OWNER_DECISION_B=B_FILESYSTEM_WORKLOAD_AWARE;ACKNOWLEDGED
AUTHORITY=REPO_AND_PRIMARY_DOCUMENTS;WORKER_EVIDENCE_ONLY

## Repository observations

- `DriveService.swift`: source scan uses regular-file logical sizes after six exclusions; directory count excludes the job root. Capacity prefers a positive important-usage value, then a nonnegative ordinary value. Filesystem display uses a localized format description.
- `StorageMetadata.swift`: stores aggregate logical size and counts, not individual sizes, filename lengths, topology, allocation unit, or a machine filesystem identifier.
- `TransferPreflightValidator` in `DriveService.swift`: a new job folder is mandatory; equality with logical size passes. Unknown capacity blocks. There is no filesystem allowlist.
- `RsyncCommand` in `RsyncEngine.swift`: bundled 3.4.4, `-a -h --info=name1,progress2 --outbuf=N`, exclusions, source without trailing slash, destination with trailing slash. Unlimited bandwidth is the experiment setting. No sparse, xattr, inplace, preallocate, external temp directory, or delay-updates option.
- `DestinationActivitySnapshotter`: sums logical regular-file sizes and clamps against the source total; telemetry has no authority to establish completion or integrity.
- Direct tests inspected: sparse/compressed/logical counting, exclusions, fresh-job rejection, capacity selection and equality, observer bounds in `MetadataOnlySourceSafetyXCTests.swift`; storage admission and observer denominator in `TransferViewModelRuntimeXCTests.swift`; `Tests/UnitTests/Services/DriveServiceTests.swift`. No test Swift file was changed or test suite rerun.
- CodeGraph MCP tools unavailable. Production inspection used actual source; no production edit required graph impact analysis.

## Capacity and file allocation

[Apple: Checking Volume Storage Capacity](https://developer.apple.com/documentation/foundation/checking-volume-storage-capacity) describes important versus opportunistic requests. The installed Apple SDK's `NSURL.h` clarifies that important capacity includes expected reclaimable cached space. This is a point observation, without a job reservation or overhead credit.

[Apple: fileAllocatedSizeKey](https://developer.apple.com/documentation/foundation/urlresourcekey/fileallocatedsizekey) and [totalFileAllocatedSizeKey](https://developer.apple.com/documentation/foundation/urlresourcekey/totalfileallocatedsizekey) describe reported allocation, with the latter potentially including metadata. Neither specifies the unique physical cost of a future copy. Source compression or shared extents cannot be subtracted from current rsync payload.

Installed Darwin `statvfs(3)`, `sys/statvfs.h`, and `sys/mount.h` are the direct platform authority. `statvfs.f_frsize` is the minimum allocation unit. On Darwin **`statfs.f_bsize` is also the fundamental allocation block size**, while `statfs.f_iosize` and **`statvfs.f_bsize`** describe preferred I/O. These similarly named fields must not be conflated. The experiment records all four. It uses only `f_frsize` in rounding, then tests that hypothesis per file. This corrects the ambiguity in the prompt's combined `f_bsize/preferred_IO` wording.

Darwin manual explicitly cautions about portability and incomplete `statvfs` information. A positive unit alone does not authenticate an arbitrary filesystem allocation algorithm. Two attempted Apple Libc source URLs returned 404; no inference from missing source was used.

## APFS

[Apple: About Apple File System](https://developer.apple.com/documentation/foundation/about-apple-file-system) documents shared container capacity, sparse files, clones, and Foundation clone behavior. Those clone APIs are distinct from rsync's write path.

[Apple File System Reference](https://developer.apple.com/support/downloads/Apple-File-System-Reference.pdf), retrieved before images were created, describes container block sizes, file extents, filesystem B-trees, checkpoints, and copy-on-write objects. Its space manager structures include reserve/free-queue state; the reference does not publish a stable worst-case budget for an arbitrary macOS rsync job or a public runtime formula that subtracts every allocator restriction from capacity. A free-space delta cannot isolate metadata or establish exact peak.

Prior repository evidence is preserved: `handoffs/20261001-092836_codex-local-worker_destination-capacity-headroom-decision.md` recorded five 1 GiB sparse copies on a shared host APFS volume with final reported allocation exceeding per-file rounding by 262,144 through 14,155,776 bytes. This task's fresh isolated images must not erase that counterexample or turn a sample maximum into a bound. The earlier experiment was not image-backed; its results are contextual evidence, not this matrix.

## exFAT

[Microsoft exFAT specification](https://learn.microsoft.com/en-us/windows/win32/fileio/exfat-specification), sections 3.1.14–15, 5.1, 6, 7.1, 7.4, 7.6, 7.7, and 9, defines clusters, bitmap allocation, directory streams and entry sets. Sector and cluster shifts in the boot sector give `C = 2^(BytesPerSectorShift + SectorsPerClusterShift)`. Files use whole clusters. Directory entries are 32 bytes; a normal entry set needs a primary entry, stream entry and enough filename entries to hold 15 UTF-16 units each. Names/topology therefore matter beyond total bytes and directory count.

The installed `newfs_exfat(8)` exposes cluster size choices. Calibration images are disposable, never a formatting recommendation for operator media. Boot-sector inspection reads the raw image file rather than an arbitrary device. Fixed FAT/bitmap structures already exist before the free-space snapshot; counting their complete size again would double-count. Directory expansion and driver behavior remain separate residuals.

HFS+ is optional and not tested in this task. No HFS+ allocation guarantee or generic cluster inference is imported from an untested specification.

After the exFAT mismatch appeared, the documented `getattrlist(2)` volume attributes were researched before querying them. The installed SDK's `sys/attr.h` and manual describe `ATTR_VOL_MINALLOCATION`, allocation clump, and available capacity. On the proven image these returned 512-byte minimum/clump values, while a 1-byte destination file used 32,768 bytes. `diskutil info` agreed with the 512-byte public value; `_PC_ALLOC_SIZE_MIN` returned 1. This is a preserved contradiction between the advertised minimum-unit descriptions and per-file cluster allocation, not evidence that preferred I/O can substitute for a cluster.

[RFC 1740, AppleDouble format](https://www.rfc-editor.org/rfc/rfc1740) identifies the AppleDouble header magic. Read-only inspection of a receiver-created sidecar found `00051607`, version `00020000`, a 4,096-byte file and the `com.apple.provenance` name. This supports identifying the extra files as AppleDouble. It does not establish why macOS generated provenance, whether source provenance was preserved, or a stable production-app sidecar size/count bound. Source and receiver provenance hashes matched in one sample; identical hashes do not distinguish copying from common automatic provenance.

## Exact rsync behavior

[v3.4.4 manual](https://github.com/RsyncProject/rsync/blob/v3.4.4/rsync.1.md), [receiver.c](https://github.com/RsyncProject/rsync/blob/v3.4.4/receiver.c), [fileio.c](https://github.com/RsyncProject/rsync/blob/v3.4.4/fileio.c), and [rsync.c](https://github.com/RsyncProject/rsync/blob/v3.4.4/rsync.c) were read at the exact tag. Archive omits xattrs and sparse preservation. The normal receiver creates a temporary file beside the final file, writes logical data, applies attributes and renames it. Temporary basenames can be eight characters longer, with name-limit handling. Same-volume rename transfers the existing allocation; cross-volume temp-copy fallback is outside current arguments. These semantics justify measuring one copy of data plus metadata/allocator residual, without assuming twice the payload.

The bundled executable's version and SHA256 are recorded in raw startup evidence. The upstream tag explains code semantics; binary/source reproducible-build equivalence was not established.

## Privacy packaging inspection

[Apple: NSPrivacyAccessedAPIType](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) lists volume capacity, statfs and statvfs in the disk-space category. E174.1 addresses observable admission behavior; 85F4.1 addresses displaying capacity. Their use restrictions include derived data. These are candidate relevant reasons, requiring a packaging/distribution audit before an actual declaration.

`git ls-files '*xcprivacy*' '*Privacy*'` returned no manifest; source/project searches found no privacy declaration. The explicit Resources phases are empty; the project uses macOS SDK settings. **Existing calls are not declared in the checked-in repository.** A shipped application's manifest was not inspected. [Apple's general required-reason guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) currently names iOS/iPadOS/tvOS/visionOS/watchOS in its platform text, whereas the property-list key page includes macOS availability. Therefore the missing declaration is a repository fact, not a claim that this native macOS distribution is currently rejected by App Store Connect. Platform/distribution applicability and exported diagnostic data remain unresolved. No manifest mutation was authorized or made.

RETRIEVAL=ego-browser_task_space_66;Apple_SDK_and_Darwin_manpages;official_tagged_raw_sources
EXPERIMENT_GAP=actual_macOS_allocator_behavior_under_current_bundled_rsync_and_image_ENOSPC
