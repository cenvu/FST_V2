# FST Prompt Pack

This folder contains paste-ready prompts for daily AI-assisted development.

## Agent Usage

Codex:

- `codex-core-task.md`
- `codex-fix-core-bug.md`
- `codex-implement-report.md`
- `codex-progress-eta-fix.md`

Claude:

- `claude-review-task.md`
- `claude-core-review.md`
- `claude-qa-task.md`
- `claude-runtime-qa-review.md`
- `claude-release-gate-review.md`

Antigravity/Gemini Pro:

- `antigravity-gemini-ui-task.md`
- `antigravity-design-system-task.md`
- `antigravity-ui-audit-task.md`
- `antigravity-progress-ui.md`

Claude UI review:

- `claude-ui-design-review.md`

Mi:

- `mi-final-review.md`

## UI Design Prompts

Antigravity/Gemini Pro:

- `antigravity-design-system-task.md`
- `antigravity-ui-audit-task.md`
- `antigravity-progress-ui.md`

Claude UI review:

- `claude-ui-design-review.md`

Use these for UI design, visual audit, accessibility review, and progress dashboard work.

## Prompt Compression

When a prompt becomes too long, use:

- `FST_AI/skills/fst-prompt-compression/SKILL.md`

Do not compress away safety constraints, file paths, commands, or validation.

## Rule

Use the most specific prompt possible.

Do not use broad prompts for safety-critical work.

Core coding should be handed to Codex.

Primary QA/code/safety review should be handed to Claude.

UI coding should be handed to Antigravity/Gemini Pro.

Final decision belongs to Mi.
