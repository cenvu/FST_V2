<!-- FST / CenVu | (+84) 842 841 222 -->

# FST v1.3.0 — Telegram Notification MVP

Local Apple Silicon build for testing and early use.

## Highlights

- Added new NOTIFICATION tab.
- Updated tab order to TRANSFER / NOTIFICATION / TECHNICAL LOG.
- Added Telegram Bot notification support.
- Added Test Message from Notification tab.
- Added notification events:
  - Job starts.
  - Heartbeat while running.
  - Transfer fails.
  - Copy completed.
  - Verify completed / Safe to eject.
- Added heartbeat interval options:
  - 15 minutes default.
  - 30 minutes.
- Added path-safe message preview.
- Added Keychain-backed Telegram bot token storage.
- Added outgoing network entitlement for Telegram notification.
- Hardened Telegram response validation.
- Added heartbeat failure throttling to avoid retry/log spam.
- Removed accidental Return-key Test Message behavior.
- Improved Notification tab layout so it fits without preview/outer scrollbar.
- Runtime Telegram delivery verified with real bot/chat setup by project owner.

## Safety Notes

- Telegram notification is best-effort only.
- Telegram failure never affects copy, verify, report generation, transfer result, app state, or SAFE TO EJECT semantics.
- Messages avoid full source/destination paths, manifests, checksums, private logs, and bot token exposure.
- Failure message includes:
  `Do NOT format source media. Open FST report and technical log before deciding.`
- Success message uses:
  `SAFE TO EJECT / VERIFIED OK`

## Known Limitations

- Telegram is the only notification provider in v1.3.0.
- No Slack/Discord/webhook support.
- No report/manifest/checksum upload through Telegram.
- No custom message template editor.
- Runtime delivery still depends on user-created Telegram bot token and chat ID.

## Package

- FishSockTransfer-v1.3-b20260705-local-macOS13_5plus-arm64.zip

## SHA256

d946bd411bd5f3547812190aecbb28c94c609b05e558a5dcb9b4c4ae2f4e435f  FishSockTransfer-v1.3-b20260705-local-macOS13_5plus-arm64.zip

## Platform

- macOS 13.5+
- Apple Silicon arm64

## Signing

This build is:

- Ad-hoc signed
- Not notarized
- Not Developer ID signed

macOS may show a warning on first launch. Use right-click -> Open for the first launch.

## Workflow

Copy -> Verify -> Safe To Eject

## Safety Reminder

Only eject or remove source media when FST shows SAFE TO EJECT and the operator has reviewed the workflow requirements.
