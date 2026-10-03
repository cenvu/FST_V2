# Capture method — transfer controls and language toggle

TASK=Visual Convergence Final Bounded Repair — Transfer Controls + Header Language Toggle
APPEARANCE=Dark Aqua
FIXTURES=SYNTHETIC_ONLY
LIVE_OPENDESIGN=UNAVAILABLE;TRANSPORT_CLOSED

The live OpenDesign context and artifact calls returned `Transport closed`.
The comparison fallback was the checked-in OpenDesign source at
`handoffs/evidence/opendesign-live-transfer-p1/live-source/assets/fst-c.css`
and `fst-c.js`, together with the owner-approved production screenshots in
`handoffs/evidence/final-owner-target-repair/` and the current task's visual
requirements.

`capture_native.py` compiles current production SwiftUI sources and a
task-local copy of `ContentView.swift` with a synthetic `TransferViewModel`
initializer. The production source files are not rewritten. It uses isolated
UserDefaults, an empty notification token store, a notification service that
traps if called, and disposable synthetic source/destination folders.

Each locale run captures 1120×760pt and 900×660pt Transfer Ready views plus a
synthetic Verifying layout. The 1120×760pt Ready fixture opens both dropdowns
using accessibility actions, captures each dark popover surface, selects
`50 MB/s` and `FULL 100%`, then asserts the corresponding bound values. It
also activates the header flag in each direction, waits for the locale update,
captures the changed screen, and switches back. All accessibility actions
target the isolated fixture only.

The Verifying fixture is presentation-only and carries synthetic metrics; no
transfer or verification process is started. All captures print
`transferStarted=NO notifySend=NO updateRequest=NO`. The actual app is never
sent a Telegram message, started, or asked to check for updates.

Run:

```bash
python3 handoffs/evidence/transfer-controls-language-toggle/capture_native.py EN handoffs/evidence/transfer-controls-language-toggle en .build/FST-VisualControlsToggle-Debug/Build/Products/Debug/FishSockTransfer.app/Contents/Resources
python3 handoffs/evidence/transfer-controls-language-toggle/capture_native.py VI handoffs/evidence/transfer-controls-language-toggle vi .build/FST-VisualControlsToggle-Debug/Build/Products/Debug/FishSockTransfer.app/Contents/Resources
```

The UI screenshots are 2240×1520px at nominal size and 1800×1320px at minimum
size. Dropdown menu screenshots capture the actual popover content surface.
