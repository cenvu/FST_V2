# Notification pre-edit gap matrix

START_HEAD=745022a8039cd237ced073159afbc0478898ae74
DESIGN_AUTHORITY=CANONICAL_FROZEN_SOURCE_MAP
LIVE_MCP_REQUIRED=NO
LIVE_VS_FROZEN_DIFF=UNKNOWN
CODEGRAPH=UNAVAILABLE;direct source/tests inspected

Authority: `../patch3-source/PATCH3_NOTIFICATION_SOURCE_MAP.md` (R references below map to implementation contract regions). Baseline captured before production mutation: BEFORE_NOTIFICATION.png, BEFORE_NOTIFICATION_CONFIGURED.png, BEFORE_NOTIFICATION_MINIMUM.png.

| REGION | SOURCE_MAP_REF | TARGET | CURRENT | GAP | SEVERITY | CLASS | PROPOSED_CHANGE |
|---|---|---|---|---|---|---|---|
| R1 Intro | §2, §3.2 surface-intro | 20 semibold title, 14 muted kicker | Absent | Missing content hierarchy | Medium | VISUAL_ONLY | Compact intro row, retain full safety footnote |
| R2 Telegram | §2 LEFT, §3.3 fields | Left standalone section, labels above secure/native 36pt fields | Right half of shared panel; placeholder labels only | Position, surface, field rhythm | High | VISUAL_ONLY | Local section helper; labeled SecureField/TextField; preserve real action |
| R3 Events/options | §2 LEFT, §3.2 setup/check-row | One left section, five rows and native menu fields 1:1.4 | Full-width split with separate options heading and segmented pickers | Structure and control presentation | High | VISUAL_ONLY | Merge options below events, keep exact allCases/bindings |
| R4 Status | §2 RIGHT, §3.2 status-list | Vertical label/value list 16/4 gaps | Horizontal LazyVGrid, two-line middle truncation | Position and inspectability | High | VISUAL_ONLY / PRODUCTION_TRUTH_OVERRIDE | Right section, natural wrapping, selection/help, retain Error emphasis and '-' |
| R5 Preview | §2 RIGHT, §3.3 preview | Right lower section, mono 16, inset 16/4/1 | Full-width third row, secondary text, 10/8/no border | Geometry and contrast | High | VISUAL_ONLY / BACKEND_CONSTRAINED | Keep factory text/selection; local inset/border/line spacing |
| R6 Scroll/layout | §3.3, §4 | 1.5:1 top-aligned columns, 16 gaps; usable minimum | Three rows, 12 gap and 16 horizontal padding | Composition | High | VISUAL_ONLY | File-private two-child Layout; 24 horizontal, 12 top, 16 bottom; no breakpoint |

Smallest safe production surface: NotificationTabView.swift only. Targeted verification: native Dark Aqua before/pass/final captures, exact behavior diff inspection, Debug build, existing NotificationCoordinator and TransferViewModelRuntime suites, full canonical XCTest suite. No model/service/global panel edits.
