# Patch 3 final visual evidence

WORKSTREAM_ID=OPENDESIGN_VISUAL_CONVERGENCE_P2
PHASE=PATCH_3_NOTIFICATION
DESIGN_AUTHORITY=CANONICAL_FROZEN_SOURCE_MAP
LIVE_MCP_REQUIRED=NO
LIVE_VS_FROZEN_DIFF=UNKNOWN
FIXTURE_SEMANTICS_COPIED=NO
IMPLEMENTATION_PASSES=1
PASS_B_NOT_REQUIRED=YES
REASON=Structural targets implemented; remaining differences are bounded native presentation, truthful production content, and safe vertical scrolling. No material correctable visual-only gap identified.
BRAIN_REVIEW_STATUS=PENDING
VISUAL_PARITY_ACCEPTANCE=UNSET

| Region | Final worker observation | Classification | Evidence |
|---|---|---|---|
| Intro | 20 semibold title, 14 muted kicker; compact row retained despite selected-tab repetition because it adds safety context | MATCHED / INTENTIONAL_NATIVE_VARIATION | AFTER_NOTIFICATION.png |
| Telegram Setup | Left upper flat section, 16pt padding, 4pt radius, semantic 1pt border; labels above 36pt secure/native fields | MATCHED / INTENTIONAL_NATIVE_VARIATION | AFTER_NOTIFICATION.png; AFTER_NOTIFICATION_CONFIGURED.png |
| Test/helper | Real callback/disable preserved; existing full production safety copy stays below native button; no prototype validation | SAFETY_OVERRIDE / INTENTIONAL_NATIVE_VARIATION | PATCH3_PRODUCTION_REVIEWED.diff |
| Events/options | Single left lower section, five checkboxes; native menu pickers inside 1:1.4 local tracks, enums unchanged | MATCHED / INTENTIONAL_NATIVE_VARIATION | AFTER_NOTIFICATION_MINIMUM_SCROLLED.png |
| Status | Four vertical label/value rows, 16/4 rhythm, 14/16 type; real values, '-' fallback; Error and nonnil error summary emphasized | MATCHED / BACKEND_CONSTRAINED / SAFETY_OVERRIDE | AFTER_NOTIFICATION.png; AFTER_NOTIFICATION_LONG_ERROR.png |
| Preview | Right lower section with 16/4/1 inset, mono16, 6pt added line spacing, wrapping and selection; real factory content | MATCHED / BACKEND_CONSTRAINED | AFTER_NOTIFICATION.png; AFTER_NOTIFICATION_MINIMUM_SCROLLED.png |
| Container | Top-aligned 1.5:1 columns, gap16, same-column gap16; outer 12/24/16 padding; scrolling covers full document | MATCHED / INTENTIONAL_NATIVE_VARIATION | All primary AFTER images plus scrolled variants |

Remaining native differences: checkbox glyph/text gap and accent drawing are AppKit-controlled; native popup/button chrome and intrinsic control heights differ from CSS despite 36pt minimum frames; SF line metrics and system .footnote sizing differ from web typography. Outer horizontal padding remains 24pt even at 900 (web uses 16 below 1023). No single-column breakpoint introduced.

Production truth differences are preserved deliberately: Disabled/Enabled, Not Tested, factory-derived No messages sent, '-' missing error, and factory preview at Copying/42% with Standard timing. No prototype string is hard-coded into the production view. Status two-line truncation was removed to meet the task's inspectability requirement; full text wraps, can be selected, and has a help value. Long runtime errors expand the right column and stay scrollable.

At nominal dimensions the lower card border needs 24pt scroll; at minimum, options and preview timing require 137pt scroll. Supplemental bottom captures show them fully. This preserves readable type/control sizes and source geometry. Captures prove rendering/scroll reachability, not live Telegram delivery. No live send was performed. BRAIN must review the images and adjudicate convergence; Worker does not accept visual parity.

Production changed path: `FishSockTransfer/FishSockTransfer/Views/NotificationTabView.swift` only. Patch 1/2 bytes retained; Patch 4 Technical Log and Patch 5 polish not started. Details: NOTIFICATION_GAP_MATRIX.md, PATCH3_COMPARE_A.md, CAPTURE_METHOD.md, VALIDATION.md, PATCH3_PRODUCTION_REVIEWED.diff, BEHAVIOR_SCOPE_CHECK.json.
