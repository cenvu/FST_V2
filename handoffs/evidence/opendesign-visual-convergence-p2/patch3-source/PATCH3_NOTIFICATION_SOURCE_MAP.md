# Patch 3 — Notification design source map

TASK=OPENDESIGN_P2_PATCH3_NOTIFICATION_LIVE_SOURCE_CAPTURE
WORKSTREAM_ID=OPENDESIGN_VISUAL_CONVERGENCE_P2
CLASS=READ_ONLY_DESIGN_AUTHORITY_CAPTURE
LIVE_SOURCE_READ=NO
DESIGN_AUTHORITY=frozen snapshot `handoffs/evidence/opendesign-live-transfer-p1/live-source/`
AUTHORITY_SHA256_INDEX=b70202cafe7eb1e5503ee7c7178dc1ab80e1266e2078f1b3576b0adb899fb9e8
AUTHORITY_SHA256_CSS=a6170ef2c70fc770440271640b172f5b6fa0c44684d5dcea9d5bf2596dc3f8e5
AUTHORITY_SHA256_JS=aaa3bd496796890c63d42190ac8ad333ab4c299c5cf7530085aa85a9ba132a66
SOURCE_STATE=READ_ONLY_CAPTURE;NO_PRODUCTION_SWIFT_MUTATION;NO_PATCH3_IMPLEMENTATION

All line numbers below are line numbers in the frozen snapshot files.

---

## 1. Renderer entry points

| Function / helper | File:line | Role |
|---|---|---|
| `notificationSurface()` | `assets/fst-c.js:252-261` | Builds the whole NOTIFICATION tab DOM |
| `checkbox(key,label)` | `assets/fst-c.js:251` | Emits one `<label class="check-row">` with `<input type="checkbox" data-notify>` |
| `metadataRow(label,value,mono)` | `assets/fst-c.js:230` | Emits `<div class="od-field"><dt>..</dt><dd>..</dd></div>` |
| `notificationPreview()` | `assets/fst-c.js:244-249` | Returns the fixture message-preview text |
| `errorMarkup(key)` | `assets/fst-c.js:250` | Emits `<span class="field-error" id="<key>-error">` |
| `testMessage()` | `assets/fst-c.js:375-381` | Fixture-only local preview simulation |
| `validateNotify(key)` | `assets/fst-c.js:363-374` | Fixture-only token/chatID validation |
| render dispatch | `assets/fst-c.js:292` | `model.tab==='notification'?notificationSurface():...` |
| tab keyboard order | `assets/fst-c.js:428` | `['transfer','notification','logs']` |
| tab button | `index.html:100` | `<button id="tab-notification" data-tab="notification">NOTIFICATION</button>` |
| notification model | `assets/fst-c.js:37-38` | `notification:{enabled,token,chatID,interval,detail,job,heartbeat,fail,copy,verify}`, `formErrors:{}`, `testing:false`, `lastPreview:'No messages sent'` |

---

## 2. Exact Notification DOM skeleton

From `assets/fst-c.js:254-260`:

```text
section.tab-surface[role=tabpanel][aria-labelledby=tab-notification]
├── div.surface-intro
│   ├── h1                      "Notifications"
│   └── span.section-kicker     "Optional · best-effort · separate from job safety"
└── div.notification-layout                         ← 1.5fr / 1fr grid
    ├── div                                           ← LEFT column wrapper
    │   ├── section.settings-section
    │   │   ├── h2                 "Telegram setup"
    │   │   ├── p.caption          "Notification delivery never changes transfer or verification results."
    │   │   ├── label.check-row    "Enable Telegram notification"  (data-notify=enabled)
    │   │   └── form#notification-form[novalidate]
    │   │       ├── div.form-summary[role=alert]      (only when model.formErrors non-empty)
    │   │       │   └── a[href="#<key>"]              per error
    │   │       └── div.settings-fields               ← 16px vertical grid
    │   │           ├── div.field
    │   │           │   ├── label[for=token]          "Bot token" + " · required" when enabled
    │   │           │   ├── input#token[type=password][autocomplete=off]
    │   │           │   └── span#token-error.field-error   (conditional)
    │   │           ├── div.field
    │   │           │   ├── label[for=chatID]         "Chat ID" + " · required" when enabled
    │   │           │   ├── input#chatID[type=text][autocomplete=off]
    │   │           │   └── span#chatID-error.field-error   (conditional)
    │   │           └── div
    │   │               ├── button[data-action=test-message].button.ghost  "Test message"
    │   │               │     ("Generating preview…" while model.testing, then disabled)
    │   │               ├── div.loading-track[aria-label="Generating local message preview"]
    │   │               └── p.field-hint   "This visual prototype generates a local preview. No message is sent."
    │   └── section.settings-section                 ← gap to previous = 16px (`.settings-section + .settings-section`)
    │       ├── h2                 "Notify events"
    │       ├── label.check-row    "Job starts"                    (data-notify=job)
    │       ├── label.check-row    "Heartbeat while running"       (data-notify=heartbeat)
    │       ├── label.check-row    "Transfer fails"                (data-notify=fail)
    │       ├── label.check-row    "Copy completed"                (data-notify=copy)
    │       ├── label.check-row    "Verify completed / Safe to eject" (data-notify=verify)
    │       └── div.setup                                ← nested 2-up field grid
    │           ├── div.field
    │           │   ├── label[for=heartbeat-interval]  "Heartbeat interval"
    │           │   └── select#heartbeat-interval      options "15 minutes" / "30 minutes"
    │           └── div.field
    │               ├── label[for=message-detail]     "Message detail"
    │               └── select#message-detail         options "Compact" / "Standard"
    └── div                                           ← RIGHT column wrapper
        ├── section.settings-section
        │   ├── h2                 "Notification status"
        │   └── dl.metadata.status-list
        │       ├── od-field: dt "Telegram"   dd "Enabled in preview" | "Disabled"
        │       ├── od-field: dt "Connection" dd "Not tested"
        │       ├── od-field: dt "Last message" dd model.lastPreview
        │       └── od-field: dt "Last error"  dd joined formErrors | "None"
        └── section.settings-section                 ← gap to previous = 16px
            ├── h2                 "Message preview"
            └── pre.message-preview#message-preview   ← notificationPreview()
```

Structural facts:

- `notification-layout` children are two bare `<div>` column wrappers, not
  `.settings-section` directly. Column gap is the grid `gap`.
- Left column stacks `Telegram setup` then `Notify events` with
  `.settings-section + .settings-section { margin-top: 16px }`.
- Right column stacks `Notification status` then `Message preview` with the
  same 16px `margin-top`.
- Notify Events and Message Detail live in the LEFT column. Notification Status
  and Message Preview live in the RIGHT column.

### `notificationPreview()` exact output (`assets/fst-c.js:244-249`)

```text
FST heartbeat
Source: <model.source.name | "Source">
Destination: <model.destination.name | "Destination">
Phase: <statePresentation().title>
Progress: <model.progress>%
[if detail === 'Standard']
Elapsed: <mm:ss | h:mm:ss>
ETA: <model.eta>          ← only when model.eta truthy
```

---

## 3. CSS selectors and exact tokens

File: `assets/fst-c.css`. Base tokens from `:root` lines 1-43, then the
approved "C refinement v2" override block at line 323:

```css
:root {--radius:4px;--stage:#101318;--line:#343c47;--control-height:36px;--section-gap:8px;}
```

### 3.1 Resolved token values used by Notification

| Token | Base (`:root`) | After C refinement v2 (line 323) | Value used |
|---|---|---|---|
| `--radius` | `8px` (line 29) | `4px` | **4px** |
| `--line` | `#3b434f` (line 10) | `#343c47` | **#343c47** |
| `--control-radius` | `4px` (line 30) | unchanged | **4px** |
| `--control-height` | not defined | `36px` | **36px** |
| `--s1..s4,s6,s8` | 4/8/12/16/24/32px (lines 23-28) | unchanged | 4/8/12/16/24/32px |
| `--gap` grid (`--s4`) | 16px | unchanged | **16px** |
| `--surface` | `#20252c` (line 5) | unchanged (hybrid) | **#20252c** |
| `--inset` | `#11161c` (line 6) | unchanged (hybrid) | **#11161c** |
| `--bg` | `#161a1f` (line 4) | unchanged (hybrid) | **#161a1f** |
| `--text` | `#edf1f6` (line 8) | unchanged | **#edf1f6** |
| `--muted` | `#a7b1bd` (line 9) | unchanged | **#a7b1bd** |
| `--blue` | `#7ab6ff` (line 11) | unchanged | **#7ab6ff** |
| `--red` | `#ff9094` (line 16) | unchanged | **#ff9094** |
| `--body` | `16px` (line 19) | unchanged | **16px** |
| `--label` | `14px` (line 20) | unchanged | **14px** |
| `--title` | `20px` (line 21) | unchanged | **20px** |
| `--mono` | `SFMono-Regular, Menlo, Monaco, monospace` (line 18) | unchanged | SF Mono stack |

Note `body[data-direction='native']` (lines 44-47) and
`body[data-direction='cinema']` (lines 48-52) retune `--bg/--surface/--inset/
--raised/--muted/--line/--radius`. The frozen `index.html:67` sets
`<body data-direction="hybrid">`, so the base `:root` values plus the C
refinement override are the values in force.

### 3.2 Notification-specific selectors

| Selector | File:line | Exact declaration |
|---|---|---|
| `.notification-layout` | `fst-c.css:210` | `display:grid; grid-template-columns: minmax(0,1.5fr) minmax(0,1fr); gap: var(--s4); align-items:start;` |
| `.settings-section` | `fst-c.css:211` | `padding: var(--s4); border: 1px solid var(--line); background: var(--surface); border-radius: var(--radius);` |
| `.settings-section h2` | `fst-c.css:212` | `margin-bottom: var(--s4);` |
| `.settings-section + .settings-section` | `fst-c.css:213` | `margin-top: var(--s4);` |
| `.settings-fields` | `fst-c.css:214` | `display:grid; gap: var(--s4);` |
| `.check-row` | `fst-c.css:215` | `display:flex; align-items:flex-start; gap: var(--s3); padding-block: var(--s2); cursor:pointer;` |
| `input[type='checkbox']` | `fst-c.css:216` | `margin: var(--s1) 0 0; width:16px; height:16px; accent-color: var(--blue); flex:none;` |
| `.field-error` | `fst-c.css:217` | `color: var(--red); display:block; margin-top: var(--s1);` |
| `.form-summary` | `fst-c.css:218` | `display:grid; gap:var(--s1); padding:var(--s3); border:1px solid var(--red); border-radius:var(--control-radius); margin-bottom:var(--s3);` |
| `.message-preview` | `fst-c.css:219` | `white-space:pre-wrap; overflow-wrap:anywhere; margin:0; padding:var(--s4); border:1px solid var(--line); border-radius:var(--control-radius); background:var(--inset); font: var(--body)/1.6 var(--mono);` |
| `.status-list` | `fst-c.css:220` | `display:grid; gap: var(--s4);` |
| `.surface-intro` | `fst-c.css:115` | `display:flex; align-items:center; justify-content:space-between; gap:var(--s4); margin-bottom:var(--s4);` |
| `.section-kicker` | `fst-c.css:116` | `color:var(--muted); font-size:var(--label);` |
| `.caption` | `fst-c.css:73` | `font-size:var(--label); color:var(--muted);` |
| `.tab-surface` (base) | `fst-c.css:114` | `padding: var(--s4) var(--s6) var(--s6);` = 16/24/24 |
| `.tab-surface` (C ref.) | `fst-c.css:330` | `padding: var(--s3) var(--s6) var(--s4);` = **12/24/16** ← in force |
| `.setup` (nested 2-up) | `fst-c.css:142` | `display:grid; grid-template-columns:1fr 1.4fr; gap:var(--s4); padding:var(--s3) var(--s4); background:var(--surface); border:1px solid var(--line); border-radius:var(--radius);` |
| `.field label` (base) | `fst-c.css:143` | `display:block; color:var(--muted); font-size:var(--label); margin-bottom:var(--s1);` |
| `.field` / `.field label` (C ref.) | `fst-c.css:352-353` | `.field{--od-gap:0px;} .field label{font-weight:500;}` |
| `.field-hint` | `fst-c.css:144` | `display:block; color:var(--muted); font-size:var(--label); margin-top:var(--s1);` |
| `select,input[type='text'],input[type='password']` (base) | `fst-c.css:145` | `display:block; width:100%; min-height:40px; padding:var(--s2) var(--s3); border:1px solid var(--line); border-radius:var(--control-radius); color:var(--text); background:var(--inset);` |
| same (C ref.) | `fst-c.css:354` | `min-height:var(--control-height); padding-block:var(--s1);` → **min-height 36px, padding-block 4px, padding-inline 12px** |
| `.button` (base) | `fst-c.css:133` | `display:inline-flex; align-items:center; justify-content:center; gap:var(--s2); min-height:40px; padding:var(--s2) var(--s3); border:1px solid var(--line); background:var(--raised); border-radius:var(--control-radius); font-weight:550;` |
| `.button` (C ref.) | `fst-c.css:341` | `min-height:var(--control-height); padding:var(--s1) var(--s3); font-size:var(--body); font-weight:500;` → **36px / 4px 12px / 16px / 500** |
| `.button.ghost` | `fst-c.css:135` | `background: transparent;` |
| `.loading-track` | `fst-c.css:245-246` | `height:4px; background:var(--line); border-radius:var(--control-radius);` + animated `::after` |
| `.metadata dt` | `fst-c.css:198` | `color:var(--muted); font-size:var(--label);` |
| `.metadata dd` | `fst-c.css:199` | `margin:0; overflow-wrap:anywhere; font-size:var(--body);` |
| `.metadata .od-field` | `fst-c.css:197` | `--od-gap:4px;` |
| `.od-field` (layout primitive) | `index.html:25` | `display:grid; gap:var(--od-gap,2px);` children `display:block` |
| `h1` | `fst-c.css:67` | `font-size:var(--title); line-height:1.3; font-weight:650; letter-spacing:-.02em;` |
| `h2,h3` | `fst-c.css:68` | `font-size:var(--body); font-weight:650;` |

### 3.3 Resolved Notification geometry/tokens (what a SwiftUI target should hit)

| Datum | Value |
|---|---|
| Column ratio | `minmax(0,1.5fr) / minmax(0,1fr)` = 60% / 40% of track |
| Column gap | 16px (`--s4`) |
| Column alignment | `align-items: start` (top aligned, no stretch) |
| Outer tab-surface padding | 12px top / 24px left-right / 16px bottom |
| Section padding | 16px all sides (`--s4`) |
| Section radius | 4px (`--radius` after refinement) |
| Section border | 1px solid `#343c47` |
| Section background | `#20252c` (`--surface`) |
| Section-to-section gap (same column) | 16px `margin-top` |
| Heading-to-content gap | 16px `margin-bottom` on `.settings-section h2` |
| Field stack gap (`.settings-fields`) | 16px |
| Label → control gap | 4px (`--s1`) |
| Control height | 36px (`--control-height`) |
| Control radius | 4px (`--control-radius`) |
| Control background | `#11161c` (`--inset`) |
| Control border | 1px solid `#343c47` |
| Checkbox size | 16×16, `margin-top:4px`, accent `#7ab6ff` |
| Check row gap | 12px (`--s3`), `padding-block:8px` |
| Status list gap | 16px between rows |
| Status label/value intra gap | 4px (`.metadata .od-field {--od-gap:4px}`) |
| Status label | 14px, `#a7b1bd` |
| Status value | 16px, `#edf1f6` |
| Message preview padding | 16px |
| Message preview radius | 4px |
| Message preview border | 1px solid `#343c47` |
| Message preview background | `#11161c` |
| Message preview font | `16px/1.6` SF Mono, `pre-wrap` + `overflow-wrap:anywhere` |
| Section heading size | `h2` = 16px / 650 |
| Surface heading | `h1` = 20px / 650 / `-0.02em` |
| Kicker / caption / label | 14px, `#a7b1bd` |
| Body | 16px / 1.5 |
| Form summary | 12px padding, 1px `#ff9094` border, 4px radius, 12px bottom margin, 4px row gap |
| Field error | `#ff9094`, block, `margin-top:4px` |
| Nested field grid (`.setup`) | `1fr / 1.4fr`, gap 16px, padding 12px 16px, 1px `#343c47` border, 4px radius, `#20252c` background |

---

## 4. Responsive rules affecting `.notification-layout`

| Rule | File:line | Effect on Notification |
|---|---|---|
| `@media (max-width:767px) .notification-layout { grid-template-columns: 1fr; }` | `fst-c.css:295` | **Only Notification-specific responsive rule.** Collapses 1.5fr/1fr to a single column. |
| `@media (max-width:1023px) .tab-surface { padding-inline: var(--s4); }` | `fst-c.css:401` | Outer horizontal padding 24px → 16px (therefore also at 767/479). |
| `@media (max-width:479px) .tab-surface { padding-inline: var(--s3); }` | `fst-c.css:414` | Outer horizontal padding → 12px. |
| `@media (max-width:1023px) .tab-surface { padding-block: ... }` | not present | Vertical padding stays 12/16. |
| `@media (max-width:767px) .setup { grid-template-columns: 1fr; }` | `fst-c.css:293` | Nested heartbeat/detail field grid stacks. |
| `@media (min-width:1440px) .tab-surface { padding-block: var(--s4); }` | `fst-c.css:398` | Vertical padding 12/16 → 16/16 at ≥1440. |

Boundary that matters for native FST:

- The single-column collapse exists only at `max-width:767px`.
- Production `ContentView` has `minWidth: 900`
  (`FishSockTransfer/FishSockTransfer/Views/ContentView.swift:48`).
- Therefore the production window can never reach the 767px collapse
  breakpoint. The 1.5fr/1fr two-column Notification layout is reachable across
  the entire production width range.

---

## 5. Semantic classification

### 5.1 `VISUAL_AUTHORITY` — safe to adopt as presentation

- `notification-layout` `1.5fr / 1fr`, gap 16, `align-items:start`.
- Left column = `Telegram setup` + `Notify events`.
- Right column = `Notification status` + `Message preview`.
- `.settings-section` geometry: padding 16, radius 4, 1px `#343c47`, `#20252c`.
- `.settings-fields` gap 16; label→control 4px; control height 36, radius 4.
- `.check-row` gap 12, `padding-block:8`, checkbox 16×16 accent `#7ab6ff`.
- `.status-list` gap 16; `.od-field` intra gap 4; dt 14px muted / dd 16px.
- `.message-preview` padding 16, radius 4, 1px `#343c47`, `#11161c`,
  `16px/1.6` SF Mono, `pre-wrap` + `anywhere`.
- Surface intro: `h1 "Notifications"` + `.section-kicker`
  `"Optional · best-effort · separate from job safety"`.
- Section headings: `"Telegram setup"`, `"Notify events"`,
  `"Notification status"`, `"Message preview"`.
- Safety caption: `"Notification delivery never changes transfer or
  verification results."`
- Event label wording: `Job starts`, `Heartbeat while running`,
  `Transfer fails`, `Copy completed`, `Verify completed / Safe to eject`.
- Field labels: `Bot token`, `Chat ID`, `Heartbeat interval`,
  `Message detail`.
- Option sets: heartbeat `15 minutes | 30 minutes`; detail
  `Compact | Standard`.
- `.form-summary` / `.field-error` visual treatment (presentation only).
- Outer `.tab-surface` padding 12/24/16.

### 5.2 `FIXTURE_ONLY` — prototype semantics; MUST NOT be copied to production

Explicit prototype-only strings, all verified in the frozen source:

| String | File:line |
|---|---|
| `"This visual prototype generates a local preview. No message is sent."` | `fst-c.js:258` |
| `"Enabled in preview"` | `fst-c.js:260` |
| `"Not tested"` | `fst-c.js:260` |
| `"No messages sent"` (fixture default `model.lastPreview`) | `fst-c.js:38` |
| `"Preview generated · no message sent"` | `fst-c.js:380` |
| `"Preview generated locally. No Telegram message was sent."` (toast) | `fst-c.js:380` |
| `"Generating preview…"` (button busy label) | `fst-c.js:258` |
| `"Generating local message preview"` (loading-track aria-label) | `fst-c.js:258` |
| `"Enter a sample bot token to generate a preview."` | `fst-c.js:367` |
| `"Enter a numeric sample Chat ID, such as 123456789."` | `fst-c.js:371` |
| `"Design fixture only. No transfer, hash, filesystem write or notification is executed."` | `fst-c.js:108` |
| Fixture header comment `"FST design fixtures only. No filesystem, transfer engine, hashing or network access."` | `fst-c.js:1` |

Additional fixture-only behavior (not strings):

- `testMessage()` performs a 700ms `setTimeout` and performs **no network
  send** (`fst-c.js:375-381`). Production Test Message must keep its real
  send path.
- Token/chatID are held in a plain JS object (`fst-c.js:37`) and written to
  `input.value` (`fst-c.js:256-257`). Production must keep SecureField +
  Keychain.
- Prototype form validation (`validateNotify`, `fst-c.js:363-374`) has no
  production counterpart; do not import its error copy or its
  `form-summary` link-list behavior as a semantic change.

> Note on `"No messages sent"`: the prototype fixture default and production
> `NotificationRuntimeStatus.from(...)` (`Models/NotificationSettings.swift:119`)
> happen to use the same literal. The production value is canonical. The
> prototype literal is recorded here as fixture evidence, not as authority.

### 5.3 `BACKEND_CONSTRAINTED` — presentation may follow design, value must come from backend

| Datum | Design source | Production backend truth |
|---|---|---|
| Telegram status row | `Enabled in preview / Disabled` (`fst-c.js:260`) | `viewModel.notificationStatus.telegramStatus` from `NotificationRuntimeStatus.from(settings:token:)` → `Disabled / Not Configured / Enabled` (`Models/NotificationSettings.swift:106-122`) |
| Connection row | `Not tested` (`fst-c.js:260`) | `viewModel.notificationStatus.connectionStatus.displayText` → `Not Tested / Ready / Error` (`Models/NotificationSettings.swift:71-86`) |
| Last message row | `model.lastPreview` (`fst-c.js:260`) | `viewModel.notificationStatus.lastMessageStatus` |
| Last error row | joined `formErrors` or `None` (`fst-c.js:260`) | `viewModel.notificationStatus.lastErrorSummary ?? "-"` |
| Message preview body | `notificationPreview()` live fixture state (`fst-c.js:244-249`) | `NotificationMessageFactory.preview(settings:sourceName:destinationName:)` (`Models/NotificationSettings.swift:209-220`), fixed fixture context `phase=Copying, progress=42, elapsed=12:00, eta=18:00` |
| Heartbeat interval options | `15 minutes / 30 minutes` | `TelegramHeartbeatInterval.allCases` = `.fifteenMinutes/.thirtyMinutes` (`Models/NotificationSettings.swift:5-22`) — **exact match** |
| Message detail options | `Compact / Standard` | `TelegramMessageDetail.allCases` = `.compact/.standard` (`Models/NotificationSettings.swift:24-33`) — **exact match** |
| Event checkbox set | 5 prototype toggles | `NotificationSettings.notifyJobStarts/notifyHeartbeat/notifyTransferFails/notifyCopyCompleted/notifyVerifyCompleted` — **exact set match** |

### 5.4 `PRODUCTION_TRUTH_OVERRIDE` — production wins over the design

- Production FST Telegram behavior remains canonical:
  `TransferViewModel.testTelegramNotification()`
  (`ViewModels/TransferViewModel.swift:845`) and the
  `TelegramNotificationService` send path.
- Production notification status remains canonical:
  `NotificationRuntimeStatus` / `NotificationConnectionState`
  (`Models/NotificationSettings.swift:71-123`).
- `NotificationMessageFactory` remains canonical
  (`Models/NotificationSettings.swift:162-266`), including the
  `Do NOT format source media.` failure line and the
  `containsUnsafePath` guard.
- Notification never affects transfer / verify / report / SAFE TO EJECT.
  Design states this too (`"Notification delivery never changes transfer or
  verification results."`, `fst-c.js:254`), but production wording is stronger
  and canonical: `"Telegram notification is optional and best-effort. It never
  changes transfer, verify, report, or SAFE TO EJECT results."`
  (`Views/NotificationTabView.swift:76`).
- Persistence canonical: `.onChange(of: viewModel.notificationSettings)` →
  `persistNotificationSettings()` and `.onChange(of:
  viewModel.telegramBotToken)` → `persistTelegramBotToken()`
  (`Views/NotificationTabView.swift:27-32`,
  `ViewModels/TransferViewModel.swift:826-843`).
- Secret handling canonical: `SecureField` + Keychain help
  (`Views/NotificationTabView.swift:63-65`).
- Status/Chat ID/Token values must never be synthesized to satisfy a design
  mock.

---

## 6. Diff against frozen source for Notification regions

```text
LIVE_SOURCE_READ=NO
LIVE_VS_FROZEN_NOTIFICATION_DIFF=NOT_MEASURED
LIVE_VS_FROZEN_NOTIFICATION_DIFF_REASON=No live OpenDesign read surface available; see LIVE_READ_RESULT.md
```

No claim of equivalence or divergence between live and frozen Notification
regions is made.
