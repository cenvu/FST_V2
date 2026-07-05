# FST v1.3.3 — Network Permission Hotfix

## Highlights
- Fixed packaged/release builds failing outbound network access for manual update-check and Telegram notification workflows.
- Release builds now preserve the required outbound network entitlement when sandboxed.

## Safety
- No auto-download.
- No auto-install.
- No Sparkle dependency.
- No app bundle mutation.
- No transfer, verify, rsync, report, SAFE TO EJECT, or Telegram business logic changed.

## Technical
- Verified Debug and Release entitlement alignment.
- Verified packaged app entitlements.
- Confirmed outbound network client entitlement for GitHub and Telegram HTTPS requests.
- Confirmed no incoming network/server entitlement is added unless already required by the project.
