# Evidence Index — c248 Localization Catalog Reconciliation

## Catalog preservation and semantic comparison

- `RAW_LOCALIZABLE_DIFF.patch` — exact `git diff -- FishSockTransfer/FishSockTransfer/Localizable.xcstrings` captured before restore.
- `RAW_PATCH_SHA256.txt` — patch digest.
- `DIRTY_FILE_SHA256.txt` and `CANONICAL_FILE_SHA256.txt` — exact dirty/canonical catalog digests captured before restore.
- `REANCHOR.txt` — fetched HEAD/upstream and initial sole dirty path/stat.
- `SEMANTIC_DIFF.md` and `SEMANTIC_DIFF.json` — normalized comparison, exact changed sets, and recent localization commit correlation.
- `RESTORATION.txt` — authorized single-file restore and post-restore digest/diff state.
- `SECRET_SCAN.txt` — pre-publication scan result.

## Verification

- - `FOCUSED_LOCALIZATION_TEST.txt` and `FOCUSED_LOCALIZATION_TEST_SUMMARY.json` — focused localization run and exact xcresult counts.
- `TRANSFER_CONTROLS_LABEL_TEST.txt` — standalone presentation test compile/run output.
- `RSYNC_BANDWIDTH_LIMIT_TEST.txt` — standalone bandwidth model test compile/run output.
- `FULL_CANONICAL_TEST.txt` and `FULL_CANONICAL_TEST_SUMMARY.json` — fresh DerivedData full suite; 301 passed, 0 failed, 0 skipped.
- `VALIDATION.md` — exact commands, paths, and totals.
- `BEHAVIOR_REVIEW.md` — source-level C248 behavior checks.
- `SCOPE_GATE.md` — scope, restore, and pass gates.

## Existing c248 runtime visual proof

No new visual captures were taken in this verification task. The already committed c248 evidence is referenced at `handoffs/evidence/transfer-controls-language-toggle/VISUAL_QA.md` and `EVIDENCE_INDEX.md`, including EN↔VI flag-toggle and EN/VI READY/minimum-width captures.
