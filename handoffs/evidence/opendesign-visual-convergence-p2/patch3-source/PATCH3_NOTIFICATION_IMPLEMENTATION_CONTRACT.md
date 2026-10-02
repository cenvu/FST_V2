# Patch 3 — Notification implementation contract

TASK=OPENDESIGN_P2_PATCH3_NOTIFICATION_LIVE_SOURCE_CAPTURE
WORKSTREAM_ID=OPENDESIGN_VISUAL_CONVERGENCE_P2
PHASE=PATCH_3_SOURCE_CAPTURE
CLASS=READ_ONLY_DESIGN_AUTHORITY_CAPTURE
WORKER_STATUS=DESIGN_SOURCE_EVIDENCE_COMPLETE
CONTRACT_STATE=PROPOSAL_FOR_BRAIN_ROUTING;NOT_AUTHORIZED_IMPLEMENTATION

This document is source-capture output. No production Swift file was changed by
this task. It defines the boundary a later, separately routed Patch 3
implementation task must stay inside.

```text
AUTHORIZED_PRODUCTION_FILE=
  FishSockTransfer/FishSockTransfer/Views/NotificationTabView.swift

CONDITIONAL_FILE=
  FishSockTransfer/FishSockTransfer/Views/PanelStyle.swift

CONTENTVIEW=
  DO_NOT_CHANGE unless strictly required

TARGET_LAYOUT=
  LEFT_1_5_TO_RIGHT_1

PRESERVE_BEHAVIOR=
  Telegram bindings
  SecureField
  Chat ID
  persistence
  Test Message
  real status
  heartbeat
  message detail
  NotificationMessageFactory
  best-effort safety separation

FORBIDDEN=
  prototype fixture semantics
  fake status
  secret capture
  network send during visual fixture
  ViewModel/backend semantic changes
```

Supporting design authority: `PATCH3_NOTIFICATION_SOURCE_MAP.md`.
Live read outcome: `LIVE_READ_RESULT.md`.

---

## 1. Authorized / conditional / prohibited files

| File | Status |
|---|---|
| `FishSockTransfer/FishSockTransfer/Views/NotificationTabView.swift` | **AUTHORIZED** — only file that should need structural change |
| `FishSockTransfer/FishSockTransfer/Views/PanelStyle.swift` | **CONDITIONAL** — only if a notification-specific panel modifier is required; `standardPanel` must remain available to other callers (`PanelStyle.swift:81-88`) |
| `FishSockTransfer/FishSockTransfer/Views/ContentView.swift` | **DO_NOT_CHANGE** unless strictly required; `notificationTabContent` (`ContentView.swift:186-189`) already delegates fully to `NotificationTabView`, so no ContentView change is expected |
| `ViewModels/TransferViewModel.swift` | PROHIBITED |
| `Models/NotificationSettings.swift` | PROHIBITED |
| `Services/TelegramNotificationService.swift` | PROHIBITED |
| `Coordinators/NotificationCoordinator.swift` | PROHIBITED |
| any `TransferState` / verify / report / SAFE TO EJECT code | PROHIBITED |

---

## 2. Target layout contract

Normal desktop target (production window `minWidth 900`, `idealWidth 1120`,
`ContentView.swift:47-54`):

```text
LEFT  ≈ 1.5fr     RIGHT ≈ 1fr
──────────────    ──────────────
Telegram Setup    Notification Status
Notify Events     Message Preview
+ Notification
  Options
```

Design authority for the ratio: `.notification-layout`
`grid-template-columns: minmax(0,1.5fr) minmax(0,1fr); gap:16px;
align-items:start` (`fst-c.css:210`).

Expected column widths with current NotificationTabView horizontal padding 16:

| Window width | Track after padding/gap | LEFT (1.5fr) | RIGHT (1fr) |
|---|---|---|---|
| 900 (min) | 868 − 16 = 852 | ≈ 511.2 pt | ≈ 340.8 pt |
| 1120 (ideal) | 1088 − 16 = 1072 | ≈ 643.2 pt | ≈ 428.8 pt |

If the implementation adopts the design's `.tab-surface` horizontal padding of
24 (`fst-c.css:330`) instead of the current 16, recompute the track as
`width − 48 − 16`; at 1120 that is LEFT ≈ 633.6 / RIGHT ≈ 422.4. Whichever
padding is chosen, record it; do not mix.

The design's single-column fallback exists only below 767px
(`fst-c.css:295`). Production `minWidth` is 900, so the production
implementation must keep the two-column layout across its whole width range.
No production reflow breakpoint is authorized.

---

## 3. Region-by-region target map

Each region records: `OPEN_DESIGN_SOURCE`, `OPEN_DESIGN_GEOMETRY`,
`OPEN_DESIGN_STYLE`, `CURRENT_SWIFTUI_REGION`, `CURRENT_DIFFERENCE`,
`PRODUCTION_CONSTRAINT`, `IMPLEMENTATION_GUIDANCE`.

### R1 — Surface intro / heading / kicker

```text
OPEN_DESIGN_SOURCE      notificationSurface() fst-c.js:254;
                        div.surface-intro > h1 + span.section-kicker
OPEN_DESIGN_GEOMETRY    .surface-intro: flex, justify-content:space-between,
                        gap 16, margin-bottom 16 (fst-c.css:115).
                        tab-surface padding 12/24/16 (fst-c.css:330).
OPEN_DESIGN_STYLE       h1 "Notifications": 20px/1.3, weight 650,
                        letter-spacing -0.02em (fst-c.css:67).
                        .section-kicker: 14px, #a7b1bd (fst-c.css:116),
                        text "Optional · best-effort · separate from job safety".
CURRENT_SWIFTUI_REGION  ABSENT. NotificationTabView.swift:13-25 starts directly
                        with VStack(spacing:12) { statusAndSetupSection; ... }
                        padding .horizontal 16, .bottom 12.
CURRENT_DIFFERENCE      No surface heading and no kicker exist in production.
                        Production also lacks the design's 12/24/16 outer
                        padding (has 16 horizontal / 12 bottom / no top).
PRODUCTION_CONSTRAINT   Presentation only. Kicker copy must not weaken or
                        replace the canonical production safety footnote at
                        NotificationTabView.swift:76.
IMPLEMENTATION_GUIDANCE Add a leading intro row: Text("Notifications")
                        (.system 20, weight 650, tracking -0.4) plus a
                        secondary 14px kicker "Optional · best-effort ·
                        separate from job safety", spaced 16, 16 below.
                        Keep the existing safety footnote in the Telegram
                        Setup region unchanged.
```

### R2 — Telegram Setup

```text
OPEN_DESIGN_SOURCE      notificationSurface() fst-c.js:254-258;
                        section.settings-section > h2 "Telegram setup",
                        p.caption, checkbox(enabled), form#notification-form
                        > div.settings-fields
OPEN_DESIGN_GEOMETRY    Section: padding 16, radius 4, 1px #343c47 border,
                        background #20252c (fst-c.css:211). h2
                        margin-bottom 16 (fst-c.css:212).
                        .settings-fields gap 16 (fst-c.css:214).
                        label→control 4 (fst-c.css:143).
                        Controls min-height 36, padding 4/12, radius 4,
                        background #11161c, border 1px #343c47
                        (fst-c.css:145 + fst-c.css:354).
                        check-row gap 12, padding-block 8; checkbox 16x16,
                        margin-top 4, accent #7ab6ff (fst-c.css:215-216).
                        Test action: .button.ghost, 36px min-height, radius 4,
                        transparent background (fst-c.css:133/135/341).
                        Optional .loading-track height 4, radius 4
                        (fst-c.css:245).
OPEN_DESIGN_STYLE       h2 16px/650. .caption 14px #a7b1bd: "Notification
                        delivery never changes transfer or verification
                        results." Labels "Bot token · required" /
                        "Chat ID · required" only when enabled, 14px #a7b1bd,
                        weight 500. Error span #ff9094, block, margin-top 4
                        (fst-c.css:217). .form-summary 12px padding, 1px
                        #ff9094 border, radius 4, margin-bottom 12, row gap 4
                        (fst-c.css:218). field-hint 14px #a7b1bd margin-top 4
                        (fst-c.css:144).
CURRENT_SWIFTUI_REGION  NotificationTabView.swift:54-82, right side of
                        statusAndSetupSection HStack. Headline "Telegram
                        Setup"; Toggle(.checkbox); SecureField("Bot Token")
                        .textFieldStyle(.roundedBorder); TextField("Chat ID")
                        .textFieldStyle(.roundedBorder); HStack { Button
                        "Test Message"; footnote Text }.
CURRENT_DIFFERENCE      (a) Position: currently RIGHT side; design puts it in
                        the LEFT column. (b) Wrapped inside a 1/3–2/3 status
                        split with a Divider instead of a standalone section.
                        (c) .standardPanel: padding 12, radius 10,
                        controlBackgroundColor 0.5, secondary 0.15 stroke
                        (PanelStyle.swift:69-79) vs design padding 16,
                        radius 4, #20252c, 1px #343c47. (d) No "Telegram
                        setup" h2 spacing of 16 below heading — production
                        VStack spacing is 10. (e) No leading .caption safety
                        line inside the section. (f) Controls use
                        .roundedBorder, not the 36px/inset/4px design field.
                        (g) Button is a default app button, not ghost/36px.
                        (h) Prototype field-hint under Test Message and the
                        form-summary/error span system do not exist — and
                        their fixture copy must not be added.
PRODUCTION_CONSTRAINT   SecureField + Keychain help string must remain
                        (NotificationTabView.swift:63-65). Chat ID binding to
                        viewModel.notificationSettings.chatID must remain.
                        Toggle binding to isTelegramEnabled must remain.
                        Test Message must keep calling
                        viewModel.testTelegramNotification() with the real
                        send path; isSendingTelegramTestMessage disable must
                        remain. The canonical safety footnote (line 76) must
                        remain. No prototype validation copy, no "enabled in
                        preview", no local-preview claim.
IMPLEMENTATION_GUIDANCE Move this section into the LEFT column as a standalone
                        .settings-section-equivalent block: heading
                        "Telegram Setup" 16/650 with 16 below, production
                        safety caption 14px secondary, checkbox row 12 gap /
                        8 vertical padding, then a 16-gapped field stack of
                        SecureField (Bot Token) and TextField (Chat ID) at
                        36pt control height, 4pt radius, inset background,
                        1px line border, then the Test Message ghost button
                        (36pt) with the existing footnote preserved.
                        Native Aqua field/button rendering stays native.
```

### R3 — Notify Events + Notification Options

```text
OPEN_DESIGN_SOURCE      notificationSurface() fst-c.js:259;
                        section.settings-section h2 "Notify events" +
                        5x checkbox(...) + div.setup > 2x div.field
OPEN_DESIGN_GEOMETRY    Same section geometry as R2 (padding 16, radius 4,
                        1px #343c47, #20252c, h2 margin-bottom 16).
                        Section spacing to the previous section: 16
                        (fst-c.css:213).
                        check-row: gap 12, padding-block 8, checkbox 16x16
                        accent #7ab6ff.
                        Nested .setup grid: grid-template-columns 1fr 1.4fr,
                        gap 16, padding 12 16, 1px #343c47, radius 4,
                        background #20252c (fst-c.css:142).
                        Nested selects min-height 36, radius 4, inset bg
                        (fst-c.css:145/354).
                        Responsive: below 767px .setup → 1fr (fst-c.css:293);
                        unreachable in production (minWidth 900).
OPEN_DESIGN_STYLE       h2 "Notify events" 16/650. Labels: Job starts /
                        Heartbeat while running / Transfer fails /
                        Copy completed / Verify completed / Safe to eject.
                        Field labels "Heartbeat interval" and "Message
                        detail", 14px #a7b1bd weight 500, 4px above control.
                        Options 15 minutes | 30 minutes; Compact | Standard.
                        select padding-inline 12, padding-block 4
                        (fst-c.css:354).
CURRENT_SWIFTUI_REGION  NotificationTabView.swift:87-141,
                        eventsAndHeartbeatSection: HStack { VStack
                        "Notify Events" + 5 Toggle(.checkbox) VStack spacing 8
                        ; Divider ; VStack "Notification Options" +
                        2x (caption label + .segmented Picker, maxWidth 280)
                        } .standardPanel().
CURRENT_DIFFERENCE      (a) Design places Notify Events in the LEFT column
                        directly under Telegram Setup, and folds the two
                        option pickers into the same section as a nested 2-up
                        grid; production puts them in a separate second full
                        row split 1/2–1/2 with a Divider. (b) Production has
                        a separate "Notification Options" heading; the design
                        has no such heading — options sit under "Notify
                        events". (c) Production uses .segmented Pickers capped
                        at 280pt; design uses two select controls in a
                        1fr/1.4fr grid. (d) Production toggle stack spacing 8
                        vs design check-row padding-block 8 + gap 12.
                        (e) Panel treatment differs as in R2(c).
                        (f) Production caption label "Heartbeat Interval" /
                        "Message Detail" are title case; design is "Heartbeat
                        interval" / "Message detail".
PRODUCTION_CONSTRAINT   All five Toggle bindings
                        (notifyJobStarts/notifyHeartbeat/notifyTransferFails/
                        notifyCopyCompleted/notifyVerifyCompleted), the
                        heartbeatInterval binding and the messageDetail
                        binding must be preserved exactly
                        (NotificationTabView.swift:96-135). Option sets come
                        from TelegramHeartbeatInterval.allCases and
                        TelegramMessageDetail.allCases; do not add, remove or
                        rename options. Changing segmented → menu/dropdown is
                        presentation-only and must not alter the selected
                        value type or persistence.
IMPLEMENTATION_GUIDANCE Move Notify Events into the LEFT column directly below
                        Telegram Setup as a second .settings-section-equivalent
                        with 16pt separation. Keep the five checkbox rows.
                        Replace the separate "Notification Options" panel with
                        the nested 2-up field grid (Heartbeat interval |
                        Message detail) inside the same section, labeled
                        14px secondary, 4pt above the control. Picker style
                        may follow the design's select presentation; if native
                        Aqua segmented is retained instead, record it as a
                        deliberate native-control deviation rather than a
                        design divergence.
```

### R4 — Notification Status

```text
OPEN_DESIGN_SOURCE      notificationSurface() fst-c.js:260;
                        section.settings-section h2 "Notification status" +
                        dl.metadata.status-list + 4x metadataRow()
OPEN_DESIGN_GEOMETRY    Section: padding 16, radius 4, 1px #343c47,
                        #20252c, h2 margin-bottom 16.
                        .status-list: display grid, gap 16 (fst-c.css:220).
                        Each row is .od-field (index.html:25): grid, gap
                        --od-gap forced to 4 by .metadata .od-field
                        (fst-c.css:197), children display block → label
                        stacked ABOVE value.
                        dt: 14px #a7b1bd (fst-c.css:198).
                        dd: 16px, margin 0, overflow-wrap anywhere
                        (fst-c.css:199).
OPEN_DESIGN_STYLE       Rows: Telegram → "Enabled in preview" | "Disabled";
                        Connection → "Not tested"; Last message →
                        model.lastPreview; Last error → joined formErrors |
                        "None". Only "Disabled" and "None" are non-fixture
                        values; see FORBIDDEN.
CURRENT_SWIFTUI_REGION  NotificationTabView.swift:37-53, left side of
                        statusAndSetupSection: Text("Notification Status")
                        .font(.headline) + LazyVGrid(statusColumns) with
                        statusRow(label,value): label .caption
                        .fontWeight(.semibold) secondary in a
                        120–150 flexible column, value .body rounded,
                        orange when value == "Error", lineLimit 2,
                        truncationMode .middle. Statuses read
                        viewModel.notificationStatus.* (lines 44-47).
CURRENT_DIFFERENCE      (a) Position: currently the LEFT 1/3 of a 1/3–2/3
                        split; design makes it the top of the RIGHT column.
                        (b) Layout: production is a horizontal label|value
                        2-column grid with a 120–150pt label column; design
                        is a vertical list of stacked label-over-value pairs
                        with 16pt between pairs and 4pt inside a pair.
                        (c) Production shows only 4 rows in a grid that can
                        sit side-by-side; design is a single-column list.
                        (d) Panel treatment differs as in R2(c).
                        (e) Production last-error fallback is "-"; design is
                        "None".
PRODUCTION_CONSTRAINT   Real status only. All four values must continue to
                        come from viewModel.notificationStatus
                        (NotificationRuntimeStatus). Never render
                        "Enabled in preview", never render a synthesized
                        connection result, never fake a successful test.
                        The production fallback for a missing last error
                        ("-") is canonical unless BRAIN explicitly changes it.
                        Orange-on-"Error" emphasis is a production safety
                        affordance and must not be dropped without review.
IMPLEMENTATION_GUIDANCE Move this section to the top of the RIGHT column as a
                        standalone .settings-section-equivalent: heading
                        "Notification Status" 16/650 with 16 below, then a
                        vertical list with 16pt row spacing, each row a
                        14pt secondary label over a 16pt value with 4pt
                        internal spacing. Keep statusRow's lineLimit/
                        truncation so long errors stay inspectable. Values
                        stay bound to viewModel.notificationStatus.
```

### R5 — Message Preview

```text
OPEN_DESIGN_SOURCE      notificationSurface() fst-c.js:260;
                        section.settings-section h2 "Message preview" +
                        pre.message-preview#message-preview
OPEN_DESIGN_GEOMETRY    Section: padding 16, radius 4, 1px #343c47,
                        #20252c, h2 margin-bottom 16; 16pt below Notification
                        Status (fst-c.css:213).
                        .message-preview: padding 16, border 1px #343c47,
                        radius 4, background #11161c, margin 0
                        (fst-c.css:219).
                        Column width = RIGHT 1fr track (≈ 428.8pt at 1120
                        with 16pt outer padding).
OPEN_DESIGN_STYLE       font: 16px/1.6 SFMono-Regular/Menlo/Monaco/monospace
                        with tabular-nums from .mono (fst-c.css:72/219);
                        white-space pre-wrap; overflow-wrap anywhere.
                        Content from notificationPreview() (fst-c.js:244-249).
CURRENT_SWIFTUI_REGION  NotificationTabView.swift:143-164,
                        messagePreviewSection: VStack { Text("Message
                        Preview") .font(.headline); Text(
                        NotificationMessageFactory.preview(...)) .font(.body
                        monospaced) .foregroundColor(.secondary)
                        .textSelection(.enabled) .fixedSize(vertical) .
                        padding(10) .background(NSColor.textBackgroundColor
                        0.6) .clipShape(RoundedRectangle(cornerRadius: 8)) }
                        .standardPanel().
CURRENT_DIFFERENCE      (a) Position: currently a full-width third row below
                        both upper panels; design puts it in the RIGHT column
                        under Notification Status. (b) No enclosing section
                        card of its own — production wraps the whole block in
                        .standardPanel with a heading inside; design wraps
                        heading + pre in a .settings-section. (c) padding 10
                        vs 16; radius 8 vs 4; no border vs 1px #343c47;
                        background textBackgroundColor 0.6 vs #11161c inset.
                        (d) Production monospaced body colour is .secondary;
                        design body colour is #edf1f6 (--text). (e) Font size
                        16/1.6 matches only if the production .body size
                        resolves to 16; no explicit line-height is set in
                        production. (f) Production does not set
                        overflow-wrap-anywhere; long paths rely on
                        textSelection/fixedSize only.
PRODUCTION_CONSTRAINT   The preview text MUST come from
                        NotificationMessageFactory.preview(settings:
                        sourceName:destinationName:)
                        (NotificationTabView.swift:149-153). Do not import
                        the prototype notificationPreview() body, its live
                        fixture state, or any of its strings. Text selection
                        must remain enabled. Font stays monospaced.
IMPLEMENTATION_GUIDANCE Move message preview into the bottom of the RIGHT
                        column as a .settings-section-equivalent containing
                        heading "Message Preview" 16/650 with 16 below and a
                        monospaced pre-equivalent: padding 16, radius 4,
                        1px line border, inset background, 16/1.6 monospaced,
                        wrapping enabled, text selection enabled, content
                        still produced by NotificationMessageFactory.
```

### R6 — Outer scroll container / responsive

```text
OPEN_DESIGN_SOURCE      .notification-layout fst-c.css:210;
                        responsive rules fst-c.css:295, 401, 414, 398
OPEN_DESIGN_GEOMETRY    tab-surface padding 12/24/16 (fst-c.css:330);
                        16 at ≥1440 vertical (fst-c.css:398);
                        padding-inline 16 below 1023 (fst-c.css:401);
                        padding-inline 12 below 479 (fst-c.css:414);
                        notification-layout → 1fr only below 767
                        (fst-c.css:295).
OPEN_DESIGN_STYLE       align-items:start — columns are top-aligned and do
                        not stretch to equal height.
CURRENT_SWIFTUI_REGION  NotificationTabView.swift:13-26: ScrollView > VStack
                        (alignment .leading, spacing 12) with three stacked
                        fixedSize sections; .padding(.horizontal, 16),
                        .padding(.bottom, 12); .frame(maxWidth:.infinity,
                        alignment:.topLeading). ContentView applies no
                        additional tab padding (ContentView.swift:186-189).
CURRENT_DIFFERENCE      Single vertical stack vs two-column grid; spacing 12
                        vs 16; padding 16/0/12 vs 24/12/16; sections are
                        full width rather than column width.
PRODUCTION_CONSTRAINT   ContentView minWidth 900 / ideal 1120 must be
                        respected. The 767px single-column design fallback is
                        unreachable and must not be introduced. No clipping
                        or disappearing controls at minWidth. Long chat IDs
                        and long error strings must remain inspectable.
                        ScrollView must remain so content never clips.
IMPLEMENTATION_GUIDANCE Replace the top-level VStack of three rows with a
                        two-column layout: HStack(alignment:.top, spacing:16)
                        { VStack(alignment:.leading, spacing:16)
                        { TelegramSetup; NotifyEventsWithOptions }
                          Spacer/minWidth
                          VStack(alignment:.leading, spacing:16)
                        { NotificationStatus; MessagePreview } }
                        inside the existing ScrollView, each column
                        .frame(maxWidth:.infinity, alignment:.topLeading)
                        with the left column weighted 1.5 and the right 1.0
                        (e.g. GeometryReader-free HStack using
                        .frame(maxWidth:.infinity) on both plus explicit
                        layout priority, or a hidden ratio helper in
                        PanelStyle.swift only if the conditional file is
                        authorized). Keep top-aligned, non-stretching
                        columns. Adopt outer padding 12 top / 24 sides / 16
                        bottom only if the implementation also records the
                        chosen padding; otherwise keep 16 and record that
                        deviation.
```

---

## 4. Behavior preservation checklist (must all still hold after Patch 3)

| Item | Current site |
|---|---|
| Telegram enable binding | `NotificationTabView.swift:60` |
| SecureField for bot token + Keychain help | `NotificationTabView.swift:63-65` |
| Chat ID binding | `NotificationTabView.swift:67` |
| Persist settings on change | `NotificationTabView.swift:27-29` → `TransferViewModel.swift:826` |
| Persist token on change | `NotificationTabView.swift:30-32` → `TransferViewModel.swift:833` |
| Test Message real send | `NotificationTabView.swift:71-74` → `TransferViewModel.swift:845` |
| Real status source | `NotificationTabView.swift:44-47` → `NotificationRuntimeStatus` |
| Five notify-event toggles | `NotificationTabView.swift:96-100` |
| Heartbeat interval picker | `NotificationTabView.swift:116-123` |
| Message detail picker | `NotificationTabView.swift:128-135` |
| `NotificationMessageFactory` preview | `NotificationTabView.swift:149-153` |
| Best-effort safety separation footnote | `NotificationTabView.swift:76` |

---

## 5. Forbidden list (expanded)

```text
FORBIDDEN=
  prototype fixture semantics
  fake status
  secret capture
  network send during visual fixture
  ViewModel/backend semantic changes
```

Concretely, a Patch 3 implementation must NOT:

1. Copy any string from `FIXTURE_ONLY` in
   `PATCH3_NOTIFICATION_SOURCE_MAP.md` §5.2 into production, including
   `"This visual prototype generates a local preview. No message is sent."`,
   `"Enabled in preview"`, `"Not tested"` (as a design-supplied value), or
   `"No messages sent"` as a design-supplied default.
2. Render `viewModel.notificationStatus` values that are not derived from
   `NotificationRuntimeStatus`.
3. Replace `SecureField` with a plain text field, log, echo, or otherwise
   expose the bot token.
4. Make Test Message a local/no-op preview, or send network traffic as part of
   a visual fixture or screenshot harness.
5. Change `NotificationSettings`, `NotificationRuntimeStatus`,
   `NotificationMessageFactory`, `TelegramNotificationService`,
   `NotificationCoordinator`, or any `TransferViewModel` notification method
   semantics.
6. Change `TransferState`, verification, report, or SAFE TO EJECT behavior in
   any way. Notification remains best-effort and must never gate, block, or
   authorize a transfer outcome.
7. Add a production responsive breakpoint that collapses the two columns —
   the design's 767px collapse is below the production `minWidth` of 900.
8. Modify `ContentView.swift` for layout reasons; if a change is ever judged
   strictly required, it must be re-routed to BRAIN rather than taken inside
   Patch 3.

---

## 6. Verification expectation for the later implementation task

No `xcodebuild` was required for this source-capture task because production
source is unchanged. A later Patch 3 implementation task must run at minimum:

```text
git diff --name-only        → only authorized/conditional production files
git diff --check            → clean
focused notification tests  → existing suite, 0 failures
full canonical suite        → existing suite, 0 failures
```

and must not self-accept visual parity (`VISUAL_PARITY_ACCEPTANCE` remains a
BRAIN decision).
