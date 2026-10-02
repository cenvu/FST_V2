# Patch 3 canonical verification recovery

TASK=PATCH3_NOTIFICATION_CANONICAL_VERIFICATION_RECOVERY
WORKSTREAM_ID=OPENDESIGN_VISUAL_CONVERGENCE_P2
CLASS=VERIFICATION_ONLY
ROLE=VERIFIER
EXPECTED_HEAD=50c312e06a1192f5a67071e60d464baccdcdd94a
START_HEAD=50c312e06a1192f5a67071e60d464baccdcdd94a
START_ORIGIN_MAIN=50c312e06a1192f5a67071e60d464baccdcdd94a
START_WORKTREE=CLEAN
HOST_DIAGNOSTICS=HOST_DIAGNOSTICS.md

Prior failure, preserved exactly in `../patch3/TEST_FULL_FIRST.log` and `../patch3/TEST_FULL_RETRY.log`:

```text
DestinationCapacityImageRuntimeXCTests/testDisposableAPFSAdmissionAndVerifiedCopy
hdiutil create failed - Device not configured
```

Host diagnostics observed before running tests found no attached disk images and no `FSTCapacityImageQA-*` temp roots. The system disk listing showed only internal APFS storage. No disk/media operation was performed.

Isolated run (exactly one attempt; fresh DerivedData and result bundle):

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/fst-patch3-verify-isolated-20261002-1627-derived -resultBundlePath /tmp/fst-patch3-verify-isolated-20261002-1627.xcresult -parallel-testing-enabled NO -only-testing:FishSockTransferTests/DestinationCapacityImageRuntimeXCTests/testDisposableAPFSAdmissionAndVerifiedCopy test
```

ISOLATED_APFS_TEST=PASS
ISOLATED_PASSED=1
ISOLATED_FAILED=0
ISOLATED_SKIPPED=0
ISOLATED_HDIUTIL_STDERR=NONE;create succeeded
ISOLATED_BEFORE_PRODUCTION_ASSERTIONS=NO;test proceeded through APFS assessment, expected preflight block, bundled rsync hash verification
CLEANUP=PASS;test-owned defer reported cleanup success
OWNER_MEDIA_TOUCHED=NONE
ISOLATED_LOG=ISOLATED_APFS.log
ISOLATED_SUMMARY=ISOLATED_APFS_SUMMARY.json

Full canonical suite (exactly one run; fresh DerivedData and result bundle):

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj -scheme FishSockTransfer -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath /tmp/fst-patch3-verify-full-20261002-1628-derived -resultBundlePath /tmp/fst-patch3-verify-full-20261002-1628.xcresult -parallel-testing-enabled NO test
```

FULL_CANONICAL_TESTS=285_PASSED_0_FAILED_0_SKIPPED
FULL_RUN_COUNT=1
FULL_LOG=FULL_CANONICAL.log
FULL_SUMMARY=FULL_CANONICAL_SUMMARY.json

Structured results come from `xcrun xcresulttool get test-results summary --path <fresh result bundle> --format json`. Raw console logs and structured summaries are retained as repository evidence; result bundles remain in the exact `/tmp` paths above.

NO_PRODUCTION_MUTATION=YES
PATCH3_VISUAL_CHANGES=NONE
PATCH3_PRODUCTION_BYTES_UNCHANGED=YES
PRODUCTION_SHA256_AT_START_AND_END=bf1aa5a1572db82699457e65128d9410ccbe6a78ff57cacc9f2faa6c20df364a
PRODUCTION_TEST_PROJECT_CONFIG_BYTES_CHANGED=NONE
DIFF_CHECK=PASS

The only working-tree addition during verification was this evidence directory. No code, tests, Xcode project, harness/system configuration, disk policy, Codex configuration or source media was changed. No Patch 4/5 work occurred. Prior full-run APFS infrastructure failure is resolved on this verified host cycle; original failed evidence remains available and unchanged.
