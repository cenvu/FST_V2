<!-- FST / CenVu | (+84) 842 841 222 -->

# Changelog

## v1.3.4 - 2026-07-06

### Changed
* Hardened Detailed TXT Report V1 sections for clearer operator review.
* Added a bilingual disclaimer near the top of generated reports.
* Removed obsolete safety wording from active report output.
* Clarified final verified success wording as SAFE TO EJECT DESTINATION.
* Updated report filenames and job IDs so they no longer use the source name.
* Reduced operator-facing rsync detail to rsync 3.4.4.
* Added a technical log sharing note to report output.
* Updated tests for report wording safety.

### Safety
* FST reports copy and verification results only. Decisions to erase, format, or reuse source media remain the user's responsibility.
* SAFE TO EJECT applies to destination eject safety evidence only.
* No transfer, verify/hash, rsync, Telegram, update-check, or UI layout behavior changed.
* v1.3.3 remains the packaged network permission / entitlement hotfix release.

## v1.3.3 - 2026-07-06

### Fixed
* Fixed packaged/release app failing outbound network workflows used by GitHub update-check and Telegram notification.
* Ensured sandboxed release builds include and preserve the outbound network client entitlement.

### Safety
* No auto-download or auto-install.
* No Sparkle dependency.
* No app bundle mutation.
* No transfer, verify, rsync, report, SAFE TO EJECT, or Telegram business logic changed.

## v1.3.2 - 2026-07-06

### Fixed
* Fixed Telegram API request construction for reliable test and runtime notification delivery.
* Reduced repeated Telegram warning/log noise when notification delivery fails.
* Preserved Notification tab layout fixes and tab order: TRANSFER / NOTIFICATION / TECHNICAL LOG.

### Verification
* Confirmed manual Check for Updates compatibility with GitHub Release tag `v1.3.2`.

### Safety
* Telegram notification remains best-effort visibility only.
* No auto-download or auto-install.
* No app bundle mutation.
* No Sparkle dependency.
* No transfer, verify, rsync, report, or SAFE TO EJECT safety behavior changed.

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
* No transfer, verify, rsync, report, SAFE TO EJECT, or Telegram behavior changed.

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
* Telegram failure never affects copy, verify, report generation, transfer result, app state, or SAFE TO EJECT safety logic.
* Messages avoid full source/destination paths, manifests, checksums, private logs, and bot token exposure.
* Bundled rsync remains 3.4.4.
* Copy / Verify / SAFE TO EJECT workflow unchanged.

### Known limitations:
* Telegram is the only notification provider in v1.3.0.
* No Slack, Discord, webhook, report upload, manifest upload, checksum upload, or custom template editor.
* Runtime delivery depends on user-created Telegram bot token and chat ID.

## v1.2.2 - 2026-07-04

* Updated macOS app icon with rounded icon asset.
* Refined header branding/contact presentation.
* Updated Technical Logs metadata/footer presentation.
* Minor UI polish for release identity and documentation consistency.
* No changes to transfer engine, verification engine, rsync command logic, report generation, or SAFE TO EJECT safety logic.

### Safety note:
* Bundled rsync remains 3.4.4.
* Copy / Verify / SAFE TO EJECT workflow unchanged.
* Data-safety behavior unchanged.

### Known limitations:
* Local build may not be signed/notarized.
* Runtime progress/ETA truthfulness remains a separate QA area.
