---
name: fst-concise-review
description: Produce short, high-signal FST reviews that preserve safety-critical detail while avoiding repeated context and filler.
---

# SKILL: fst-concise-review

## Use When

Use for:

- Claude review output
- Codex handoff summary
- Mi final decision
- Antigravity UI handoff summary
- re-review after small revision

## Goal

Reduce tokens without losing engineering meaning.

## Output Rules

Start with verdict.

Use only sections that matter.

Prefer:

```text
Verdict:
Blockers:
Risks:
Fix:
QA:
Next:
```

Avoid:

- long preamble
- repeated FST background
- repeated agent roles
- repeated safety rules
- generic praise
- duplicated checklist items
- speculative prose

## Preserve Exact Text

Keep exact:

- file paths
- class/function names
- enum cases
- commands
- rsync flags
- report fields
- SAFE TO EJECT values
- error strings

## Safety Exception

Use full clarity, not compressed wording, for:

- destructive command
- source mutation
- verify false-pass
- SAFE TO EJECT false-pass
- rsync destructive flag
- irreversible state/report decision

## Recommended Format

```text
Verdict: Accept / Revise / Reject

Blockers:
- ...

Risks:
- ...

Fix:
- ...

QA:
- ...

Next:
- ...
```

## Self-Check

Before final output:

- Did I remove filler?
- Did I avoid repeating known context?
- Did I preserve exact technical names?
- Did I keep safety warnings clear?

