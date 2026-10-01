# OpenDesign Live Transfer Phase 1 — visual evidence for BRAIN

PROJECT_ID=988fea7b-beea-4916-a10e-5368a120417e
VISUAL_AUTHORITY=LIVE_OPEN_DESIGN_MCP
RUNTIME_AND_SAFETY_AUTHORITY=CANONICAL_FST_REPO
BRAIN_REVIEW_STATUS=PENDING
BRAIN_CLASSIFICATION=UNSET
ACCEPTED_STATE=UNSET
ACTIVE_NEXT=NONE
WORKER_PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_VISUAL_ADJUDICATION

This report classifies bounded regions, not whole-screen parity or acceptance. The live MCP source snapshots and selector/function map are in `LIVE_SOURCE_MAP.md` and `live-source/`. No design fixture telemetry, state machine, Telegram behavior or technical-log text was ported.

## Native before/after evidence

| State | Before | After | Concrete observed change |
|---|---|---|---|
| READY | BEFORE_READY.png | AFTER_READY.png | Separate tall cards become one flat route group. Setup becomes two columns. Job Status now exposes three equal hero slots with idle placeholders. Persistent footer added. |
| COPYING | BEFORE_COPYING.png | AFTER_COPYING.png | Before: phase metrics below the initial viewport. After: copy progress, phase ETA, current speed, thin track and secondary metrics visible at nominal geometry. |
| VERIFYING | BEFORE_VERIFYING.png | AFTER_VERIFYING.png | Before: verification metrics below the initial viewport. After: 62% synthetic verification fraction, Verify ETA, Verify Elapsed and amber phase text/track visible. No verification throughput. |
| SAFE TO EJECT | BEFORE_SAFE_TO_EJECT.png | AFTER_SAFE_TO_EJECT.png | Verified canonical terminal outcome remains explicit in the action region; Job Status now includes completed verify phase track. Secondary footer repeats the canonical outcome. |

All eight primary PNGs use the same native content geometry, 1120×760 points, 2240×1520 pixels, Dark Aqua. They are the actual NSHostingView bitmap of production SwiftUI in an NSWindow; no HTML renderer, compositing, screenshot reconstruction or browser image was substituted. Captures exclude the OS titlebar/traffic lights, so they do not establish native chrome pixel parity. BEFORE was captured at START_HEAD before production mutation; AFTER uses final production view bodies. Window construction/model injection lives only in temporary compilation units.

`capture_native.py` and `CaptureNative.swift` provide the exact recipe. Asset catalog is compiled into a disposable capture app. Null bookmarks, isolated defaults and empty token store prevent owner folder restoration or credential use. Empty UUID temp source/destination directories and synthetic metadata/runtime snapshots provide layout values; no transfer, verification or owner media is used. UUID path suffixes vary by run. Verify elapsed is displayed from the model (the canonical phase-start timer initializes it to 00:00 in these immediate captures); no elapsed sample is production evidence. Injected optional copy snapshots during verify/terminal are layout coverage only: production may clear them and then renders unavailable placeholders.

## Region comparison to final live CSS/JS

Each row has exactly one classification. MATCHED describes the named structure/token only.

| Region | Classification | Live reference and native observation |
|---|---|---|
| Dark shell surfaces | MATCHED | Final CSS root background #161a1f, surface #20252c, inset #11161c, raised #2a3038 and line #343c47 map to adaptive FSTPalette. |
| Outer geometry/chrome | REMAINING_VISUAL_GAP | OD max 1280×888 and drawn 32px titlebar differ from native 900×660 minimum/1120×760 nominal and OS-owned chrome. Preserve existing macOS resizing; content-only screenshots exclude titlebar. Safe for BRAIN/Owner adjudication; OS title rendering was not redesigned. |
| FST identity and social region | REMAINING_VISUAL_GAP | FST wordmark/divider and four existing native icons move left of tabs; OD includes a fifth LinkedIn icon. Existing asset/link inventory preserved. Safe for BRAIN/Owner adjudication; no new social capability introduced. |
| Tools signature | REMAINING_VISUAL_GAP | OD places CenVu D.I.T Tools at titlebar right; native places it in the secondary persistent footer. Leaves header compact at 900pt. Safe for BRAIN/Owner adjudication. |
| Three-tab shell | MATCHED | Existing TRANSFER/NOTIFICATION/TECHNICAL LOG actions retain the three-tab inset group, raised selected surface and log count. |
| Route composition | MATCHED | One flat surface contains horizontal Source and Destination rows with left role, center identity/path/facts, right native actions and thin separators. |
| Endpoint metadata density | REMAINING_VISUAL_GAP | OD puts name/facts on one summary line; native uses name, path, facts on separate lines and retains destination output preview. Preserves inspectability and every existing production fact at minimum width. Safe for BRAIN/Owner adjudication. |
| Full-path inspection | REMAINING_VISUAL_GAP | Native retains middle truncation, full-path tooltip/accessibility label and target preview; OD has an inspector/dialog. No new inspector added in this bounded convergence. Safe for BRAIN/Owner adjudication; full values remain inspectable. |
| Source volume/free/connection facts | BACKEND_CONSTRAINED | Current source metadata has folder/path/logical bytes/file/folder counts, not device free capacity or connection identity. Nothing fabricated. |
| Capacity section | SAFETY_OVERRIDE | OD Storage ready/estimated after copy is replaced by unchanged CAPACITY PRECHECK PASSED, Payload, Admission Floor, Available, Margin Above Floor and complete snapshot/uncertainty explanation. Additional height is required for canonical truth. |
| Setup row | MATCHED | Bandwidth and Verification read as one two-column setup row with labels, menu controls, helper text and bottom divider; configuration lock remains canonical. |
| Bandwidth values | MATCHED | Native uses canonical 50/75/100/125/150/175/200/Unlimited MB/s options. No conversion change. |
| Verification labels | SAFETY_OVERRIDE | Canonical COPY ONLY — Fastest / SAMPLE 33% — Balanced / FULL 100% — Maximum confidence labels and real algorithm descriptions remain; OD NONE wording is not imported. |
| Control strip structure | MATCHED | Explicit state/action separation, state icon/text, help and trailing native Start/Cancel/New Transfer/Retry action remain distinct from setup. Validation spinner and cancel confirmation are preserved. |
| Native control styling/type | REMAINING_VISUAL_GAP | OD blue filled start/red outlined cancel/36px controls and 14–16px body labels differ from system bordered buttons, native menu chrome and mostly 12–14pt utility labels. Native focus/keyboard behavior retained; critical hero values remain 28pt. Safe for BRAIN/Owner adjudication. |
| READY/COPYING presentation | MATCHED | Text-explicit canonical READY/SETUP REQUIRED and COPYING appear in control strip, Job Status and footer with neutral/active styling; no prototype readiness calculation used. |
| Job Status hero hierarchy | MATCHED | Three equal-width 28pt hero values, followed by 4pt phase progress, phase/help row, four flat secondary metrics and divided current item. Progress 45/62/100 is phase-specific, not combined workflow progress. |
| Verify third hero metric | BACKEND_CONSTRAINED | Backend exposes elapsed, not verification throughput. Verify Elapsed replaces OD Verification speed/512.8 MB/s. |
| ETA | BACKEND_CONSTRAINED | Existing Copy ETA/Verify ETA estimates are reused; no aggregate job ETA, fixture ETA or checked-file count inferred. Unknown/terminal estimates are placeholders. |
| Secondary duration/snapshots | BACKEND_CONSTRAINED | COPY ELAPSED replaces OD aggregate Job elapsed. Average copy speed/copied bytes/files read optional canonical snapshots; unavailable snapshots show placeholders, including when verify clears copy telemetry. |
| Current item | BACKEND_CONSTRAINED | Existing clip/sequence/verify-current-file presentation is reused. No fixture filename or missing verified-item telemetry imported; exact existing current filename remains in tooltip where present. |
| SAFE TO EJECT outcome | SAFETY_OVERRIDE | Only canonical safeToFormat maps to this green terminal wording and completed verify phase. No OD safeToEject function was ported. copyComplete remains TRANSFER COMPLETE; cancellation/error cannot display successful percent. |
| Inline warnings/error evidence | SAFETY_OVERRIDE | Real capacity warning and start blocker/report/error strings retained, including technical-detail disclosure and Open Technical Log. Prototype error/report content is excluded. |
| Persistent footer structure | MATCHED | Footer remains outside scrolling content and uses existing canonical state-title presentation plus Source protection · Read-only. No footer safety decision. |
| Footer rsync detail | REMAINING_VISUAL_GAP | OD footer may show unavailable-rsync text; native preserves existing setup blocker and Technical Log rsync detail instead of adding another footer alert. Safe for BRAIN/Owner adjudication; unavailable bundle still blocks Start. |
| Minimum viewport lower edge | REMAINING_VISUAL_GAP | In the 900×660 programmatic bottom-scroll capture, the current-item label sits partly at the footer boundary. Secondary metrics are reachable and critical actions/phase/hero values remain usable. Retain this capture limitation for BRAIN/Owner adjudication; no complete physical-scroll or VoiceOver audit is claimed. Full current-item help remains available. |
| Notification/Technical Log content | SAFETY_OVERRIDE | Canonical live functionality/content retained; prototype statuses/messages/log samples excluded. Only shared shell presentation changes. |
| PREPARING / VALIDATING | DESIGN_REFERENCE_MISSING_STATE | No dedicated visual reference artifact required by the task. Shared neutral/active shell, existing preparation message/spinner preserved; no new progress/safety semantics. |
| TRANSFER COMPLETE | DESIGN_REFERENCE_MISSING_STATE | No dedicated reference artifact. Existing copy-only text/blue role and canonical terminal action retained; never SAFE TO EJECT. |
| MANUAL CHECK REQUIRED | DESIGN_REFERENCE_MISSING_STATE | No dedicated reference artifact. Existing warning icon, backend reason, technical details and retry/log actions retained. |
| TRANSFER ERROR | DESIGN_REFERENCE_MISSING_STATE | No dedicated reference artifact. Existing error icon, backend reason and retry/log action retained. |
| CANCELLED | DESIGN_REFERENCE_MISSING_STATE | No dedicated reference artifact. Existing cancelled wording/icon/restart eligibility retained; unavailable progress and no success. |

## Functional/accessibility evidence

- Final Debug build and full canonical suite: PASS, 285 passed, 0 failed, 0 skipped. Focused state/runtime/capacity/bandwidth: PASS, 127 passed, 0 failed, 0 skipped. Full/default standalone TransferControlsLabelTests: PASS; includes new verify fraction, terminal copy/verified separation, cancellation/error unknown-progress and nonfinite-value checks.
- Existing standalone fixture had an operator Keychain dependency and stale logical-capacity assertion. Test-only fixes use an empty token store/isolated defaults, supply canonical capacity assessment and assert current preflight-floor wording. Production stores/policy unchanged.
- Both native source/destination picker buttons were clicked in the capture app. Each opened NSOpenPanel configured directories=true, files=false, createDirectories=false, then cancelled; no media selected or transfer started. Selection locks/drop callbacks/clear-only behavior remain unchanged in the reviewed diff.
- Notification and Technical Log tabs were clicked with local native NSEvents; `QA_NOTIFICATION.png` and `QA_TECHNICAL_LOG.png` show the switched native surfaces. No Telegram message or update-check request was sent.
- `MIN_DARK_*` captures verify 900×660 usability. Action strip, phase and hero values are visible; secondary runtime requires native scrolling. `MIN_DARK_SCROLLED.png` checks that lower content remains reachable with persistent footer.
- `LIGHT_*` captures verify semantic light readability with adaptive surfaces and darker state colors. Dark is primary; no separate Light Mode layout was added. State colors have explicit state text/icons. Thin progress is static SwiftUI presentation and does not require animation.
- Source/destination paths retain full-value accessibility labels/help; choose/clear controls have explicit role-specific accessibility labels. Native menu/button controls retain keyboard semantics. In-process AX enumeration exposed only part of SwiftUI's tree; this is not a complete VoiceOver audit. Picker/tab QA therefore used native mouse events, not incomplete AX traversal.

Manual production diff review: only seven View/presentation files changed; no ViewModel, engine, coordinator, filesystem, capacity formula, policy, rsync selection, verification, bandwidth conversion, privacy manifest, Telegram, report or report-safety edits. NotificationTabView/TerminalLogsView/FolderPicker/technical log content and behavior remain unchanged. No WebView or JavaScript runtime/state-machine port. All production values come from canonical model fields; synthetic numbers appear only in evidence fixture code/images.

Remaining visual gaps above are safe to return for BRAIN/Owner visual adjudication. Worker does not accept parity, classify BRAIN outcome or start Phase 2.
