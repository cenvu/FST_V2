# Isolated APFS recovery test

TASK=PATCH3_NOTIFICATION_CANONICAL_VERIFICATION_RECOVERY
TEST=DestinationCapacityImageRuntimeXCTests/testDisposableAPFSAdmissionAndVerifiedCopy
ATTEMPTS=1
RESULT=PASS
PASSED=1
FAILED=0
SKIPPED=0
EXIT=0
DERIVED_DATA=/tmp/fst-patch3-verify-isolated-20261002-1627-derived
RESULT_BUNDLE=/tmp/fst-patch3-verify-isolated-20261002-1627.xcresult
LOG=ISOLATED_APFS.log
SUMMARY=ISOLATED_APFS_SUMMARY.json

Prior exact failure from the Patch 3 implementation run: `hdiutil create failed - Device not configured` (full stderr line is preserved in `../patch3/TEST_FULL_FIRST.log` and `TEST_FULL_RETRY.log`). This isolated invocation emitted no hdiutil create error. The APFS image was created; the test reported APFS, then its expected preflight block before rsync at 14,278,656 bytes vs 33,554,432 floor; bounded bundled-rsync 3.4.4 verified copy/hash for 8,192 files; and its own cleanup path reported `CLEANUP=PASS`. It ran entirely under the UUID disposable root `/var/folders/89/bwjml4px7bd8_gc4y493myh80000gn/T/FSTCapacityImageQA-53ACA323-30AC-4986-AD1A-F4C1A7808555`. `OWNER_MEDIA_TOUCHED=NONE`. No cleanup action was performed by the verifier.

Only one isolated attempt was made. Because it passed, the task directs one full canonical suite next; that run has started once with separate fresh DerivedData and result bundle. No full-suite retry is allowed.
