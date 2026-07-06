<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-diagnose-bug
description: Diagnose FST bugs using evidence-first debugging before implementation.
---

# Skill: fst-diagnose-bug

## Purpose

Diagnose FST bugs before implementing fixes.

## When to Use

Use when copy, verify, progress, ETA, report, SAFE TO EJECT, UI state, permission, or file-system behavior appears wrong.

## Owner Agent

Codex diagnoses. Claude reviews safety-sensitive diagnosis. Mi routes if scope is unclear.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/TASK_REGISTRY.md`
- `FST_AI/memory/known-issues.md`

## Inputs

- Observed behavior.
- Expected behavior.
- Logs/screenshots if available.
- Source/destination size and file count if relevant.
- Current branch/commit.

## Safety Boundaries

- Do not change SAFE TO EJECT logic without explicit task scope.
- Do not hide core bugs with UI wording.
- Do not mutate source media during diagnosis.

## Procedure

1. Restate observed and expected behavior.
2. Classify phase: Copy / Verify / Report / UI / Safety / Permission.
3. Identify likely subsystem.
4. List evidence needed.
5. Locate likely files.
6. Propose smallest safe fix and required checks.

## Required Checks

- Could this affect SAFE TO EJECT?
- Could this hide failure/cancel state?
- Could this mutate source media?
- Could this be progress/observer UI only?
- What runtime scenario proves the diagnosis?

## Output Format

Diagnosis:

Likely subsystem:

Evidence needed:

Files to inspect:

Smallest safe fix:

Safety impact:

Runtime QA:

## Stop / Escalate If

- Evidence is insufficient.
- The bug may affect source safety or false SAFE TO EJECT.
- The task needs UI and core changes.

## Do Not

- Implement immediately without diagnosis.
- Add dependencies.
- Rewrite subsystems without evidence.
