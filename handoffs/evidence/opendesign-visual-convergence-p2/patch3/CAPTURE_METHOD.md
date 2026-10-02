# Native Notification capture method

DESIGN_AUTHORITY=CANONICAL_FROZEN_SOURCE_MAP
LIVE_MCP_REQUIRED=NO
LIVE_VS_FROZEN_DIFF=UNKNOWN
FIXTURE_SEMANTICS_COPIED=NO

Reused the Patch 2 native AppKit/SwiftUI capture approach, with repo-local `capture_native.py` and `CaptureNative.swift`. No browser, HTML runtime, WebView, OpenDesign call, or tooling/config repair. BEFORE ran and completed before production mutation. BEFORE compiles Swift files from START_HEAD=745022a8039cd237ced073159afbc0478898ae74 via git show into a temporary directory; PASS_A/AFTER compile current production Swift verbatim. Only a temporary ContentView compilation unit injects the isolated model and selects the Notification tab. The actual ContentView and all other production paths remain untouched.

Commands (from repository root):

```sh
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch3/capture_native.py BEFORE handoffs/evidence/opendesign-visual-convergence-p2/patch3
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch3/capture_native.py PASS_A handoffs/evidence/opendesign-visual-convergence-p2/patch3
python3 handoffs/evidence/opendesign-visual-convergence-p2/patch3/capture_native.py AFTER handoffs/evidence/opendesign-visual-convergence-p2/patch3
```

All images use native Dark Aqua. Entire app content bounds (header/tab/footer included; title bar excluded): nominal 1120x760 points / 2240x1520 pixels; minimum 900x660 points / 1800x1320 pixels. Notification viewport is 665pt nominal and 565pt minimum. Production min dimensions and accepted shell remain intact. Capture uses NSHostingView cacheDisplay at native 2x scale without image alteration.

Deterministic model states: default NotificationSettings with empty token/chat ID; configured enabled settings with clearly synthetic Chat ID, masked non-secret token, 30-minute interval and Compact detail. Each uses a unique isolated UserDefaults suite removed after capture, a fake token store that never accesses Keychain, null bookmarks, and injected NoSendService that fatally rejects any delivery attempt. No Test Message click, transfer start, folder selection, real source media, or network notification occurred. Runtime status uses the existing production mapping; preview uses the existing factory. A supplemental minimum long-error state sets an explicitly synthetic NotificationRuntimeStatus in the capture harness only.

Final supplemental captures scroll the native NSScrollView to the document bottom. AFTER_NOTIFICATION_SCROLLED confirms nominal extent 24pt; AFTER_NOTIFICATION_MINIMUM_SCROLLED confirms minimum extent 137pt (702pt document / 565pt viewport), all five events and both options fully visible, no horizontal scroll. AFTER_NOTIFICATION_LONG_ERROR and its scrolled variant demonstrate wrapped error text and preview access at minimum. Header/footer stay fixed; no controls are compressed out of the scroll document.

Pass A and final primary captures are independent runs of identical production source. The final harness adds supplemental captures only. No Pass B production edit occurred. Capture logs preserve native compiler warnings, including pre-existing macOS onChange deprecation warnings.
