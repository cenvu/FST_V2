<!-- FST / CenVu | (+84) 842 841 222 -->

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

## AD-007: Progressive Disclosure & Backend Truth

Advanced information targets (e.g. filesystem, free capacity) should use a right-side inspector or inline disclosure. Do not invent or fake device metadata if not provided by backend.

## AD-008: Responsive Window Contract

The layout must define a minimum usable window size and adapt naturally without fixed heights for primary panels or disappearing controls. Main hierarchy remains stable on resize.

## AD-009: ETA Trust Contract

ETA is a responsive truthful estimate for the operator, not safety truth. It must never affect safe-to-eject gating. ETA should adapt to sustained throughput changes and avoid leaving stale values presented as current.

## AD-010: Intel Mac Support

Intel is a target requiring proof of safety, not a currently asserted support status. Apple Silicon and Intel Mac support must only be claimed when the complete bundled runtime is proven safe and repeatable.

