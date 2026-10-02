# Patch 2 — Pass B comparison

IMPLEMENTATION_PASS=B
GEOMETRY=1120x760 nominal content points;2240x1520 native pixels;Dark Aqua
FINAL_CAPTURE_SET=AFTER_READY.png;AFTER_COPYING.png;AFTER_VERIFYING.png;AFTER_SAFE_TO_EJECT.png;AFTER_ERROR.png
PASS_A_CAPTURE_SET=PASS_A_READY.png;PASS_A_COPYING.png;PASS_A_VERIFYING.png;PASS_A_SAFE_TO_EJECT.png;PASS_A_ERROR.png
BUILD=PASS (Pass A canonical Debug build succeeded; final canonical build/test follows)

| REGION | CLASSIFICATION | PASS B OBSERVATION |
|---|---|---|
| Source and Destination rows | MATCHED | `Source` and `Destination` now fit on one line in the fixed 88pt role column. Identity and existing labeled facts share a summary line; monospaced paths, right-aligned actions, and the Destination target preview remain. Source and Destination rows are shorter than their pre-edit captures. |
| Capacity | SAFETY_OVERRIDE | The capacity block is more compact. `CAPACITY PRECHECK PASSED`, Payload, Admission Floor, Available, Margin Above Floor, and the current APFS floor/overhead explanation remain. Snapshot-not-reservation, APFS/exFAT uncertainty, and necessary-floor-not-fit-guarantee wording remain available through the existing supporting text/help path. The block stays taller than OpenDesign’s simplified readiness row because its safety evidence is required. |
| Transfer setup | MATCHED | Native Bandwidth and Verification controls use the reference 1:1.6 column ratio, aligned labels/controls/helpers, and canonical options and descriptions. |
| Control strip layout and actions | INTENTIONAL_NATIVE_VARIATION | READY/terminal primary actions are blue native SwiftUI buttons. Existing error actions share one trailing row, primary Retry first. COPYING/VERIFYING Cancel has a red outline while retaining the native white label and native control fill; this is the remaining system-control rendering variation. Title/subtitle hierarchy and success/error backgrounds follow the design tokens. Button callbacks, confirmation, enablement, retry, and new-transfer logic are unchanged. |
| Job Status header and hero metrics | MATCHED | Header/state indicator, equal three-column metrics, 28pt numeric heroes, reduced long ETA scale, and label/value spacing now follow the reference rhythm. |
| Phase progress and status line | SAFETY_OVERRIDE | The native 4pt phase track and canonical status line remain. Error progress stays unavailable. No fixture counts, stopped progress, or extra phase telemetry are added. |
| Secondary metrics and current item | BACKEND_CONSTRAINED | Four equal columns, separators, and current-item row match the structure. Copy metrics use actual `CopyRuntimeSnapshot` fields; unknown values remain unavailable. |
| Verify hero telemetry | BACKEND_CONSTRAINED | Verify progress and supported ETA remain model-derived. `VERIFY ELAPSED` occupies the third hero; no verification throughput is fabricated. |
| Error outcome and telemetry | SAFETY_OVERRIDE | The existing `TRANSFER ERROR: rsync failed.` fixture wording remains intact and all unavailable telemetry fields render as em dashes. Real production errors continue to use canonical operator text and retry eligibility. |

## Remaining gap and review boundary

REMAINING_VISUAL_GAP=No material visual-only gap was identified in the audited Patch 2 regions after the one bounded refinement. Remaining differences are the required capacity explanation/values, backend-limited telemetry, and native Aqua button rendering described above.
VISUAL_PARITY_ACCEPTANCE=NOT_SELF_ACCEPTED
PATCH_3_NOTIFICATION_NOT_STARTED=YES
PATCH_4_TECHNICAL_LOG_NOT_STARTED=YES
PATCH_5_POLISH_NOT_STARTED=YES
