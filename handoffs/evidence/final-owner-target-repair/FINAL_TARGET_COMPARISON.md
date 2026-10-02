# Final Owner Target Comparison

TASK=FINAL_OWNER_TARGET_VISUAL_REPAIR
WORKSTREAM_ID=OPENDESIGN_VISUAL_CONVERGENCE_P2
RESULT=IMPLEMENTATION_EVIDENCE;BRAIN_REVIEW_PENDING

The target is the Owner's final repair requirements supplied for this task,
reviewed alongside the checked-in Owner reference screenshots in
`handoffs/evidence/opendesign-live-transfer-p1/QA_TECHNICAL_LOG.png` and
`QA_NOTIFICATION.png`. No live OpenDesign read was required. Production truth
and the accepted copy/log behavior remain authoritative where screenshots are
ambiguous.

| Area | TARGET | CURRENT_AFTER | MATCH | INTENTIONAL_NATIVE_VARIATION | PRODUCT_TRUTH_OVERRIDE |
|---|---|---|---|---|---|
| Technical Log title row | Title left; truthful operational subtitle right on one row | `Technical Log` / localized equivalent and operational subtitle share a first-baseline HStack | YES | NO | NO |
| Show Diagnostics placement | First, on the left side of the action row | Remains left of Auto-scroll | YES | NO | NO |
| Auto-scroll placement | Beside Show Diagnostics on the left | Remains beside Show Diagnostics; user toggle state is retained | YES | NO | NO |
| Copy All Logs button | Text-only bordered action on the right | Text-only bordered button; same full retained-log clipboard operation | YES | NO | NO |
| Log details button | Text-only bordered action on the right | Text-only bordered button; same complete selectable history sheet | YES | NO | NO |
| Check for Update button | Text-only bordered action on the right | Text-only bordered button; production update callback and copy/verify disablement retained | YES | NO | NO |
| Button icon presence | No icons on idle toolbar action buttons | No idle action icons; success/warning glyph is confined to the toast | YES | NO | NO |
| Copy confirmation presentation | Compact, transient, nonblocking toast/HUD | Rounded material overlay at the log surface's top trailing edge; 2.8-second generation-scoped timeout; EN/VI success and failure | YES | NO | NO |
| Log feed geometry | Copy confirmation must not consume a row or move the feed | Toast is a SwiftUI overlay and contributes no VStack layout height; feed view and log formatting are unchanged | YES | NO | NO |
| Visible/total line | Keep visible and total entry counts | Existing localized visible/total summary remains below the feed | YES | NO | NO |
| Footer left grouping | Canonical state title and short canonical subtitle | `stateTitle` and `stateSubtitle` from `TransferControlsActionPresentation`; subtitle uses the same state/canStartTransfer truth and existing localized strings | YES | NO | NO |
| Footer right source-protection grouping | Source protection · Read-only at the right | Localized source-protection label is right-aligned | YES | NO | NO |
| Obsolete metadata absence | Do not restore version, bundled-rsync, or license rows | Those metadata rows remain absent | YES | NO | NO |
| EN/VI minimum-width behavior | Keep title, action row, feed summary, and footer readable at 900×660 | Both 900×660 screenshots show the complete header/action row and footer without critical clipping | YES | NO | NO |
| Native titlebar CenVu position | Move the brand only if a safe existing titlebar mechanism exists | No AppKit titlebar mutation was introduced; the operational footer has no CenVu brand row | INTENTIONAL_NATIVE_VARIATION | YES — `NATIVE_TITLEBAR_CENVU_POSITION=INTENTIONAL_NATIVE_VARIATION` | NO |
| Unsafe mockup-only wording | Preserve production capacity and status truth | No “Storage ready”, estimated-after-copy, or prototype transfer claims were added | YES | NO | NO |
| Idle update status | No secondary status row while update state is idle | `updateStatus` is rendered only for non-idle states; capture does not fake an update result | YES | NO | NO |

No numeric similarity score is claimed.
