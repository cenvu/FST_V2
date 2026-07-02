# Workflow: Fix Core Bug

## Use When

Use for:

- rsync bugs
- transfer bugs
- verify bugs
- state machine bugs
- progress/ETA bugs
- report bugs
- safety bugs

## Steps

1. Mi classifies the bug.
2. Mi prepares Codex core task.
3. Codex diagnoses using `fst-diagnose-bug`.
4. Codex applies `fst-small-safe-change`.
5. Codex implements smallest safe fix.
6. Codex reports changed files, behavior, safety impact, and tests.
7. Mi sends result to Claude.
8. Claude reviews using `fst-code-review` and `fst-core-safety-review`.
9. If rejected, Codex revises.
10. Claude rechecks.
11. Mi performs final safety gate.

## Rule

The coding agent is not the final reviewer of its own safety-critical change.

