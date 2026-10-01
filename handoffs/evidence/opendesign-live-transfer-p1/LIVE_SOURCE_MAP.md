# Live OpenDesign source map

PROJECT=FST Design Exploration
PROJECT_ID=988fea7b-beea-4916-a10e-5368a120417e
AUTHORITY=LIVE_OPEN_DESIGN_MCP
ACTUAL_CALLS=list_projects;get_file(index.html);get_file(assets/fst-c.css);get_file(assets/fst-c.js)
READ_ONLY=YES
START_HEAD=0c230033eaa413629459c1495c84e26d94bdf1c2

The three `live-source/` files are exact text returned by MCP in this execution. Line references refer to these snapshots. No OpenDesign mutation was called. Final CSS overrides take precedence over early rules. CodeGraph callable surface unavailable; production source and tests inspected directly.

| Region | Live file / location | Native mapping |
|---|---|---|
| Outer geometry | CSS `.app-window` 75, 325; max 1280×888, scroll middle | ContentView native window; retain 900×660 minimum, evidence 1120×760 |
| Title/chrome | HTML `.titlebar` 70–74; CSS 77–84, 326 | Real NSWindow title/traffic lights; secondary tools signature in header |
| FST brand | HTML `.brand` 76–97; CSS `.wordmark`, `.brand-rule` 87–88 | ContentView FST wordmark, divider, existing native social links |
| Tabs | HTML `.tabs` 98–102; CSS 110–113, 328–329 | Native tab Buttons, selected inset/raised treatment |
| Separators | CSS `--line` 10, 323; `.endpoint + .endpoint` 123; `.transfer-setup` 351; `.runtime-values` 380 | SwiftUI Divider between route rows, setup and metric regions |
| Footer | HTML `.app-footer` 112–115; CSS 202–209; JS `updateFooter` 266–280 | Persistent secondary footer; existing canonical state presentation, read-only source statement |
| Tokens | CSS `:root` 1–43, 323, 423–427 | PanelStyle semantic adaptive shell/surface/inset/line/text/state colors |
| Surfaces | `--bg #161a1f`, `--surface #20252c`, `--inset #11161c`, `--raised #2a3038` | Dark semantic colors with native light equivalents |
| Text / semantic | `--text #edf1f6`, `--muted #a7b1bd`; blue/green/amber/red 11–17 | Primary/secondary; explicit state text accompanies colors |
| Borders / radii | final `--line #343c47`, `--radius 4px`, `--control-radius 4px`, dialog 12px | Flat route group, restrained 4pt control surfaces; real macOS window chrome |
| Type | CSS system/mono fonts 18–19; body16,label14,title20,metric28; weight selectors 335–338,356,431 | SF system, mono paths/technical data, equal 28pt metric values; native smaller labels where needed |
| Spacing | CSS s1/s2/s3/s4/s6/s8=4/8/12/16/24/32; final section-gap8 | SwiftUI group8, inset12/16, outer24 |
| Source row | JS `endpoint` 138–150; CSS 332–340 | SourceCardView horizontal label/identity/facts/path/actions; no invented free capacity |
| Destination row | same endpoint selectors/function | DestinationCardView identity/filesystem/free/writable/target/actions |
| Capacity | JS `readiness` 152–155; CSS 345–350 | StorageAnalysisView: preserve CAPACITY PRECHECK PASSED and all canonical floor/snapshot uncertainty wording |
| Setup grid | JS `setup` 157–164; CSS `.transfer-setup` 351 | Bandwidth + Verification side by side; canonical options/descriptions |
| Control strip | JS `controlBar` 165–174; CSS 355–361,429–430 | Existing active/terminal bars; native action, confirmation and retry semantics |
| Job Status | JS `telemetry` 199–219; CSS 362–370 | TransferControlsView progressPanel visible across ready/active/terminal states |
| Hero metrics | JS 209–211; CSS 160–167,371,431 | Three equal widths: phase progress, phase ETA, copy speed / truthful Verify Elapsed |
| Thin progress | JS 212; CSS 168–177,373–377,443–454 | Native linear ProgressView, semantic phase tint, text percentage |
| Phase row | JS 204–207,214; CSS 378–379 | Canonical state title and workflow phase/elapsed fields |
| Secondary metrics | JS 215–218; CSS 380–382 | Existing average copy speed, copy elapsed, copied bytes/files; no fabricated job duration |
| Current item | JS 206,219; CSS 180–182,383 | Existing current-file/sequence presentation with full value tooltip |
| READY | JS `statePresentation` 129, controlBar168 | Canonical ready/canStartTransfer; no prototype hasSpace admission |
| COPYING | JS 131, telemetry199–219 | Canonical copying, real runtime snapshot |
| VERIFYING | JS 132, telemetry199–219 | Canonical verifying; no prototype 512.8 MB/s or fabricated checked-file count |
| SAFE TO EJECT | JS 125–127; CSS success429,441,450 | Only canonical `.safeToFormat`; never JS safeToEject port |

Fixture numbers, prototype safety computations, Telegram/log/report content and browser wording are not product truth. Dedicated evidence for PREPARING, TRANSFER COMPLETE, MANUAL CHECK REQUIRED, TRANSFER ERROR and CANCELLED will be classified conservatively in the gap report even where a shared JS presentation mapping exists.

Source coordinate correction: HTML shell and initial CSS offsets were checked directly against the exact MCP snapshots. Initial evidence bytes are preserved in LIVE_SOURCE_MAP_INITIAL.md; only the coordinates above changed.
