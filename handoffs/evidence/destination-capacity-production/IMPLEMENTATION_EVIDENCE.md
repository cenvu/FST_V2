# Destination Capacity Policy Production Implementation evidence

TASK=DESTINATION_CAPACITY_POLICY_PRODUCTION_IMPLEMENTATION
START_HEAD=67e28a06b267f7da741b58cd848aee2ebcb56ddb
ROLE=IMPLEMENTER_NOT_INDEPENDENT_REVIEWER
POLICY_AUTHORITY=Owner prompt APFS_STRICT_R;EXFAT_UNKNOWN_WARN_PLUS_L
OWNER_FOLLOWUP=Explicitly authorized removing capacity detail from Telegram failure summary to satisfy Apple disk-space reason restrictions

## Production delta and formulas

Exact production patch: `production.diff.gz`; exact XCTest patch: `tests.diff.gz`. Both decompress to verbatim `git diff HEAD` at START_HEAD, including the new manifest. `diff-manifest.json` records archive and decompressed hashes. Compression preserves original/context whitespace without creating a publication whitespace violation.

- `L = sum(s_i)` over eligible regular-file logical `.fileSizeKey`; source metadata contains L only. Sparse and compressed sources receive no allocated-byte credit.
- Validated profile is exactly machine identity `apfs` and public runtime allocation unit `4096`.
- For that profile, `R = sum(roundUp(s_i,4096))`. Zero contributes zero. For a nonaligned positive size, roundUp is checked `size + (unit - size % unit)`; aligned sizes are unchanged. No ceil-multiply intermediate, wrapping, saturation or fallback on overflow. Logical and rounded sums and file/directory counters use checked additions.
- Other profiles (including exfat reporting 512, unknown, failed identity probes, and APFS with missing/invalid/unexpected unit) use L with allocation uncertainty. No allowlist, cluster assumption, raw-device production probe, empirical production write, or arbitrary margin.
- Admission is `F >= floor`; equality passes. The actual floor appears in the insufficient-space error. R is a necessary regular-file data floor, never a complete physical requirement or guarantee.
- `DriveService.preparePreflight` performs one eligible metadata enumeration for L/R, refreshes capacity after it, and rejects changed filesystem/unit/mount identity. Coordinator applies the validator to that fresh assessment before copying. Report source metadata is assigned before admission failure. `DriveService.preflight` is the same preparation/validator path used directly by runtime tests.
- Stable identity: public Darwin `statfs.f_fstypename`; unit: `statfs.f_bsize`, documented fundamental filesystem block size. `f_fsid` guards destination mount/profile consistency. Localized filesystem description is display-only. Fresh Foundation URLs prevent reuse of preview capacity values; capacity retains the existing positive important-usage preference, then ordinary nonnegative fallback.
- Assessment is bound to canonical source/destination URLs. Selection/Clear cancels and discards the preview; a new destination recomputes its own profile/unit/floor/capacity. `hasInsufficientDestinationSpace` consumes the assessment. Programmatic `startTransfer` submits to fresh Coordinator authority rather than vetoing from old preview evidence.
- `TransferPreflightPlan.transferableBytes`, source metadata and all copy/observer denominators remain L. Observer and progress code unchanged, including the active-copy 99% cap.
- Storage view retains panel, row layout, spacing and header location. It shows Payload / Admission Floor / Available / Margin Above Floor; CAPACITY PRECHECK PASSED is neutral for validated APFS, warning text+icon for unvalidated allocation. No STORAGE READY or Remaining After Copy wording. Capacity has no SAFE TO EJECT relation.
- Only the Owner-authorized notification change strips capacity API/derived error details to a generic transfer failure before making the Telegram context. Other notification behavior unchanged.

Protected source files verified byte-unchanged via `git diff --exit-code`: RsyncEngine, VerifyEngine, ProgressParser, TransferFileExclusionPolicy, TransferState, VerificationMode, ReportEngine, TelegramNotificationService and AppUpdateService. No Xcode configuration, xattrs, rsync arguments, bandwidth, ETA, report safety, verification or OpenDesign convergence mutation.

## Privacy primary research and packaging

Current official references were retrieved before manifest mutation:

- [Apple API categories](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype): Foundation volume capacity and statfs/statvfs belong to DiskSpace.
- [Apple approved reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons): E174.1 applies to an observable pre-write disk-space admission check; 85F4.1 applies to capacity display. Both restrict off-device disk-space/derived information. Owner explicitly authorized redaction of capacity failure details in the Telegram context.
- [Apple manifest schema/packaging](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) and [required-reason guidance](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
- [Apple public statfs structure](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/sys/mount.h) confirms machine name, fundamental block size, and filesystem identity fields; installed Darwin SDK inspected too.

`privacy-research.json` contains exact declared schema, usage mapping, retrieval payload hashes, references and built manifest hash. Manifest contains only `NSPrivacyAccessedAPITypes` -> DiskSpace -> E174.1,85F4.1. No tracking/data-collection claims or unused reasons invented. Existing synchronized app source group packages it; canonical Debug bundle contains byte-identical manifest. Source/bundle plutil lint PASS; XCTest exact-schema inspection PASS. Native macOS enforcement is not inferred from Apple's platform text.

## Exact verification

See `verification.json` for exact commands, result bundle paths and native OS/architecture.

- Canonical Debug build PASS (exit 0).
- Focused DriveService/preflight/ViewModel/presentation/rounding/privacy: 138 passed, 0 failed, 0 skipped.
- Disposable image runtime QA: 2 passed, 0 failed, 0 skipped.
- Full canonical xcodebuild test: 277 passed, 0 failed, 0 skipped. Full includes both runtime image tests.
- Protected production source diff empty; git diff --check PASS before publication.
- New tests cover rounding 0/1/4095/4096/4097/large unaligned/many small/near overflow/sum overflow/invalid unit; machine-vs-localized identity; probe failure; all profile branches; equality/floor-1; tiny-file old-L false admission; aligned equivalence; stale destination rejection/recomputation; exclusions/sparse/compression/read-only/cancellation; independent plan floor and L observer/progress; wording and manifest.

Earlier unsuccessful build/fixture/test attempts remain recorded in verification.json; they are not final passes. Actual exFAT rsync ENOSPC from the larger initial fixture is preserved as a capacity-sufficiency counterexample. New progress assertion was corrected to existing 99%, without changing production progress.

## Image runtime and cleanup

Exact bounded observations in `runtime-evidence.txt`:

- APFS disposable 128 MiB image: identity apfs, unit 4096; 8192 one-byte files => L=8192, R=33554432. Measured F=14282752 admits old L but fresh authoritative preflight blocks R. Coordinator reaches error before copying and never SAFE TO EJECT. After filler removal, F>=R passes; bundled rsync 3.4.4 succeeds; all 8192 SHA256 pairs match; observer bytes/denominator remain 8192.
- exFAT disposable 512 MiB image: exact newly attached image/device receipt checked before image-only newfs_exfat; no owner media or production raw-device code. Machine identity exfat, public unit512, 512 one-byte files => floor=L=512. At F=8126464 fresh logical-only preflight passes; actual receiver reports ENOSPC(28), exits11, Coordinator reports TRANSFER ERROR and never TRANSFER COMPLETE/SAFE TO EJECT. Source retained. After removing QA-only partial destination/filler, successful copy hashes all512 files and observer remains L512. No claim of fit.
- `cleanup-verification.json`: no attached task images, no remaining UUID source/destination/image fixtures; earlier detached orphan removed only after image absence proven. No owner media touched. All writes restricted to generated fixtures/image mounts.

## Native presentation QA and limitations

`native-qa.swift` is a standalone AppKit/SwiftUI harness using actual StorageAnalysisView and production sources, inert bookmarks and token storage, synthetic metadata, and no owner media. It displayed four native windows at 600x300 points, then captured their NSHostingView output at Retina resolution. `native-apfs-light.png`, `native-exfat-light.png`, `native-apfs-dark.png`, `native-exfat-dark.png` were physically inspected: supporting text/rows visible without clipping; uncertainty uses text+icon; APFS neutral rather than verified-transfer green. This is the actual native storage view, not a full-app navigation or external-device visual run. No layout convergence work.

Remaining risks: F is a point snapshot and may include expected purgeable capacity; no reservation. R excludes filesystem metadata/allocator/COW/checkpoint costs. exFAT public 512 signal is not validated cluster size. Source growth, competing writers, shared containers, quotas, physical fragmentation and other OS profiles remain uncertain; no formula proves fit. Runtime failure handling and copy+required-verification safety truth remain authoritative. CodeGraph tools unavailable; direct source/tests inspected. Privacy declarations describe these concrete disk-space usages, not a broad distribution or app privacy audit. Native full-app navigation and owner-device QA not performed.

BRAIN review/classification/accepted state remain pending/unset. Exactly one proposal: return to BRAIN for post-implementation independent review.
