# FST v1.3.2 — Telegram Notification Fix

## Purpose

v1.3.2 is a Telegram notification hotfix and Check Update compatibility release.

This release is intended to verify that the manual Technical Logs footer Check for Updates button can detect `v1.3.2` from GitHub Releases.

## Highlights

- Keeps the Telegram Notification MVP introduced in v1.3.0.
- Keeps tab order: TRANSFER / NOTIFICATION / TECHNICAL LOG.
- Fixes Telegram API request construction for test and runtime notifications.
- Reduces repeated Telegram warning/log noise when delivery fails.
- Preserves Notification tab layout fixes.
- Confirms manual Check for Updates compatibility with GitHub release tag `v1.3.2`.

## Safety

- Telegram notification remains best-effort visibility only.
- Telegram success or failure never decides copy success, verification success, report truth, transfer state, or SAFE TO EJECT.
- No auto-download.
- No auto-install.
- No app bundle mutation.
- No Sparkle dependency.
- No background updater.
- No transfer, verify, rsync, report, or SAFE TO EJECT behavior changed.

## Package

- FishSockTransfer-v1.3.2-b20260706-local-macOS13_5plus-arm64.zip
- SHA256: `b8b9b09acb197afa44ba05926772000aa54cfb371dcb17a7ba822040eb2a6ff4`
- macOS 13.5+
- Apple Silicon arm64 only
- Ad-hoc signed
- Not notarized
- Not Developer ID signed

## Operator Note

Because this is not notarized, macOS may show a security warning on first launch. Use Right-click -> Open if needed.
