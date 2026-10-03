# FST v1.4.0 — Redesign

FST v1.4.0 redesigns the macOS interface for clearer media offload, progress tracking and verification results. Version 1.4.0, build 20261003, is available as separate Apple Silicon and Intel packages.

## Highlights

- Redesigned Transfer, Notification and Technical Log interface.
- In-app EN/VI language switching with a saved preference.
- Bandwidth presets: 50 / 75 / 100 / 125 / 150 / 175 / 200 MB/s / Unlimited.
- Clearer progress, current speed, average speed and ETA.
- Clearer checks that the destination has enough free space before copying.
- Copy All Logs and refined log presentation.
- Apple Silicon arm64 and Intel x86_64 support.

## Downloads

Requires macOS **13.5+**. Choose the ZIP for your Mac:

- [Apple Silicon (arm64) ZIP](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-arm64.zip)
- [Intel (x86_64) ZIP](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/FishSockTransfer-v1.4.0-b20261003-local-macOS13_5plus-x86_64.zip)
- SHA-256 checksums: [Apple Silicon](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/SHA256SUMS-v1.4.0.txt) · [Intel](https://github.com/cenvu/FST_V2/releases/download/v1.4.0/SHA256SUMS-v1.4.0-x86_64.txt).

## Verification

Both Mac packages were tested before release and use bundled rsync 3.4.4.

## Safety

- Source media remains read-only. FST does not format or eject source media.
- None performs copy only and ends at **TRANSFER COMPLETE**, never SAFE TO EJECT.
- Sample 33% uses **SHA256**; Full 100% uses non-cryptographic **xxHash64**.
- **SAFE TO EJECT** requires complete successful copy and successful required verification. Failure, cancellation, incomplete or uncertain results never authorize it.

## Signing

The packages are **ad-hoc signed**, **not notarized** and **not Developer ID signed**. macOS may require Right-click → Open on first launch.

## Third-party software

Redistributors should review the third-party licensing and corresponding-source requirements in [docs/legal/THIRD_PARTY_LICENSES.md](https://github.com/cenvu/FST_V2/blob/main/docs/legal/THIRD_PARTY_LICENSES.md).
