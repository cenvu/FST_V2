# Visual convergence capture method

TASK=Visual Convergence Finalization — Technical Log Canonical Match + Copy All Logs
CAPTURE_DATE=2026-10-03
APPEARANCE=Dark Aqua
FIXTURES=SYNTHETIC_ONLY
OPERATIONS=TRANSFER_NONE;NOTIFICATION_SEND_NONE;UPDATE_REQUEST_NONE

`capture_native.py` compiles the production SwiftUI views with a task-local
initializer seam in `ContentView.swift`; the production view bodies and the
other production sources remain byte-identical in the capture build. Fixtures
use isolated UserDefaults, empty notification credentials, a notification
service that traps if called, and a synthetic rsync executable reference. No
transfer or network action is invoked. The notification and transfer content
is produced by the current production views.

The capture process uses the built app's `en.lproj` and `vi.lproj` catalog
resources and `CFBundleDevelopmentRegion=en`. Window sizes are 1120×760pt and
900×660pt. PNG backing dimensions are 2240×1520 and 1800×1320 respectively.
Minimum-size Notification has a second scrolled capture because its content
extends below the window; the fixed header remains visible.

## Captures

For each language prefix (`EN`, `VI`):

- `*_TRANSFER_READY.png`, `*_TRANSFER_READY_MINIMUM.png`
- `*_NOTIFICATION.png`, `*_NOTIFICATION_MINIMUM.png`,
  `*_NOTIFICATION_MINIMUM_SCROLLED.png`
- `*_TECH_LOG_EMPTY.png`, `*_TECH_LOG_POPULATED.png`,
  `*_TECH_LOG_DIAGNOSTICS.png`, `*_TECH_LOG_MINIMUM.png`

Capture output logs are `CAPTURE_EN.log` and `CAPTURE_VI.log`. The fixture
prints `transferStarted=NO notifySend=NO updateRequest=NO` for every screen.

## Comparison references

- `handoffs/evidence/opendesign-live-transfer-p1/QA_TECHNICAL_LOG.png`
- `handoffs/evidence/opendesign-visual-convergence-p2/patch5/AFTER_TECH_LOG_POPULATED.png`
- `handoffs/evidence/opendesign-visual-convergence-p2/patch4/PASS_B_TECH_LOG_POPULATED.png`
- Frozen source: `handoffs/evidence/opendesign-live-transfer-p1/live-source/assets/fst-c.js`,
  `logSurface()` and `showLogDetails()`

OpenDesign MCP was attempted for current context and projects but its transport
was unavailable, so checked-in owner-approved screenshots and frozen source
were used as the canonical comparison material.
