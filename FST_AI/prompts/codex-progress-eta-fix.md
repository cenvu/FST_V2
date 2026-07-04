<!-- FST / CenVu | (+84) 842 841 222 -->

# Prompt: Codex Progress / ETA Fix

ROLE:
You are Codex acting as FST Main Core Coding Agent.

TASK:
Diagnose and fix FST progress / ETA behavior.

CONTEXT:
FST workflow: Copy -> Verify -> SAFE TO EJECT.
Operator needs Project ETA / Whole Job ETA.
Current file progress is secondary.

KNOWN ISSUE:
App may appear stuck on a source around 40GB, around 7000 files, around 325 folders.
Destination may appear mostly cloned while UI remains stuck.
ETA may appear to represent current file rather than whole job.

USE SKILLS:

- fst-diagnose-bug
- fst-progress-eta-review
- fst-rsync-engine-review
- fst-state-machine-review
- fst-small-safe-change

CONSTRAINTS:
You must not:

- Fake ETA in UI.
- Present per-file ETA as project ETA.
- Redesign UI.
- Change verify/safety/report logic unless explicitly required.
- Add telemetry/database/background scheduler.
- Add new dependency.

CHECK:

- Is rsync still running?
- Is rsync output still received?
- Is parser receiving output?
- Is total expected bytes known?
- Is copied bytes aggregated?
- Is current file progress separate from whole-job progress?
- Is state transition blocked?
- Is UI/main thread blocked?
- Is stale progress detected?
- Are many-small-file cases handled?

PROCESS:

1. Diagnose whether bug is parser, model, state, or UI binding.
2. Fix core progress/ETA model first.
3. Keep UI work minimal unless required to expose correct data.
4. Prepare Claude review handoff.
5. If UI display needs redesign, ask Mi to route to Antigravity/Gemini.

OUTPUT:

Diagnosis:

Files changed:

ETA source:

Whole-job ETA behavior:

Current file behavior:

Safety impact:

Claude review skill:
fst-progress-eta-review plus any relevant Batch 2 skill

Runtime QA needed:

