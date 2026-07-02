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
