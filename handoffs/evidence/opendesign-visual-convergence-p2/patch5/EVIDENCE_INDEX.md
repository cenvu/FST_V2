# Patch 5 evidence index

TASK=OPENDESIGN_VISUAL_CONVERGENCE_P2_PATCH5_FINAL_POLISH
BEFORE_AFTER_PAIRS=20
BYTE_IDENTICAL_PAIRS=20

| State | Before | After | Geometry | SHA256 (both) |
|---|---|---|---|---|
| `CANCELLED` | `BEFORE_CANCELLED.png` | `AFTER_CANCELLED.png` | 1120x760pt | `9a6b98d7939308dafcb4f2dfb730f16b593f2d75605a5aa54429a4ead1cbc3e8` |
| `COPYING` | `BEFORE_COPYING.png` | `AFTER_COPYING.png` | 1120x760pt | `61fa492b96a2d72818fc10a9f8b7a3218a9d2aef1e9ee861b694ecbbeb5bb015` |
| `ERROR` | `BEFORE_ERROR.png` | `AFTER_ERROR.png` | 1120x760pt | `53c9aa1011b4c695d1c64d774d306edece06709c464684b2b566932c65f5732f` |
| `ERROR_MINIMUM` | `BEFORE_ERROR_MINIMUM.png` | `AFTER_ERROR_MINIMUM.png` | 900x660pt | `fa1c437839a623213aa1510324fc55d19be36d2bbe97656a77a9706ae5ff0df3` |
| `MANUAL_CHECK_REQUIRED` | `BEFORE_MANUAL_CHECK_REQUIRED.png` | `AFTER_MANUAL_CHECK_REQUIRED.png` | 1120x760pt | `3d36b0fb18068e36836216d562f05696f8cf82437cd4c68342f178dfad5d88ff` |
| `NOTIFICATION` | `BEFORE_NOTIFICATION.png` | `AFTER_NOTIFICATION.png` | 1120x760pt | `a2282f21d63abb56c1c653b1123591509ce5435176d0b0f7e18c0d7234668278` |
| `NOTIFICATION_MINIMUM` | `BEFORE_NOTIFICATION_MINIMUM.png` | `AFTER_NOTIFICATION_MINIMUM.png` | 900x660pt | `e088bb8a8d91ba102c1dc2f622f6997206e4926e765cffe28d10f128312612c2` |
| `NOTIFICATION_MINIMUM_SCROLLED` | `BEFORE_NOTIFICATION_MINIMUM_SCROLLED.png` | `AFTER_NOTIFICATION_MINIMUM_SCROLLED.png` | 900x660pt | `2c1df0ea089d484b578e020b258fdb3356da5dde7503130965046d2db05d5c73` |
| `PREPARING` | `BEFORE_PREPARING.png` | `AFTER_PREPARING.png` | 1120x760pt | `57c71ba4f3b83f66e4cfc088ad58de01439385f1b52f357f521dda2605fe5aed` |
| `READY` | `BEFORE_READY.png` | `AFTER_READY.png` | 1120x760pt | `ea0df1d7965ed87ad8bddcd347a2ce14334ed5bef32e6acca7b87c2d9f44b411` |
| `READY_MINIMUM` | `BEFORE_READY_MINIMUM.png` | `AFTER_READY_MINIMUM.png` | 900x660pt | `5a11ed852120878a27e2df030903ef87e636217ceac1762b76b719b3aa703766` |
| `READY_MINIMUM_SCROLLED` | `BEFORE_READY_MINIMUM_SCROLLED.png` | `AFTER_READY_MINIMUM_SCROLLED.png` | 900x660pt | `313e110b33bade0462e9a29351c4a4f664d20d6ad173993a29252cca2da919d8` |
| `SAFE_TO_EJECT` | `BEFORE_SAFE_TO_EJECT.png` | `AFTER_SAFE_TO_EJECT.png` | 1120x760pt | `bed51a0c04ffae7be2ae3b1c085d876d0da1ccfcc1598513f5a25248b8047f68` |
| `SAFE_TO_EJECT_MINIMUM` | `BEFORE_SAFE_TO_EJECT_MINIMUM.png` | `AFTER_SAFE_TO_EJECT_MINIMUM.png` | 900x660pt | `e2f1689e235994761914ff843f4b7cd39841ef52442510928405c1e728184dbd` |
| `TECH_LOG_DIAGNOSTICS` | `BEFORE_TECH_LOG_DIAGNOSTICS.png` | `AFTER_TECH_LOG_DIAGNOSTICS.png` | 1120x760pt | `127054b668d96c641c4920c53a65b95025d96d3d6109ff865cdb7509fe731f91` |
| `TECH_LOG_EMPTY` | `BEFORE_TECH_LOG_EMPTY.png` | `AFTER_TECH_LOG_EMPTY.png` | 1120x760pt | `52cf5a9837d9e53d38b3676bc0751dd5b255285a8961231a3588ac081682ed23` |
| `TECH_LOG_MINIMUM` | `BEFORE_TECH_LOG_MINIMUM.png` | `AFTER_TECH_LOG_MINIMUM.png` | 900x660pt | `2977a36e76bee737b38c2a73e71eddcd75b2a726118ea11a27cd9e9f905dc59c` |
| `TECH_LOG_POPULATED` | `BEFORE_TECH_LOG_POPULATED.png` | `AFTER_TECH_LOG_POPULATED.png` | 1120x760pt | `2f4e3cc470b78c6a079a985debd7b5ce89f300863139a1c354ab2693c68ab930` |
| `TRANSFER_COMPLETE` | `BEFORE_TRANSFER_COMPLETE.png` | `AFTER_TRANSFER_COMPLETE.png` | 1120x760pt | `7389fb7da83d0a838cf0753c35a61930f1e76d050d9c223827a80f1d596f785c` |
| `VERIFYING` | `BEFORE_VERIFYING.png` | `AFTER_VERIFYING.png` | 1120x760pt | `606b5de8e1cfe33f548cdf90aa58c5f13ca193510ddf08ada7a0ab5636cf3491` |

## Capture and comparison records

- `CAPTURE_BEFORE.log.gz`, `CAPTURE_AFTER.log.gz` — exact compressed capture records with state names, geometry, synthetic fixture safety boundary, and measured scroll extents; extract with `gzip -dc`.
- `capture_native.py`, `CaptureNative.swift` — reproducible temporary-source native capture harness.
- `FINAL_CROSS_SCREEN_GAP_MATRIX.md` — complete pre-edit audit matrix.
- `PATCH5_COMPARE_A.md` — every matrix row classified; Pass B decision.
- `FINAL_CROSS_SCREEN_COMPARE.md` — whole-app and minimum-window review.
- `FINAL_VISUAL_GAP_REPORT.md` — remaining gap classes and missing references.
- `CAPTURE_METHOD.md` — fixture isolation, geometry, appearance, and reproduction.
- `BEHAVIOR_REVIEW.md`, `SCOPE_GATE.md` — behavior/security and production scope gates.
- `CANONICAL_DEBUG_BUILD.log.gz` — exact compressed canonical Debug build output; extract with `gzip -dc`.
- `TRANSFER_CONTROLS_PRESENTATION_TEST.log.gz` — exact compressed focused terminal-state presentation result; extract with `gzip -dc`.
- `FULL_CANONICAL_TESTS.log.gz`, `FULL_CANONICAL_SUMMARY.json` — exact compressed output and structured result for one serial canonical test run; extract the log with `gzip -dc`.
- `VALIDATION.md` — exact commands, counts, and result bundle reference.

The BEFORE set includes the required nominal Ready, Copying, Verifying, Transfer Complete, Safe to Eject, Error, Cancelled, Notification, empty Technical Log, and populated Technical Log states. It also includes Ready/Notification/Technical Log minimum captures, minimum Safe to Eject/Error captures, Preparing, Manual Check Required, diagnostics-on, and bottom-scrolled Transfer/Notification minimum captures. Matching AFTER images exist for each.
