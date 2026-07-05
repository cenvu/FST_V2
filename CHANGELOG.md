<!-- FST / CenVu | (+84) 842 841 222 -->

# Changelog

## v1.3.1 - 2026-07-05

### Added
* Manual GitHub release update-check in Technical Logs footer.
* Semantic version comparison for local vs latest GitHub Release.
* Browser handoff for release/download links.
* XCTest coverage for update-check backend foundation.

### Safety
* No auto-download or auto-install.
* No app bundle mutation.
* No Sparkle dependency.
* No transfer, verify, rsync, report, Safe To Eject, or Telegram behavior changed.

## v1.3.0 - 2026-07-05

* Added Telegram Notification MVP.
* Added new NOTIFICATION tab and updated tab order to TRANSFER / NOTIFICATION / TECHNICAL LOG.
* Added Telegram Bot setup with Keychain-backed bot token storage and chat ID settings.
* Added Test Message from the Notification tab.
* Added optional notification events for job start, heartbeat, transfer failure, copy completion, and verified SAFE TO EJECT.
* Added 15-minute default and 30-minute heartbeat interval options.
* Added compact and standard message detail options with path-safe message preview.
* Hardened Telegram response validation and heartbeat failure throttling.
* Removed accidental Return-key Test Message behavior.
* Improved Notification tab layout to fit without preview/outer scrollbar.

### Safety note:
* Telegram notification is best-effort only.
* Telegram failure never affects copy, verify, report generation, transfer result, app state, or Safe To Eject safety logic.
* Messages avoid full source/destination paths, manifests, checksums, private logs, and bot token exposure.
* Bundled rsync remains 3.4.4.
* Copy / Verify / Safe To Eject workflow unchanged.

### Known limitations:
* Telegram is the only notification provider in v1.3.0.
* No Slack, Discord, webhook, report upload, manifest upload, checksum upload, or custom template editor.
* Runtime delivery depends on user-created Telegram bot token and chat ID.

## v1.2.2 - 2026-07-04

* Updated macOS app icon with rounded icon asset.
* Refined header branding/contact presentation.
* Updated Technical Logs metadata/footer presentation.
* Minor UI polish for release identity and documentation consistency.
* No changes to transfer engine, verification engine, rsync command logic, report generation, or Safe To Eject safety logic.

### Safety note:
* Bundled rsync remains 3.4.4.
* Copy / Verify / Safe To Eject workflow unchanged.
* Data-safety behavior unchanged.

### Known limitations:
* Local build may not be signed/notarized.
* Runtime progress/ETA truthfulness remains a separate QA area.
