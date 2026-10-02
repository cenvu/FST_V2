# FST EN/VI Localization L2 — Evidence Index

TASK=FST_EN_VI_LOCALIZATION_L2_NOTIFICATION_LOGS_AUDIT
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION

| Evidence | Path | Contents |
|---|---|---|
| Pre-edit source inventory | `LOCALIZATION_L2_INVENTORY.md` | Candidate classification and authorized boundaries. |
| Whole-app untranslated audit | `FINAL_UNTRANSLATED_AUDIT.md` | Catalog counts, residual English classes, and zero missed UI strings. |
| Behavior review | `BEHAVIOR_REVIEW.md` | All eight required behavior-preservation assertions and evidence. |
| Visual QA | `VISUAL_QA.md` | Layout observations, capture constraints, screenshot links. |
| Validation | `VALIDATION.md` | Commands, exact XCTest totals, catalog/resource validation. |
| Scope gate | `SCOPE_GATE.md` | Production files changed and forbidden surfaces inspected. |
| Capture harness | `capture_native.py`, `CaptureNative.swift` | Reproducible synthetic native capture; empty token store and no-send trap. |
| Handoff | `handoffs/CURRENT_HANDOFF.md` | Worker status, raw report refs, review-pending state, one proposed next. |
| BRAIN transport | `~/Desktop/03_FST_BRAIN.md` | Exporter packet plus requested compact L2 evidence summary; repository remains canonical. |

## Screenshot files

- Notification: `EN_NOTIFICATION.png`, `VI_NOTIFICATION.png`,
  `EN_NOTIFICATION_MINIMUM.png`, `VI_NOTIFICATION_MINIMUM.png`,
  `EN_NOTIFICATION_MINIMUM_SCROLLED.png`,
  `VI_NOTIFICATION_MINIMUM_SCROLLED.png`.
- Technical Log empty: `EN_TECH_LOG_EMPTY.png`, `VI_TECH_LOG_EMPTY.png`.
- Technical Log populated: `EN_TECH_LOG_POPULATED.png`,
  `VI_TECH_LOG_POPULATED.png`.
- Technical Log minimum: `EN_TECH_LOG_MINIMUM.png`,
  `VI_TECH_LOG_MINIMUM.png`.
- Settings: `EN_SETTINGS.png`, `VI_SETTINGS.png`.
- Transfer regression: `EN_READY.png`, `VI_READY.png`,
  `EN_SAFE_TO_EJECT.png`, `VI_SAFE_TO_EJECT.png`.

## Local build products

Fresh full-suite xcresult and DerivedData are under `.build/` as listed in
`VALIDATION.md`. These build products are local verification artifacts, not
canonical source files. Repository screenshots and Markdown evidence are kept
under this evidence directory.
