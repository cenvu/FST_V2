# Patch 1 native visual evidence

## Capture method

These are native macOS SwiftUI captures produced in the local Patch 1 worker session on 2026-10-02. The existing native capture harness is `handoffs/evidence/opendesign-live-transfer-p1/capture_native.py` with `CaptureNative.swift`. It compiled the current production view bodies; only the `ContentView` construction site was adjusted in the temporary compilation unit to inject an isolated `TransferViewModel`. The harness rendered through `NSHostingView` and wrote PNGs using AppKit's `bitmapImageRepForCachingDisplay` / `cacheDisplay` path.

The captures show the dark Aqua appearance at a nominal 1120 × 760 point content geometry and 2240 × 1520 pixels (2×). They capture the native content view and exclude macOS window chrome. The Notification and Technical Log screenshots were taken after selecting those existing tabs in the same native window.

## Fixture limits

The harness used its existing local-only fixture: temporary `CAM_A_CARD_001` and `OFFLOAD` directories, fixture metadata of 24 GB / 240 files / 4 folders, and 96 GB reported free space. It captured the READY state. It did not start a copy, verify media, send a Telegram message, run an update check, or touch owner media. Its temporary fixture directory is removed by the harness. The notification preview is the app's existing preview UI. No new business-state fixture or production behavior was introduced for these captures.

## Files

- `READY.png` — READY tab, dark Aqua, 1120 × 760 points, 2240 × 1520 pixels.
- `NOTIFICATION.png` — Notification tab, same window/appearance/geometry.
- `TECHNICAL_LOG.png` — Technical Log tab, same window/appearance/geometry.
- `CONTENTVIEW_PATCH1_REVIEWED.diff` — exact production diff inspected for this finalization.
