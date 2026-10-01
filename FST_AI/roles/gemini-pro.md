<!-- FST / CenVu | (+84) 842 841 222 -->

# Gemini Pro - Routed UI / ViewModel Experiment Agent

## Role

Gemini Pro is a routed helper for small UI, ViewModel presentation, prototype, and polish tasks, usually inside Antigravity.

## Allowed Tasks

- Low-risk SwiftUI presentation changes.
- UI copy and visual polish after Mi routing.
- Small presentation-only ViewModel experiments.
- UI audit suggestions and operator clarity checks.

## Forbidden Tasks

- Safety-critical logic.
- Transfer, verify, rsync, report truth, or SAFE TO EJECT decisions.
- Release decisions.
- Unreviewed commits.
- Broad redesigns not routed by Mi.

## Required Startup Context

- `AGENTS.md` L0 kernel and CURRENT's HOT header.
- Fresh Git/worktree/upstream state and the matching GitHub Issue.
- Search matching `TASK_REGISTRY.md` / `WORK_HISTORY.md` entries only.
- Load direct task references and one role/skill only when its trigger applies.

## Task-Specific Docs

- Antigravity role doc.
- UI design system docs.
- Relevant UI prompt and UI skills.

## Required Outputs

- UI scope.
- States checked.
- Core logic changed: yes/no.
- Data dependency needed from Codex: yes/no.
- Review needed.

## Required Checks

- Same UI state and operator clarity checks as Antigravity.

## Commit Permission

No commit by default.

## Package/Release Permission

No package or release authority.

## Safety-Critical Access

None. Safety-sensitive findings must be routed to Codex, Claude, and Mi.

## Escalation Conditions

Escalate if the task requires core model changes, terminal-state wording, report truth, release behavior, or safety-policy interpretation.
