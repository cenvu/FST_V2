# FST Documentation Merge Plan

Version: 2026-06-21
Status: Recommended

## Decision

Merge these six files into one active technical guide:

- CODING_STANDARDS.md
- FILE_STRUCTURE.md
- RSYNC_ENGINE_SPEC.md
- STATE_MACHINE.md
- UI_GUIDELINES.md
- VERIFY_ENGINE_SPEC.md

New active file:

- FST_TECHNICAL_GUIDE.md

Reason:

- The project is small enough for one technical source-of-truth.
- Codex performs better with one compact, current guide.
- The previous files repeat architecture, state, engine boundaries, and safety rules.
- Several old assumptions conflict with the current project screenshot and current rsync direction.

## Keep Separate

Keep these as separate top-level docs:

1. PRD.md
   - Product scope and operator requirements.

2. AI_Engineering_System_Prompt.md
   - Short behavior prompt for Codex/AI agents.

3. FST_TECHNICAL_GUIDE.md
   - Current code architecture, file ownership, engine specs, state machine, UI, tests.

Optional archive:

4. FST_V1_WORKLOG_ARCHIVED.md
   - Historical reference only. Not source-of-truth.

## Archive

Move old detailed docs into:

```text
Documentation/Archive/
  CODING_STANDARDS.md
  FILE_STRUCTURE.md
  RSYNC_ENGINE_SPEC.md
  STATE_MACHINE.md
  UI_GUIDELINES.md
  VERIFY_ENGINE_SPEC.md
```

Add this header to archived files:

```text
ARCHIVED. Replaced by FST_TECHNICAL_GUIDE.md. Do not use as source-of-truth.
```

## Minimal Active Documentation Set

Recommended active docs:

```text
Documentation/
  PRD.md
  AI_Engineering_System_Prompt.md
  FST_TECHNICAL_GUIDE.md
  Archive/
    FST_V1_WORKLOG_ARCHIVED.md
    old split docs...
```

## Codex Instruction

Use this priority order:

1. PRD.md
2. FST_TECHNICAL_GUIDE.md
3. AI_Engineering_System_Prompt.md
4. Existing code

If documentation conflicts with current code structure:

- Preserve current code structure.
- Fix documentation if docs are stale.
- Ask before large refactors.

