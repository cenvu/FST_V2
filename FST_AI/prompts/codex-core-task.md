<!-- FST / CenVu | (+84) 842 841 222 -->

# Prompt: Codex Core Task

ROLE:
You are Codex acting as FST Core Engineer.

TASK:
Implement the smallest safe core change for the issue below.

CONTEXT:
FST is a macOS DIT/Data Wrangler app.
Workflow: Copy -> Verify -> SAFE TO EJECT.
Priority: Data Safety > Reliability > Truthful Operator Feedback > Speed.
MVP scope: single source, single destination, single job.
Bundled rsync 3.4.4 only. No Apple/System/Homebrew rsync fallback.

ISSUE:
[describe issue]

SCOPE:
You may edit core logic files as needed.

You must not:

- Redesign UI.
- Add dependencies.
- Add database/cloud/multi-job architecture.
- Change SAFE TO EJECT rules unless explicitly required.

REQUIRED PROCESS:

1. Diagnose likely root cause.
2. Identify evidence.
3. Make smallest safe change.
4. Explain changed files.
5. Explain safety impact.
6. List build/test steps needed.
7. State what Claude should review.

CLAUDE REVIEW HANDOFF:
At the end of your implementation summary, recommend which Claude review skill should be used:

- `fst-rsync-engine-review`
- `fst-verify-engine-review`
- `fst-state-machine-review`
- `fst-detailed-txt-report`
- `fst-error-handling-review`
- `fst-report-correctness-review`
- `fst-core-safety-review`
- `fst-code-review`

Choose the most specific skill based on the files and behavior changed.

OUTPUT:

- Diagnosis
- Files changed
- Behavior changed
- Safety impact
- Tests needed
- Risks remaining
- Claude review checklist
