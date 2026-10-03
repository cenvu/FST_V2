# FST v1.4.0 — OpenDesign UI, Localization, and Transfer Safety

## v1.4.0 - 2026-10-03

FST v1.4.0 is a major Apple Silicon release focused on operator clarity, localization, progress truthfulness, and storage preflight safety.

### Highlights
* Converged the production SwiftUI interface on the approved OpenDesign Hybrid Progressive direction.
* Refined the Transfer, Notification, and Technical Log workspaces for compact DIT operation.
* Added persistent in-app English/Vietnamese presentation switching.
* Finalized bandwidth choices at 50 / 75 / 100 / 125 / 150 / 175 / 200 MB/s and Unlimited.
* Improved progress2-derived progress, copy speed, average speed, ETA, and current-item presentation.
* Strengthened destination-capacity readiness and filesystem-aware preflight behavior.
* Added Copy All Logs and refined Technical Log operator controls.

### Verification
This GitHub Release is created only after the release workflow completes all gates on a GitHub-hosted Apple Silicon macOS runner:
* full canonical XCTest suite
* Release build/package for arm64
* version/build metadata validation
* bundled rsync 3.4.4 validation
* bundled dylib architecture/linkage validation
* ad-hoc codesign verification
* zip-content validation
* SHA-256 checksum generation
* packaged-app privacy scan for local user paths and common credential/token patterns

### Privacy
* The owner-provided review screenshots are not included as release assets.
* Telegram bot tokens, runtime chat settings, local source/destination selections, and machine-specific user paths are not bundled into the release package.
* Telegram credentials remain runtime user data; the bot token is stored through the app's Keychain-backed flow.

### Safety
* Source media remains read-only.
* Production transfer continues to use bundled rsync 3.4.4 only.
* Verification mode None ends at TRANSFER COMPLETE and never SAFE TO EJECT.
* SAFE TO EJECT still requires successful complete copy and successful required verification.
* FST does not format or eject source media.

### Package
* Version: 1.4.0
* Build: 20261003
* Platform: macOS 13.5+
* Architecture: Apple Silicon arm64
* Signing: ad-hoc
* Not notarized
* Not Developer ID signed

Because this package is not notarized, macOS may show a security warning on first launch. Right-click → Open may be required.
