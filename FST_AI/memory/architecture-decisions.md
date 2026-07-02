# Architecture Decisions

## AD-001: Bundled rsync only

FST must use bundled rsync 3.4.4 only.

Apple system rsync fallback is not allowed because version differences and behavior differences can undermine repeatability.

Homebrew, MacPorts, or other non-bundled rsync fallback is also not allowed.

## AD-002: MVP single job

FST MVP is single source, single destination, single job.

Multi-destination and parallel jobs are deferred.

## AD-003: Safety before performance

Performance improvements are welcome only after safety and correctness are preserved.

## AD-004: TXT report before PDF report

Detailed TXT Report V1 is prioritized before PDF or visual report formats.

## AD-005: Agent ownership

Antigravity/Gemini Pro owns SwiftUI/UI/UX implementation when routed by Mi.

Codex owns core logic implementation.

Claude owns primary review/QA/safety.

Mi owns final routing and safety gate.

## AD-006: SAFE TO EJECT language

Operator-facing UI, logs, reports, and docs must use SAFE TO EJECT for verified success.

The internal state name `safeToFormat` is legacy and should not leak into operator-facing wording.

