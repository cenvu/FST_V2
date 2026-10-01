# Destination filesystem calibration evidence

Control-plane research artifacts only. No production or test Swift file changed.

- [Primary research](PRIMARY_RESEARCH.md): repository anchors, official sources, API semantics and privacy finding.
- [Policy candidate](POLICY_SPEC_CANDIDATE.md): P0–P4, formulas, runtime inputs, prohibited claims and unresolved decisions.
- [Full matrix](MATRIX.md), [CSV](matrix.csv), [summary](summary.json): 187 recorded jobs, including failures and missed targets.
- [Archive manifest](archive-manifest.json): lossless compressed raw JSON size/hash inventory. The five `events.json.gz` files retain source/destination per-file sizes, allocations, hashes, attributes, command arguments, volume provenance, sampling and failures.
- [Cleanup verification](cleanup-verification.json): all ten registered temporary roots absent and no attached image from those roots.
- `setup-attempt*.json`: stopped setup attempts retained. `unit-api-observations.json` and `appledouble-observations.json` retain supplemental read-only API/format observations. The empty live-sidecar observation file records an earlier observation window with no attached exFAT image; it is not evidence of sidecar absence.

The compressed JSON is canonical raw evidence, not a disk image. All disposable image files and mounts were removed. The archive manifest includes SHA256 of both compressed bytes and original JSON; decompression is lossless. Exporter RAW arguments use UTF-8 summary/CSV/manifest metadata, while the handoff validates compressed artifacts directly with publisher RAW hashes.

The CSV uses Python's standard CSV writer CRLF record endings. Git's default staged whitespace check reports those carriage returns as trailing whitespace; the complete staged check uses `core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol` to recognize valid CRLF while retaining the normal whitespace checks. The published CSV bytes and RAW hash are preserved.

## Execution and reproduction

`calibrate.py` creates exclusively new, fixed-length 512 MiB raw image files under a unique `/tmp/FST-FS-Calibration-*` directory. It attaches them without mounting, verifies the image-path/device/Virtual receipt, and only then permits filesystem construction on that exact image device. It detaches and remounts images through `hdiutil`, never selects a physical disk. Filler writes occur only on those fixed images. Source fixtures are built first, then the source image is mounted read-only for all rsync reads. Initial host free capacity was about 136 GiB; each process allows at most three image files. At most four phase processes overlapped, giving a conservative backing-length upper bound of 6 GiB, plus bounded research evidence.

The initial blank image SHA is recorded before filesystem construction. Fresh receiver copies have size and SHA recorded before mount. Source image lineage is recorded from blank creation through format and attach, with a frozen image SHA computed before the read-only phase and compared after detach for completed phases. The final collector additionally emits an explicit current-image pre-attach SHA receipt. Collector refinements made during execution are documented below; no retrospective pre-attach receipt is invented for earlier source remounts.

Commands used one collector with separate output directories. Equivalent final collector entry points are:

```sh
python3 handoffs/evidence/fs-calibration/calibrate.py
python3 handoffs/evidence/fs-calibration/calibrate.py --boundaries-only --output-dir handoffs/evidence/fs-calibration/boundaries
python3 handoffs/evidence/fs-calibration/calibrate.py --adaptive-only --output-dir handoffs/evidence/fs-calibration/adaptive
python3 handoffs/evidence/fs-calibration/calibrate.py --cluster-corrected --output-dir handoffs/evidence/fs-calibration/cluster-corrected
python3 handoffs/evidence/fs-calibration/calibrate.py --residual-only --output-dir handoffs/evidence/fs-calibration/residual
```

These are **experiment reruns**, not instructions to run against operator media. The actual supplemental invocations imported the collector, set its `OUT` to the corresponding directory, and passed the phase flag; the final `--output-dir` interface removes that wrapper. Collector code evolved between phases: canonical mount-path comparison, Darwin xattr reads, rename-race handling, detach retry, actual Swift observer compilation, directory/sidecar accounting and phase options. Raw records from earlier phases intentionally lack fields added later. Exact collector-source hashes for each executing process were not captured; final source is retained for reproducibility, without a byte-identical replay claim.

The collector compiles Objective-C read-only capacity probes and an ignored Swift runner using unchanged `DriveService`, `StorageMetadata`, exclusion and event source plus the exact observer block from `RsyncEngine.swift`. Production source hashes and extracted observer hash are in `runtime_probe` records. Swift generation/binaries stay under repo-ignored `build/`. Hash comparison is an independent research check, not the app's verification workflow.

`unit-probe.m` was compiled separately and queried only mounts returned for registered image paths. It measures public Darwin minimum-allocation/clump/space attributes and `_PC_ALLOC_SIZE_MIN`. Its observations do not solve exFAT cluster discovery. Boot-sector parsing reads image files; it does not read an owner device.

Render/archive recorded results without creating images:

```sh
python3 handoffs/evidence/fs-calibration/summarize.py
```

## Stopped attempts and limits

- Mount-path equality initially rejected `/tmp` versus `/private/tmp`; paths were canonicalized and cleanup verified.
- This macOS Python lacks `os.listxattr`; the collector uses Darwin's read-only libc interfaces instead.
- A busy disposable APFS detach stopped an attempt; subsequent detach handling retries, then permits forced detach only after re-proving the exact disposable image. Every root was ultimately removed.
- A temporary-file rename raced telemetry `lstat`; only live sampling ignores disappeared entries. Settled hash/manifest checks still fail on disappearance.
- An observer extraction delimiter error occurred before image creation; the empty root was removed.
- The `boundaries` phase stopped immediately when a newly attached `unitprobe.img` was temporarily absent from `hdiutil info`. No formatting or copy followed that failed provenance check. Cleanup subsequently re-proved the image and detached it. Its unfinished exFAT large-file segment and final whole-source-image SHA comparison were not executed. The separate cluster-corrected phase completed all required exFAT boundary workloads with new proven images. Forty completed jobs from the stopped phase remain preserved.

46 filler observations missed their requested target. The initial tiny workloads also had targets below an attainable APFS floor or outside exFAT cluster alignment. They remain evidence of failure/measurement limits; exact-point claims use the aligned `boundaries` APFS rows and `cluster-corrected` exFAT rows, where selected capacity equals the requested target for every L/R/epsilon/residual point.

APFS free deltas include allocator/metadata timing even in an isolated image; no exact unique physical cost is inferred. Peak sampling counts regular data allocation and can miss transients; sidecars/directories are measured separately in later settled rows. HFS+, real devices, other OS versions, signed packaged FST behavior, contended APFS containers, purge timing and privacy manifest mutation were not executed.
