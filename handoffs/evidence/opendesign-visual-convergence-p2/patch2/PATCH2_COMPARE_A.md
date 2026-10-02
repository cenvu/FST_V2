# Patch 2 — Pass A comparison

IMPLEMENTATION_PASS=A
BUILD=PASS (`BUILD SUCCEEDED`)
GEOMETRY=1120x760 nominal content points;2240x1520 native pixels;Dark Aqua
CAPTURE_SET=AFTER_READY.png;AFTER_COPYING.png;AFTER_VERIFYING.png;AFTER_SAFE_TO_EJECT.png;AFTER_ERROR.png
COMPARISON=BEFORE_*.png captured from START_HEAD and AFTER_*.png captured from Pass A at the same content geometry.

| REGION | CLASSIFICATION | PASS A OBSERVATION |
|---|---|---|
| Source and Destination rows | IMPROVED_BUT_REMAINING | Existing facts now share the identity line, the role column remains 88pt, the long path remains inspectable, and Destination target preview remains visible. Row height decreased. The 14pt uppercase `DESTINATION` label wraps into two lines in all five captures, so the role column does not yet match the live title-case 88px role label. |
| Capacity | SAFETY_OVERRIDE | Four required values and the canonical APFS snapshot/overhead explanation remain. Reduced vertical padding and the spacing between status, supporting text, and values make the block shorter. A one-line OpenDesign readiness row would omit required capacity truth, so the additional height remains. |
| Transfer setup | MATCHED | The columns now use the reference 1:1.6 Bandwidth-to-Verification ratio. Labels, native menu controls, and helper text align as one setup region; canonical bandwidth and verification choices/descriptions are unchanged. |
| Control strip layout and actions | IMPROVED_BUT_REMAINING | READY uses a filled blue native action. SAFE TO EJECT and generic error use the live success/error surface colors. Error Retry and Open Technical Log now share a trailing row, with Retry first. The COPYING/VERIFYING Cancel action still renders as a neutral gray native button, so its error tint does not visibly match OpenDesign’s red outlined cancel treatment. A small SwiftUI styling adjustment can safely correct both remaining view-only details. |
| Job Status header and hero metrics | MATCHED | The three columns remain equal; numeric hero metrics retain 28pt, long ETA values use the smaller 20pt scale, and label/value spacing is tighter. COPY progress/ETA/current speed and VERIFY progress/ETA/elapsed remain sourced from current model fields. |
| Phase progress and status line | SAFETY_OVERRIDE | The track remains 4pt and the line below it uses canonical phase/status text. READY remains at its existing zero-progress presentation. ERROR continues to show no phase percentage, ETA, speed, or file counts. No OpenDesign fixture phase or verification-count semantics were added. |
| Secondary metrics and current item | BACKEND_CONSTRAINED | The four equal secondary columns, dividers, and separate current-item line remain. Pass A softens label weight and spacing. Values use the copy runtime snapshot and show unavailable placeholders when it is absent. |
| Verify hero telemetry | BACKEND_CONSTRAINED | VERIFYING shows its existing observed 62% sample, supported ETA, and `VERIFY ELAPSED`. No verification throughput was added. |
| Error outcome and telemetry | SAFETY_OVERRIDE | The established `TRANSFER ERROR: rsync failed.` operator text remains. The error capture has em dashes for phase progress, ETA, current speed, copy metrics, and current item. Retry remains enabled only through the existing canonical readiness projection; no action closure or enablement condition changed. |

## Pass B decision

PASS_B_REQUIRED=YES
REASON=The role label wrapping and visually neutral active Cancel button are specific, material visual gaps that can be corrected within the authorized Transfer presentation views without changing actions or state.
BOUNDED_REFINEMENT=Change endpoint role labels to the live title case while keeping the 88pt column; give the existing active Cancel button its red outline/tint using a native SwiftUI Button. No other Pass B edits are planned.

The first Pass A capture invocation saved all five required state images, then
failed while the copied Patch 1 script tried an unneeded optional minimum-size
capture without the Patch 2 rsync argument. That attempt is preserved as
`CAPTURE_PASS_A_INITIAL_ATTEMPT.log`. The script was narrowed to the five
requested states and the successful recapture is in `CAPTURE_PASS_A.log`.
