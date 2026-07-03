# Template: Concise Agent Output

Use when output can be short.

## Format

```text
Verdict:
...

Changed:
- ...

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

## Optional Fields

Use only if needed:

```text
Safety:
...

Files:
...

Tests:
...

Prompt:
...
```

## Do Not Omit

Never omit:

- blocker
- safety risk
- failed validation
- unknown that affects decision
- required next action

