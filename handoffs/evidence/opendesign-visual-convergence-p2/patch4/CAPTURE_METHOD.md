# Patch 4 Technical Log capture method

DESIGN_AUTHORITY=CANONICAL_FROZEN_OPEN_DESIGN_SOURCE
LIVE_MCP_REQUIRED=NO
CAPTURE_APPEARANCE=DARK_AQUA
CAPTURE_RUNTIME=NATIVE_SWIFTUI_APPKIT

`capture_native.py` compiles the app's native Swift sources and renders them in
an `NSHostingView`. For BEFORE, the Swift sources are read from
`a87479af645a344bf7ccae0722f3829348ea0fb8` with `git show`; Pass A, Pass B,
and AFTER compile the current repository sources. A temporary copy of
`ContentView.swift` changes only the construction site to inject a fixture
`TransferViewModel`, select Technical Log, and set the diagnostics state. The
production view body and all other production sources are compiled verbatim.
The capture app packages the repository asset catalog and requests native
Dark Aqua. PNGs are saved directly from AppKit's `bitmapImageRepForCachingDisplay`
and `cacheDisplay`; there is no browser, WebView, HTML runtime, or image edit.

Each state uses an isolated unique `UserDefaults` suite, an empty fake token
store, null bookmark defaults, and a no-send notification service that traps
if any send is attempted. The populated log entries are deterministic
synthetic `LogEntry` values spanning the production categories, with two
messages that the production `LogVisibilityFilter` recognizes as diagnostics.
No owner log, Keychain item, owner media, source/destination selection,
transfer, notification, or update request was used. Neither `Check for
Updates` nor any transfer or notification action was clicked. The capture
fixture exits after writing the four PNGs.

The harness reports the requested view content dimensions in points; PNGs are
captured at 2x:

| States | Content points | PNG pixels |
|---|---:|---:|
| `*_TECH_LOG_EMPTY.png` | 1120×760 | 2240×1520 |
| `*_TECH_LOG_POPULATED.png` | 1120×760 | 2240×1520 |
| `*_TECH_LOG_DIAGNOSTICS.png` | 1120×760 | 2240×1520 |
| `*_TECH_LOG_MINIMUM.png` | 900×660 | 1800×1320 |

Reproduce from the repository root:

```sh
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch4/capture_native.py BEFORE handoffs/evidence/opendesign-visual-convergence-p2/patch4
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch4/capture_native.py PASS_A handoffs/evidence/opendesign-visual-convergence-p2/patch4
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch4/capture_native.py PASS_B handoffs/evidence/opendesign-visual-convergence-p2/patch4
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch4/capture_native.py AFTER handoffs/evidence/opendesign-visual-convergence-p2/patch4
```

The harness compiles the current `Assets.xcassets` into a temporary capture
app. Its fixture inputs and initializer replacement remain under this
evidence directory and do not change the production project or app behavior.
