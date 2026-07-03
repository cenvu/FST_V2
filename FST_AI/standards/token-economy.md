# Token Economy Standard

## Purpose

FST agent output should be short, precise, and reviewable.

Save tokens by removing filler and repeated context.

Do not save tokens by removing safety-critical meaning.

## Default Output Mode

Use concise technical output by default.

Prefer:

- verdict first
- changed files
- blockers
- risks
- next action
- exact commands
- exact file paths
- exact symbols

Avoid:

- repeated project background
- repeated agent role lists
- repeated safety rules unless relevant
- motivational wording
- long preambles
- generic explanations
- duplicate checklists
- vague commentary

## Keep Exact

Never compress or paraphrase:

- code
- commands
- file paths
- enum names
- function names
- class names
- error strings
- rsync flags
- test names
- report field names
- SAFE TO EJECT values

## Safety Clarity Exception

Do not use compressed output when clarity is more important than token saving.

Use full clear wording for:

- destructive command warnings
- source media safety
- rsync flag risk
- SAFE TO EJECT risk
- verify false-pass risk
- irreversible action
- multi-step instructions where order matters
- user asks for explanation or learning
- ambiguous result that needs context

## Review Output Rule

For reviews, default order:

1. Verdict
2. Blocking issues
3. Safety impact
4. Files affected
5. Required fix
6. QA required
7. Paste-ready next prompt if needed

## Prompt Output Rule

For prompts, keep required context, but avoid duplicate context already present in `FST_AI/`.

Prompt should include:

- role
- task
- constraints
- files/skills to read
- output format
- validation

Prompt should not repeat every project rule unless the task is safety-critical.

## Good Output Shape

```text
Verdict: Reject

Blockers:
1. Verify failure can still reach SAFE TO EJECT YES.
2. Report omits cancellation state.

Fix:
- Gate safety decision on canonical verify pass.
- Add cancelled state to report mapper.

QA:
- Cancel during copy
- Cancel during verify
- Verify failure
```

## Bad Output Shape

```text
Thank you for the detailed implementation. I carefully reviewed the code in the context of the overall FST architecture, and because FST is a safety-critical DIT application...
```

## Rule

Short is good.

Ambiguous is bad.

Safety clarity wins over token saving.

