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

- macOS 13.5+ for the v1.3.3 local package
- Apple Silicon arm64 package
- SwiftUI
- MVVM / Coordinator / Service / Engine architecture
- Bundled rsync 3.4.4 only

## Runtime Progress, Notification, and Update Check Model

v1.3.3 includes destination activity observer metrics, optional Telegram notifications with request-construction hotfix, a manual GitHub release update-check for operator visibility, and packaged outbound network client entitlement for Telegram/GitHub HTTPS requests.

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
