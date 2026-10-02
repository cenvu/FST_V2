# Visual QA

TASK=FINAL_OWNER_TARGET_VISUAL_REPAIR
APPEARANCE=Dark Aqua
FIXTURES=SYNTHETIC_ONLY

## Captures

| Capture | Window size | PNG size | Review |
|---|---:|---:|---|
| `EN_TECH_LOG.png`, `VI_TECH_LOG.png` | 1120×760 pt | 2240×1520 px | One-row title/subtitle, text-only action row, populated synthetic log feed, visible/total line, canonical footer grouping |
| `EN_TECH_LOG_MINIMUM.png`, `VI_TECH_LOG_MINIMUM.png` | 900×660 pt | 1800×1320 px | Title, subtitle, both left controls, all three actions, summary, and two-part footer remain readable |
| `EN_COPY_TOAST.png`, `VI_COPY_TOAST.png` | 1120×760 pt | 2240×1520 px | Rounded native material success toast overlays the feed at top trailing; it does not add a row or move the feed |
| `EN_TRANSFER_READY.png`, `VI_TRANSFER_READY.png` | 1120×760 pt | 2240×1520 px | Ready state and canonical footer subtitle remain aligned; production capacity vocabulary is retained |
| `EN_NOTIFICATION.png`, `VI_NOTIFICATION.png` | 1120×760 pt | 2240×1520 px | Notification shell still renders; no token is present and the outbound preview remains its production English body |

The Vietnamese minimum Technical Log footer shows `CẦN THIẾT LẬP` with the
localized `Hoàn tất thiết lập sao chép.` subtitle. Long toast text wraps inside
its compact rounded surface without clipping. English and Vietnamese action
labels remain fully visible at minimum width.

The toast screenshot seeds the success presentation state in the capture-only
initializer. The actual clipboard-to-feedback mapping and repeated-click timer
generation are covered by focused XCTest. No failure toast screenshot was
requested; the failure state is covered by that test.

## No side effects during capture

The capture log reports `transferStarted=NO notifySend=NO updateRequest=NO`
for every fixture. Notification sending is guarded by a fixture service that
fails if called; no token is loaded or shown. Update controls remain idle and
are not clicked. Source/destination paths and log entries are synthetic.
