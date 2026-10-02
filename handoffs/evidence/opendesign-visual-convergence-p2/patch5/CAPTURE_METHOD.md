# Patch 5 capture method

DESIGN_AUTHORITY=FST_AI/design-system/MASTER.md;FST_AI/design-system/REDESIGN_VNEXT.md;canonical frozen OpenDesign source;accepted Patch 1–4 evidence
LIVE_MCP_REQUIRED=NO
CAPTURE_RUNTIME=NATIVE_SWIFTUI_APPKIT
APPEARANCE=DARK_AQUA
NOMINAL_CONTENT=1120x760 points;2240x1520 pixels
MINIMUM_CONTENT=900x660 points;1800x1320 pixels
PRODUCTION_SOURCE=HEAD 28c8a486d73b71da9dc64cebdee71a432dc27bda

`capture_native.py` compiles the repository's native Swift sources and assets
into a temporary capture app. A temporary copy of `ContentView.swift` changes
only its construction site to inject a fixture model and select a tab. The
production view bodies and the rest of the source are compiled unchanged. The
native `NSWindow`/`NSHostingView` renders the full app content; captures use
AppKit bitmap output with no browser, WebView, HTML runtime, or image edit.

Fixtures use a unique in-memory UserDefaults domain, an empty fake token store,
a no-send NotificationService that traps if called, synthetic temporary
source/destination paths, deterministic metadata, and fixed synthetic log
timestamps. The fixture directory is created by the capture process and
removed by its own cleanup path. The only bundled-rsync interaction is the
existing availability/version probe used by the truthful app presentation;
no copy or verification starts. No owner media, owner logs, Keychain values,
credentials, Telegram send, update request, or real transfer is used.

Captured states include every required nominal state: Ready, Copying,
Verifying, Transfer Complete with verification mode `none`, Safe to Eject,
Transfer Error, Cancelled, Notification, empty Technical Log, and populated
Technical Log. The existing `.validating` state and tested
`MANUAL CHECK REQUIRED` presentation are also captured. Minimum captures cover
Ready, Safe to Eject, Transfer Error, Notification, and Technical Log. The
capture records exact scroll extents; supplemental minimum scrolled images
show the full Transfer tail and the entire Notification settings document.

Every fixture is reset to the top before its primary image to avoid inheriting
a previous window scroll position. Bottom captures are explicitly labeled
`*_SCROLLED.png`. Each state uses a fresh view model and no action is clicked.
`CAPTURE_BEFORE.log.gz` and `CAPTURE_AFTER.log.gz` preserve the exact
fixture/state, geometry, scroll extent, and no-operation records; extract with
`gzip -dc`.

Reproduce from the repository root:

```sh
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch5/capture_native.py BEFORE handoffs/evidence/opendesign-visual-convergence-p2/patch5
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch5/capture_native.py AFTER handoffs/evidence/opendesign-visual-convergence-p2/patch5
```

The AFTER source is unchanged from BEFORE. The complete PNG pairs are
byte-identical; image dimensions and comparison results are indexed in
`EVIDENCE_INDEX.md`.
