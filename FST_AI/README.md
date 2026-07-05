<!-- FST / CenVu | (+84) 842 841 222 -->

# FST AI Engineering System

`FST_AI/` is the internal AI workflow layer for FishSock Transfer.

It defines how Mi, Codex, Claude, and Antigravity/Gemini Pro should collaborate on FST without losing scope, safety, or project context.

## Purpose

This folder exists to make AI-assisted development safer, more repeatable, and easier to review.

FST is a DIT/Data Wrangler application where data integrity is more important than speed or convenience. Any mistake in Copy, Verify, SAFE TO EJECT, bundled rsync handling, progress reporting, or final report generation can create serious operational risk.

This folder standardizes:

- Agent roles
- Project memory
- Safety rules
- Skill playbooks
- Review workflows
- Prompt templates
- Release gates

## Current Agent Model

- Mi / Command Center: Technical Lead, Safety Gate, Prompt Architect, Workflow Router.
- Codex: Main Core Coding Agent, Secondary Reviewer.
- Claude: Main QA, Main Code Reviewer, Main Safety Reviewer, Secondary Coding Agent when explicitly routed.
- Antigravity / Gemini Pro: Main UI Coding Agent for SwiftUI/UI/UX.

## Core Principle

Never allow convenience, speed, UI polish, or agent autonomy to override data safety.

Source media must be treated as read-only. FST must copy from source, verify against source, and report results, but must never mutate or delete source media.

Priority order:

1. Data Safety
2. Reliability
3. Truthful Operator Feedback
4. Repeatability
5. Maintainability
6. Performance
7. Convenience

## FST MVP Scope

Current locked scope:

- Single source
- Single destination
- Single job
- Copy -> Verify -> SAFE TO EJECT
- Bundled rsync 3.4.4 only
- No Apple/System/Homebrew rsync fallback
- Detailed TXT Report V1 before advanced features

## v1.3.2 Notification and Manual Update Check Safety Model

v1.3.2 is the Telegram notification hotfix and Manual GitHub Update Check compatibility release.

FST separates three kinds of truth:

- Safety truth: verification result, report generation, and SAFE TO EJECT.
- Transfer truth: bundled rsync 3.4.4 lifecycle, exit status, errors, and cancellation.
- Operator truth: destination observer metrics, optional Telegram notifications, and manual update-check status for visibility only.

The destination activity observer, Telegram notification delivery, and manual update-check are visibility-only. They must never decide copy success, verification success, final report truth, transfer state, or SAFE TO EJECT. The update-check must never auto-download, auto-install, mutate the app bundle, use Sparkle, or run as a background updater.

Deferred:

- Multi-destination
- Database
- PDF report
- Cloud sync
- Project dashboard
- Report viewer
- Parallel multi-job engine

## How To Use

For core logic tasks:

1. Mi classifies the task.
2. Codex implements the smallest safe core change.
3. Claude performs primary QA/code/safety review.
4. Codex revises if Claude rejects.
5. Mi performs final safety gate.

For UI tasks:

1. Mi confirms the task is UI-only.
2. Antigravity/Gemini Pro implements SwiftUI/UI changes.
3. Claude or Mi reviews UI state risk.
4. Mi performs final approval.

For safety-critical tasks:

1. Mi marks the task as safety-critical.
2. Codex implements only the smallest safe change.
3. Claude performs primary safety review.
4. Codex revises if required.
5. Claude rechecks.
6. Mi decides merge/no-merge.

## Batch 2 Core Review Skills

Batch 2 adds deeper core-engine review playbooks for Claude and Codex:

- `fst-rsync-engine-review`
- `fst-verify-engine-review`
- `fst-state-machine-review`
- `fst-detailed-txt-report`
- `fst-error-handling-review`
- `fst-report-correctness-review`

Use these when Codex modifies rsync, verify, state machine, report, error handling, or any logic that can affect SAFE TO EJECT.

Recommended routing:

1. Codex implements the smallest safe change.
2. Claude reviews with the relevant Batch 2 skill.
3. Codex revises if Claude rejects.
4. Mi performs final safety gate.

## Batch 3 Prompt Pack and QA Templates

Batch 3 adds daily-use prompt and QA templates:

- Codex implementation handoff
- Claude review report
- Runtime QA matrix
- Runtime test evidence
- Mi final decision
- Antigravity/Gemini UI handoff
- Bug intake form
- Change risk classification

Use these templates to reduce repeated prompting and make Codex -> Claude -> Mi handoff consistent.

Recommended daily loop:

1. Fill bug intake or change risk classification.
2. Route to the correct agent.
3. Codex or Antigravity/Gemini implements.
4. Agent completes handoff template.
5. Claude reviews using the relevant skills.
6. Mi decides accept/revise/reject/runtime QA.
7. Runtime evidence is recorded before release-sensitive changes are accepted.

## UI Design System Pack

FST also includes a controlled UI design system layer inspired by UI/UX design-system skill patterns.

This layer is documentation-only and does not install external UI skill packages.

Use it for:

- Antigravity/Gemini UI work
- SwiftUI design direction
- Progress/dashboard hierarchy
- Accessibility review
- Operator clarity review
- UI anti-pattern filtering

Primary files:

- `FST_AI/design-system/MASTER.md`
- `FST_AI/design-system/pages/`
- `FST_AI/design-system/audits/`
- `FST_AI/skills/fst-ui-design-system/`
- `FST_AI/skills/fst-ui-visual-audit/`
- `FST_AI/skills/fst-ui-accessibility-review/`
- `FST_AI/skills/fst-progress-dashboard-design/`

Do not install or run external UI skill CLI tools inside FST unless Mi explicitly approves it.

## What Not To Do

Do not:

- Install random agent plugins directly into the project.
- Run unreviewed hooks or scripts.
- Let an AI agent add dependencies without approval.
- Let Antigravity/Gemini modify core transfer/verify/safety logic.
- Let Codex redesign UI unless explicitly asked.
- Let Claude rewrite core logic without a scoped implementation request.
- Expand MVP scope without Mi approval.
- Mark anything SAFE TO EJECT unless copy success and verification pass prove it.
