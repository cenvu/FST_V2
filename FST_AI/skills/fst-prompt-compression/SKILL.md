---
name: fst-prompt-compression
description: Compress FST prompts by removing repetition while preserving role, task, constraints, safety rules, validation, and output format.
---

# SKILL: fst-prompt-compression

## Use When

Use when:

- a prompt is too long
- Codex/Claude token budget is tight
- repeated project context appears across prompts
- creating revision prompts
- creating re-review prompts

## Goal

Make prompts shorter without weakening constraints.

## Keep

Always keep:

- role
- task
- exact bug/change
- exact files or file scope
- safety constraints
- allowed/disallowed edits
- relevant skills
- validation commands
- output format

## Remove or Shorten

Remove:

- repeated project overview
- repeated role descriptions
- repeated full priority list unless relevant
- duplicated safety language
- repeated batch history
- motivational wording
- broad explanations already in `FST_AI/`

## Do Not Compress

Do not compress:

- destructive warnings
- source safety rules
- SAFE TO EJECT constraints
- rsync flag restrictions
- verify false-pass constraints
- file paths
- commands
- code snippets

## Compact Prompt Shape

```text
ROLE:
...

TASK:
...

READ:
...

SCOPE:
Allowed:
...
Forbidden:
...

CONSTRAINTS:
...

OUTPUT:
...

VALIDATION:
...
```

## Self-Check

- Shorter?
- Still safe?
- Still specific?
- No lost file paths?
- No lost forbidden actions?
- No ambiguous task?

