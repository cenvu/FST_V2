# Patch 1 validation

## Initial canonical Debug build and full test attempt

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/fst-p2-patch1-final-derived \
  -resultBundlePath /tmp/fst-p2-patch1-final.xcresult build test
```

Result: `BUILD SUCCEEDED`; `TEST FAILED`; 283 passed, 2 failed, 0 skipped; exit 65. The APFS and exFAT disposable image runtime tests both received `hdiutil create failed - Device not configured`. Evidence: `CANONICAL_DEBUG_BUILD_TEST.log.gz` and `INITIAL_PARALLEL_TEST_SUMMARY.json`.

## Full serial retry

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/fst-p2-patch1-final-serial-derived \
  -resultBundlePath /tmp/fst-p2-patch1-final-serial.xcresult \
  -parallel-testing-enabled NO build test
```

Result: `BUILD SUCCEEDED`; `TEST SUCCEEDED`; 285 passed, 0 failed, 0 skipped; exit 0. Evidence: `CANONICAL_DEBUG_BUILD_TEST_SERIAL_RETRY.log.gz` and `CANONICAL_TEST_SUMMARY.json`.

`git diff --check` passed after all final repository edits.
