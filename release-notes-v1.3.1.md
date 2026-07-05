# FST v1.3.1 — Manual Update Check

## Highlights

- Added manual GitHub release update-check from the Technical Logs footer.
- FST can compare the installed app version with the latest GitHub Release.
- Update links open in the user's browser for manual download/install.

## Safety

- No auto-download.
- No auto-install.
- No app bundle mutation.
- No Sparkle dependency.
- Update check is disabled while copy/verification is running.
- No transfer, verify, rsync, report, SAFE TO FORMAT, or Telegram behavior changed.

## Technical

- Added SemanticVersion parser/comparator.
- Added GitHub release model and AppUpdateService.
- Added AppUpdateState model.
- Added Technical Logs footer update-check UI.
- Added XCTest coverage for semantic version/update-check foundation.

## Verification

- Build succeeded.
- Tests succeeded.
- git diff --check passed.

## Package

- FishSockTransfer-v1.3.1-b20260705-local-macOS13_5plus-arm64.zip
- macOS 13.5+
- Apple Silicon arm64 only
- Ad-hoc signed
- Not notarized
- Not Developer ID signed
