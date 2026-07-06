# FST Task Registry

## Purpose

Track meaningful AI/Codex task batches so future agents can detect repeated prompts.

## Rule

Before running a new task, Codex must check this registry and `FST_AI/memory/WORK_HISTORY.md`.

If the same or substantially similar task already exists, Codex must stop and ask:

```text
This appears to have been run before as <entry>. Do you want to rerun it, continue it, or review previous output?
```

## Entry Format

- Date:
- Task ID:
- Task name:
- Agent:
- Status: planned / implemented / blocked / superseded
- Files changed:
- Commit/tag/release:
- Safety impact:
- Checks:
- Notes:

## Recent Tasks

### 2026-07-06 - Batch AI-3A minor fix patch after AI-3 review

- Date: 2026-07-06
- Task ID: Batch AI-3A
- Task name: Minor Fix Patch After AI-3 Review
- Agent: Codex
- Status: implemented
- Files changed: `AGENTS.md`, `docs/00_AI_AGENT_START_HERE.md`, `FST_AI/memory/agent-roles.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/roles/release-gate.md`, normalized older `FST_AI/skills/*/SKILL.md`
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: docs/skills only; no Swift/runtime logic
- Checks: `git diff --check`, `git status --short`, `git diff --stat`, targeted wording scans
- Notes: aligned AGENTS role/archive wording, normalized remaining older skills, and clarified release gate is a skill/checklist, not an agent role

### 2026-07-06 - Batch AI-2 docs, skills, memory, harness, and archive cleanup

- Date: 2026-07-06
- Task ID: Batch AI-2
- Task name: FST AI Agent Docs, Skills, Memory, Harness, and Archive Cleanup
- Agent: Codex
- Status: implemented
- Files changed: `AGENTS.md`, `FST_AI/README.md`, `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/TASK_REGISTRY.md`, `FST_AI/memory/WORK_HISTORY.md`, `FST_AI/memory/agent-roles.md`, `FST_AI/memory/project-baseline.md`, `FST_AI/prompts/README.md`, `FST_AI/research/AI_AGENT_SKILL_REFERENCE_NOTES.md`, `FST_AI/roles/`, focused `FST_AI/skills/`, `docs/00_AI_AGENT_START_HERE.md`, `docs/03_PROJECT_MASTER_GUIDELINE.md`, `docs/releases/release-notes-v1.3.3.md`, deleted `docs/archive/**/*.md`
- Commit/tag/release: not committed, not tagged, not released
- Safety impact: documentation workflow only; no Swift/runtime logic
- Checks: `git diff --check`, `git status --short`, `git diff --stat`, wording/link scan, Markdown path sanity
- Notes: implemented after Batch AI-1 audit; no package/tag/push

### 2026-07-06 - Batch AI-1 audit

- Date: 2026-07-06
- Task ID: Batch AI-1
- Task name: FST AI Agent System Audit and Role Hierarchy Redesign
- Agent: Codex
- Status: implemented
- Files changed: none
- Commit/tag/release: no commit, no tag, no release
- Safety impact: read-only audit; no source/runtime changes
- Checks: Markdown inventory and repo state inspection
- Notes: recommended Batch AI-2 docs-only cleanup

### 2026-07-06 - Persistent Command Center handover memory

- Date: 2026-07-06
- Task ID: AI handover memory
- Task name: Create persistent Command Center handover memory and wire it into agent-facing docs
- Agent: Codex
- Status: implemented
- Files changed: `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`, `FST_AI/memory/WORK_HISTORY.md`, `AGENTS.md`, `FST_AI/README.md`, `docs/00_AI_AGENT_START_HERE.md`, `docs/03_PROJECT_MASTER_GUIDELINE.md`
- Commit/tag/release: `a04ba55 docs: add persistent command center handover memory`
- Safety impact: documentation workflow only; no Swift/runtime logic
- Checks: `git diff --check`
- Notes: established current handover and history files
