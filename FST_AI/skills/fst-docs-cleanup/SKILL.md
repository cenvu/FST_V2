<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-docs-cleanup
description: Safely audit and refactor FST docs, authority hierarchy, archive removal, links, and safety wording.
---

# Skill: fst-docs-cleanup

## Purpose

Guide safe documentation audits and refactors without changing FST runtime behavior.

## When to Use

Use for source-of-truth cleanup, archive removal, role/skill docs, prompt/template cleanup, link repair, wording scans, and memory/history updates.

## Owner Agent

Codex implements docs cleanup. Mi reviews authority changes. Claude reviews safety wording when needed.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/WORK_HISTORY.md`
- `FST_AI/memory/TASK_REGISTRY.md`
- `docs/00_AI_AGENT_START_HERE.md`

## Inputs

- Target docs.
- Requested authority changes.
- Markdown inventory.
- Wording scan results.
- Link/reference scan results.

## Safety Boundaries

- No Swift/source/runtime/package/release metadata changes.
- Do not weaken SAFE TO EJECT policy.
- Do not reintroduce format/erase authorization wording.
- Do not delete ambiguous non-doc folders without inventory and user approval.

## Procedure

1. Inventory affected Markdown.
2. Identify authority, duplicate, archive, and user-facing docs.
3. Patch smallest safe doc surface.
4. Repair or remove stale links.
5. Run safety wording scan.
6. Update `WORK_HISTORY.md` and `TASK_REGISTRY.md`.

## Required Checks

- `git diff --check`.
- `git status --short`.
- `git diff --stat`.
- Wording scan for obsolete safety terms.
- Link/path sanity for changed docs.

## Output Format

PHASE:

FILES:

LAYER CHECK:

PATCH:

TESTS:

VERIFY:

## Stop / Escalate If

- A doc conflict changes safety policy.
- Archive content may contain unique active requirements.
- User approval is needed before deletion.

## Do Not

- Edit Swift code.
- Package, tag, push, or publish.
- Paste long external content.
