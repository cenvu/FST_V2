# FST EN/VI Localization L2 — Visual QA

TASK=FST_EN_VI_LOCALIZATION_L2_NOTIFICATION_LOGS_AUDIT
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION
APPEARANCE=DARK_AQUA
NOMINAL_CONTENT_SIZE=1120x760_POINTS;2240x1520_PNG
MINIMUM_CONTENT_SIZE=900x660_POINTS;1800x1320_PNG
SETTINGS_CONTENT_SIZE=500x240_POINTS;1000x480_PNG
FIXTURE=SYNTHETIC_ONLY
TRANSFER_STARTED=NO
TELEGRAM_SEND=NO
UPDATE_REQUEST=NO

All captures render the production SwiftUI views with an isolated ViewModel,
empty token store, synthetic source/destination labels, and the built String
Catalog resource. The Telegram test button was not clicked. The no-send service
traps if a send is attempted. The updater remains idle; update checks are
triggered only by the existing explicit button. The transfer controls were not
activated. Temporary fixture folders and capture build scratch were removed by
the harness.

## Required captures

| Surface | English | Vietnamese | Visual result |
|---|---|---|---|
| Notification, nominal | [EN_NOTIFICATION.png](EN_NOTIFICATION.png) | [VI_NOTIFICATION.png](VI_NOTIFICATION.png) | Titles, labels, status values, test action, pickers, and preview are visible. The Vietnamese message preview remains the English factory output. |
| Notification, minimum | [EN_NOTIFICATION_MINIMUM.png](EN_NOTIFICATION_MINIMUM.png) | [VI_NOTIFICATION_MINIMUM.png](VI_NOTIFICATION_MINIMUM.png) | Top sections remain readable; the view uses its existing scroll container for lower content. |
| Notification, minimum scrolled | [EN_NOTIFICATION_MINIMUM_SCROLLED.png](EN_NOTIFICATION_MINIMUM_SCROLLED.png) | [VI_NOTIFICATION_MINIMUM_SCROLLED.png](VI_NOTIFICATION_MINIMUM_SCROLLED.png) | Event toggles, heartbeat/detail pickers, status rows, raw synthetic error, and preview container are reachable without clipping. |
| Technical Log, empty | [EN_TECH_LOG_EMPTY.png](EN_TECH_LOG_EMPTY.png) | [VI_TECH_LOG_EMPTY.png](VI_TECH_LOG_EMPTY.png) | Empty-state text, title/toolbar, activity summary, metadata, and update action fit at nominal size. |
| Technical Log, populated | [EN_TECH_LOG_POPULATED.png](EN_TECH_LOG_POPULATED.png) | [VI_TECH_LOG_POPULATED.png](VI_TECH_LOG_POPULATED.png) | Synthetic timestamps, levels, category text, stderr, paths, and diagnostic message stay English and unchanged. |
| Technical Log, minimum | [EN_TECH_LOG_MINIMUM.png](EN_TECH_LOG_MINIMUM.png) | [VI_TECH_LOG_MINIMUM.png](VI_TECH_LOG_MINIMUM.png) | Title, toolbar, summary, populated log, metadata badges, and update action remain visible at 900×660. |
| Settings | [EN_SETTINGS.png](EN_SETTINGS.png) | [VI_SETTINGS.png](VI_SETTINGS.png) | General/Language strings switch through the catalog; `English` and `Tiếng Việt` remain stable endonyms. |
| Transfer regression | [EN_READY.png](EN_READY.png), [EN_SAFE_TO_EJECT.png](EN_SAFE_TO_EJECT.png) | [VI_READY.png](VI_READY.png), [VI_SAFE_TO_EJECT.png](VI_SAFE_TO_EJECT.png) | Representative L1 states render in both languages; READY and SAFE TO EJECT remain distinct. |

At 900×660, the notification top and lower areas are separate scroll positions;
the scrolled pair records access to the content below the fold. Technical Log
metadata/update controls fit without scrolling. Typography was not reduced.

There are 18 PNGs: the 16 required captures plus the two notification minimum
scrolled captures. Every capture line emitted by `capture_native.py` records
the content size and `transferStarted=NO notifySend=NO updateRequest=NO`.
