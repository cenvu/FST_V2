<!-- FST / CenVu | (+84) 842 841 222 -->

# FST Project Baseline

FST is a professional macOS application for DIT/Data Wrangler workflows.

Primary workflow:

```text
SOURCE -> COPY -> VERIFY -> SAFE TO EJECT
```

Primary goal:

Maximum data integrity and truthful operator handoff.

The app is inspired by professional offload tools but focused on a lightweight MVP for cinema data management workflows.

## Platform

- macOS 13.5+ for the v1.3.4 local package
- Apple Silicon arm64 package
- SwiftUI
- MVVM / Coordinator / Service / Engine architecture
- Bundled rsync 3.4.4 only

## Detailed TXT Report V1 Safety Model

v1.3.4 hardens Detailed TXT Report V1 and safety wording. Generated report output must describe verified success as SAFE TO EJECT DESTINATION, disclose that FST reports copy and verification results only, and avoid implying permission to erase, format, or reuse source media.

This release does not change transfer, verify, rsync, Telegram, update-check, or UI layout behavior.

## Runtime Progress, Notification, and Update Check Model

v1.3.3 fixes packaged/release build outbound network permission by preserving the app’s sandbox network client entitlement. This allows manual GitHub update-check and Telegram notification workflows to use outbound HTTPS as intended. The release does not add auto-download, auto-install, Sparkle, app bundle mutation, or any transfer/verify/rsync/report/SAFE TO EJECT/Telegram business logic changes.

Truth layers:

- Safety truth: verification result, report generation, and SAFE TO EJECT.
- Transfer truth: bundled rsync 3.4.4 lifecycle, exit status, errors, and cancellation.
- Operator truth: copied bytes/files/current item/speed/ETA shown in UI, optional best-effort Telegram notifications, plus manual update-check status.

Observer metrics, Telegram delivery, and update-check status must never influence copy success, verify success, report truth, transfer state, or SAFE TO EJECT. The update-check must never auto-download, auto-install, mutate the app bundle, use Sparkle, or run as a background updater.

## MVP Scope

Locked MVP:

- Single source
- Single destination
- Single job
- Copy
- Verify
- SAFE TO EJECT after copy success and verification pass
- Detailed TXT Report V1

Deferred:

- Multi-destination
- Database
- PDF report
- Project dashboard
- Report viewer
- Cloud sync
- Parallel jobs

## Core Rule

Never sacrifice data safety for speed, convenience, or UI polish.

FST does not format media and does not eject media. It provides evidence for operator handoff.
