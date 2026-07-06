# FST AI Agent Skill Reference Notes

## Purpose

Concise notes from external AI-agent, skill, UI, memory, prompt, and defensive-security references used for Batch AI-2. These are inspiration notes only. Do not vendor, copy large passages, or import external tooling into FST without explicit approval.

## nextlevelbuilder/ui-ux-pro-max-skill

- Useful for FST: skill structure, design-system reasoning, anti-pattern lists, pre-delivery UI checklist style, accessibility and platform-aware UI thinking.
- Must not import: decorative consumer/web landing-page patterns, broad visual trend catalogs, external CLI/tools, large copied text.
- FST beneficiaries: `fst-ui-design-system`, `fst-ui-visual-audit`, `fst-progress-dashboard-design`, `fst-antigravity-ui-engineer`.
- Caution: adapt ideas to FST's dark-mode-first macOS utility workflow where safety state must be impossible to misread.

## ruvnet/ruflo

- Useful for FST: harness framing, startup checklist, memory loop, run guard, task repetition detection.
- Must not import: swarm complexity, autonomous multi-agent execution, networked/federated agent behavior, npm/tooling.
- FST beneficiaries: `FST_AI/memory/TASK_REGISTRY.md`, startup docs, Codex repeat-task guard.
- Caution: FST needs a lightweight repo-backed protocol, not an agent platform.

## msitarzewski/agency-agents

- Useful for FST: role-card structure, explicit specialty/when-to-use format, cross-tool role taxonomy.
- Must not import: large generic agent catalog, extra FST roles, `FST_AI/agents/` duplication.
- FST beneficiaries: `FST_AI/roles/`, `FST_AI/memory/agent-roles.md`.
- Caution: keep roles FST-specific and safety-bounded.

## DeusData/codebase-memory-mcp

- Useful for FST: persistent codebase memory concept, local-first memory, task/command history ideas.
- Must not import: MCP dependency, binaries, installer scripts, generated indexes.
- FST beneficiaries: `TASK_REGISTRY.md`, `WORK_HISTORY.md`.
- Caution: no third-party dependency or repo indexing in this batch.

## asgeirtj/system_prompts_leaks

- Useful for FST: prompt boundary clarity, role/tool separation, output contracts, explicit stop conditions.
- Must not import: leaked or proprietary prompt text.
- FST beneficiaries: prompts, role docs, skill stop/escalation sections.
- Caution: use pattern-level lessons only.

## mukul975/Anthropic-Cybersecurity-Skills

- Useful for FST: defensive skill structure, security checklist style, network/token/logging review framing.
- Must not import: offensive procedures, exploit automation, credential theft, persistence/evasion workflows.
- FST beneficiaries: `fst-network-security-review`.
- Caution: FST security review must stay defensive and scoped to Telegram, update-check, entitlements, logging, and outbound HTTPS behavior.

## Final Recommendation

Keep FST's own `FST_AI/roles/` and `FST_AI/skills/` structure. Add only two missing skills: docs cleanup and network security review. Use external references for structure and checklist discipline only.
