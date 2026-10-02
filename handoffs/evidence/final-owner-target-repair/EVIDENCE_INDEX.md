# Evidence Index

TASK=FINAL_OWNER_TARGET_VISUAL_REPAIR
RESULT=IMPLEMENTATION_COMPLETE;BRAIN_REVIEW_PENDING

## Reports

- `FINAL_TARGET_COMPARISON.md` — row-by-row target/current comparison, including
  the intentional native titlebar variation.
- `BEHAVIOR_REVIEW.md` — clipboard, feed, update, filtering, localization, and
  safety behavior preservation.
- `VISUAL_QA.md` — EN/VI Dark Aqua capture matrix and minimum-width review.
- `CAPTURE_METHOD.md` — reproducible fixture and capture constraints.
- `VALIDATION.md` — exact build and focused/full test results.

## Required screenshots

- Technical Log: `EN_TECH_LOG.png`, `VI_TECH_LOG.png`.
- Technical Log minimum: `EN_TECH_LOG_MINIMUM.png`,
  `VI_TECH_LOG_MINIMUM.png`.
- Copy toast: `EN_COPY_TOAST.png`, `VI_COPY_TOAST.png`.
- Transfer Ready: `EN_TRANSFER_READY.png`, `VI_TRANSFER_READY.png`.
- Notification: `EN_NOTIFICATION.png`, `VI_NOTIFICATION.png`.

## Reproduction and local test artifacts

- `capture_native.py` and `CaptureNative.swift` are the synthetic capture
  harness.
- `CAPTURE_EN.log` and `CAPTURE_VI.log` contain per-fixture no-side-effect
  declarations as local ignored logs.
- Focused test result bundles and `CANONICAL_FINAL_POST_FOOTER.xcresult` are
  local ignored XCTest artifacts. The committed `VALIDATION.md` records exact
  counts; the source tests remain in `FishSockTransfer/Tests/XCTest/`.

## Owner reference context

- `handoffs/evidence/opendesign-live-transfer-p1/QA_TECHNICAL_LOG.png`
- `handoffs/evidence/opendesign-live-transfer-p1/QA_NOTIFICATION.png`
- `handoffs/evidence/visual-convergence-finalization/VISUAL_COMPARISON.md`
- `handoffs/evidence/visual-convergence-finalization/CAPTURE_METHOD.md`
- Prior EN/VI untranslated-string audit (reference only; not rerun in this
  bounded visual repair):
  `handoffs/evidence/localization-l2/FINAL_UNTRANSLATED_AUDIT.md`
