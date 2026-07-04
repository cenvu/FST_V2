<!-- FST / CenVu | (+84) 842 841 222 -->

# Prompt: Codex Fix Core Bug

ROLE:
You are Codex acting as FST Main Core Coding Agent.

TASK:
Diagnose and fix the core bug below using the smallest safe change.

CONTEXT:
FST is a macOS DIT/Data Wrangler app.
Workflow: Copy -> Verify -> SAFE TO EJECT.
Priority: Data Safety > Reliability > Speed.
MVP scope: single source, single destination, single job.
Bundled rsync 3.4.4 only.
No Apple rsync fallback.

BUG:
[paste bug intake here]

RELEVANT MEMORY:
Check FST_AI/memory/current-priority.md and FST_AI/memory/known-issues.md before changing files.

USE SKILLS:

- fst-diagnose-bug
- fst-small-safe-change
- plus the most specific Batch 2 skill:
  - fst-rsync-engine-review for rsync/copy
  - fst-verify-engine-review for verify/mismatch
  - fst-state-machine-review for state/cancel/failure
  - fst-progress-eta-review for progress/ETA
  - fst-error-handling-review for errors/retry/cancel
  - fst-detailed-txt-report or fst-report-correctness-review for reports

CONSTRAINTS:
You may edit core Swift files only if needed.

You must not:

- Redesign UI.
- Add dependencies.
- Add scripts/hooks.
- Add database/cloud/multi-job architecture.
- Use Apple rsync fallback.
- Use destructive rsync flags.
- Mutate source media.
- Change SAFE TO EJECT rules unless explicitly required.

PROCESS:

1. Restate observed behavior.
2. Classify likely subsystem.
3. Identify evidence.
4. Inspect relevant files.
5. Implement smallest safe fix.
6. Avoid unrelated refactor.
7. Prepare Claude handoff.

OUTPUT:

Diagnosis:

Files changed:

Behavior changed:

Safety impact:

SAFE TO EJECT impact:

Tests/build needed:

Claude review skill:

Known risks:

Codex implementation handoff:
Use FST_AI/templates/codex-implementation-handoff.md.

