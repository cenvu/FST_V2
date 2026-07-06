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

## Documentation & Repository Hygiene Audit
- **Wording Alignment:** Standardized "SAFE TO EJECT" globally and removed obsolete formatting-safety wording from active documentation.
- **Workflow Standardization:** Confirmed wording `Copy -> Verify -> Safe To Eject -> Report` globally.
- **Archive Cleanup:** Moved deprecated and duplicate release notes into `docs/archive/`.
- **MVP Scope Clarified:** Ensured all active docs clearly reflect single source, single destination, single active job, bundled rsync 3.4.4, and no Apple system rsync fallback.
- **AI Agent Docs:** Confirmed active alignment of Agent roles (Codex for core, Antigravity for UI, Claude for QA/Review, Mi for safety/lead). Verified Roo/RooCode is completely out of scope.
- **Safety Guarantee:** Verified no Swift logic, verification engine, transfer engine, tests, scripts, release assets, or UI images were changed during this documentation-only audit.
