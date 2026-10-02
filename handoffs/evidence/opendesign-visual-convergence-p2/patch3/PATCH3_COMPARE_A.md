# Patch 3 — Pass A comparison

DESIGN_AUTHORITY=CANONICAL_FROZEN_SOURCE_MAP
LIVE_VS_FROZEN_DIFF=UNKNOWN
IMPLEMENTATION_PASSES=1
PASS_B_NOT_REQUIRED=YES
REASON=The six structural regions and local geometry are implemented; remaining differences are real production values, native control rendering, and safe scrolling at minimum size. No material correctable visual-only gap identified in the three Pass A captures.
VISUAL_PARITY_ACCEPTANCE=PENDING_BRAIN_REVIEW

Compared BEFORE and PASS_A default/configured 1120x760 and minimum 900x660 Dark Aqua captures against source map §§2–4. Screenshots include the unchanged app header/footer. Columns use 24pt outer horizontal padding: 1120 track=1056, left=633.6/right=422.4; 900 track=836, left=501.6/right=334.4. The web's below-1023 padding rule is not replicated; the native screen consistently keeps 24pt.

| Region | Classification | Observation |
|---|---|---|
| R1 Intro | MATCHED / INTENTIONAL_NATIVE_VARIATION | Compact 20 semibold title and 14 muted kicker. The selected tab repeats the topic, but the intro adds the safety separation and remains per contract. Native baseline spacing differs slightly from CSS flex centering. |
| R2 Telegram Setup | MATCHED / SAFETY_OVERRIDE / INTENTIONAL_NATIVE_VARIATION | Left standalone 16/4/1 surface; labeled 36pt inset secure/native fields; real Test Message, identical busy disable and safety footnote. Native bordered button, checkbox gap, and .footnote sizing retained; no fixture validation/imported local-send wording. |
| R3 Notify Events/options | MATCHED / INTENTIONAL_NATIVE_VARIATION | Five native checkbox rows, 8pt VStack rhythm; menu pickers in 1:1.4 local tracks within one section. Native checkbox icon/text gap and popup chrome differ from CSS. No detached options card/heading. |
| R4 Status | MATCHED / BACKEND_CONSTRAINED / SAFETY_OVERRIDE | Right upper vertical list, 16 between rows, 4 inside, 14/16 type. Values from runtime, '-' retained. Production 'Not Tested' and factory 'No messages sent' remain canonical. Removed two-line truncation to keep long errors selectable/wrapped; help exposes full value. Error uses semantic warm warning emphasis. |
| R5 Preview | MATCHED / BACKEND_CONSTRAINED | Right lower 16/4/1 inset container, mono 16 with 6pt added line spacing, primary semantic foreground, wrapping/selection. Factory content remains canonical (42%, 12:00, 18:00). |
| R6 Layout/scroll | MATCHED / INTENTIONAL_NATIVE_VARIATION | Top-aligned 1.5:1 tracks, 16pt gap and section rhythm, outer ScrollView. At nominal size all controls appear, but bottom card edge needs a short scroll; minimum requires vertical scroll. No height compression, clipping in document, horizontal overflow, or <767 collapse. Supplemental bottom captures verify access. |

No production refinement after Pass A. Build: BUILD SUCCEEDED. BRAIN owns visual acceptance; these are implementer observations only.
