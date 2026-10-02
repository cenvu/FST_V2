# Capture Method

TASK=FINAL_OWNER_TARGET_VISUAL_REPAIR
CAPTURE_DATE=2026-10-03
APPEARANCE=Dark Aqua
LIVE_OPENDESIGN_REQUIRED=NO

`capture_native.py` compiles the current production SwiftUI source plus
`CaptureNative.swift`. It injects only a temporary initializer into a copied
`ContentView.swift` compilation unit so the harness can provide a synthetic
`TransferViewModel`, choose a tab/size, and seed the success-toast display
state. Production view bodies, action callbacks, business code, and the source
repository files are not rewritten by the harness. Localization resources are
copied from the canonical Debug build.

Run separately for each locale:

```bash
python3 handoffs/evidence/final-owner-target-repair/capture_native.py EN handoffs/evidence/final-owner-target-repair en .build/FST-OwnerTargetRepair-Debug/Build/Products/Debug/FishSockTransfer.app/Contents/Resources
python3 handoffs/evidence/final-owner-target-repair/capture_native.py VI handoffs/evidence/final-owner-target-repair vi .build/FST-OwnerTargetRepair-Debug/Build/Products/Debug/FishSockTransfer.app/Contents/Resources
```

The harness renders 1120×760 pt and 900×660 pt windows to 2× PNGs. It creates
temporary synthetic source/destination directories, isolated UserDefaults,
empty token storage, and a notification service that traps if invoked. The
bundled rsync path is used for truthful availability presentation only; no
transfer or verification is started. The update action is not activated.

Each run prints `transferStarted=NO notifySend=NO updateRequest=NO` for every
captured fixture. Capture output logs are ignored local build artifacts; the
checked-in harness, screenshots, and Markdown evidence are reproducible from
the repository.
