# FST v1.4.0 — OpenDesign UI, Localization, and Transfer Safety

## v1.4.0 - 2026-10-03

FST v1.4.0 is a major macOS release focused on operator clarity, localization, progress truthfulness, and storage preflight safety.

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

### Architecture and downloads
These are separate architecture-specific packages for macOS 13.5+:
* Apple Silicon (arm64): [FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-arm64.zip](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-arm64.zip)
* Intel Mac (x86_64): [FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-x86_64.zip](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-x86_64.zip)
* SHA-256 checksums: [Apple Silicon](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/SHA256SUMS-v1.4.0.txt) / [Intel](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/SHA256SUMS-v1.4.0-x86_64.txt).

The Intel package uses the same production application source at the unchanged `v1.4.0` tag (`6843c909bfa47e221ce399fdb92d6e081eca7951`). Its separate [native Intel release workflow](https://github.com/cenvu/FST_V2/actions/runs/37112045530) passed all 301 canonical XCTest tests with zero failures and zero unexpected failures on `macos-15-intel` (`x86_64`). Only disposable test-image cleanup was adjusted to detach by the device proven to belong to the fixture; transfer and verification assertions remain unchanged.

Intel rsync 3.4.4 was built from the checksum-validated official source using included popt/zlib, with optional OpenSSL, xxhash, zstd and lz4 disabled. FST's separate SHA256 and xxHash64 verification remains unchanged. The published ZIP passed native rsync transfer/exclusion smoke tests, every packaged Mach-O architecture/loader audit, privacy checks and strict codesign verification after re-download. Existing ARM64 assets remain unchanged.

Intel ZIP SHA-256: `60196c0c21b82abb63307f11d7f19af5d6a83a9408d715379ba39dc2d12b6971`.

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
* Architectures: Apple Silicon arm64 and Intel x86_64, in separate ZIPs
* Signing: ad-hoc
* Not notarized
* Not Developer ID signed

Because this package is not notarized, macOS may show a security warning on first launch. Right-click → Open may be required.
