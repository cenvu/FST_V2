# Patch 4 evidence index

| Evidence | Contents |
|---|---|
| `TECH_LOG_GAP_MATRIX.md` | Pre-edit region-by-region gaps and bounded proposals |
| `BEFORE_TECH_LOG_EMPTY.png` | Empty Technical Log at 1120×760 points |
| `BEFORE_TECH_LOG_POPULATED.png` | Synthetic production-category log at 1120×760 points |
| `BEFORE_TECH_LOG_DIAGNOSTICS.png` | Same synthetic logs with production diagnostics filter enabled |
| `BEFORE_TECH_LOG_MINIMUM.png` | Empty Technical Log at 900×660 points |
| `PATCH4_COMPARE_A.md` | Pass A findings and the one bounded empty-state refinement |
| `PASS_A_TECH_LOG_EMPTY.png` | Pass A empty state |
| `PASS_A_TECH_LOG_POPULATED.png` | Pass A populated state |
| `PASS_A_TECH_LOG_DIAGNOSTICS.png` | Pass A diagnostics-visible state |
| `PASS_A_TECH_LOG_MINIMUM.png` | Pass A minimum geometry |
| `PATCH4_COMPARE_B.md` | Pass B result and remaining-gap review |
| `PASS_B_TECH_LOG_EMPTY.png` | Pass B centered nominal empty state |
| `PASS_B_TECH_LOG_POPULATED.png` | Pass B populated state |
| `PASS_B_TECH_LOG_DIAGNOSTICS.png` | Pass B diagnostics-visible state |
| `PASS_B_TECH_LOG_MINIMUM.png` | Pass B centered minimum empty state |
| `AFTER_TECH_LOG_EMPTY.png` | Final empty state at 1120×760 points |
| `AFTER_TECH_LOG_POPULATED.png` | Final populated state at 1120×760 points |
| `AFTER_TECH_LOG_DIAGNOSTICS.png` | Final diagnostics-visible state at 1120×760 points |
| `AFTER_TECH_LOG_MINIMUM.png` | Final minimum geometry at 900×660 points |
| `CAPTURE_METHOD.md` | Native fixture, geometry, isolation, and reproduction method |
| `FINAL_VISUAL_GAP_REPORT.md` | Final evidence classes and remaining native differences |
| `BEHAVIOR_REVIEW.md` | Exact behavior-preservation review |
| `SCOPE_GATE.md` | Authorized production paths and retained patch gates |
| `PATCH4_PRODUCTION_REVIEWED.diff` | Pointer to the exact compressed two-file production diff |
| `PATCH4_PRODUCTION_REVIEWED.diff.gz` | Byte-preserving gzip of the exact production diff; extract with `gzip -dc` |
| `BUILD.log` | Canonical Debug build output |
| `FOCUSED_TESTS.log`, `FOCUSED_TEST_SUMMARY.json` | Existing filter/update tests: 40 passed, 0 failed, 0 skipped |
| `FULL_TESTS.log`, `FULL_TEST_SUMMARY.json` | One full canonical suite: 285 passed, 0 failed, 0 skipped |
| `VALIDATION.md` | Commands, result bundles, and final verification record |

The four AFTER PNGs are byte-identical to their independent Pass B captures.
SHA256:

| Final PNG | SHA256 |
|---|---|
| `AFTER_TECH_LOG_EMPTY.png` | `52cf5a9837d9e53d38b3676bc0751dd5b255285a8961231a3588ac081682ed23` |
| `AFTER_TECH_LOG_POPULATED.png` | `6c06ba4a4d4150644ae81728b28ad099c21ff4a063896cd2b0bee0aee88e344f` |
| `AFTER_TECH_LOG_DIAGNOSTICS.png` | `f323e8d69816bfbb960c1aea0dc985eed9b141d3a332f9e51fc4c99e823a50d8` |
| `AFTER_TECH_LOG_MINIMUM.png` | `2977a36e76bee737b38c2a73e71eddcd75b2a726118ea11a27cd9e9f905dc59c` |
