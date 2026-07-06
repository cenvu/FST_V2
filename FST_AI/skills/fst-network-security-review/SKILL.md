<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-network-security-review
description: Defensively review FST Telegram, GitHub update-check, network entitlement, token, logging, and outbound HTTPS behavior.
---

# Skill: fst-network-security-review

## Purpose

Defensively review FST network-facing behavior without adding offensive workflows.

## When to Use

Use when changes touch Telegram bot token handling, Telegram HTTPS requests, GitHub update-check, sandbox network entitlements, logging redaction, reports/logs containing sensitive data, or network/config input handling.

## Owner Agent

Claude reviews. Codex implements. Mi gates.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `docs/02_FST_TECHNICAL_GUIDE.md`
- `docs/guides/telegram-bot-setup.md` when Telegram is involved

## Inputs

- Diff.
- Entitlement files.
- Network call sites.
- Token storage/logging behavior.
- Update-check behavior.
- Runtime logs if available.

## Safety Boundaries

- Defensive review only.
- Outbound-only behavior unless explicitly approved.
- No auto-download, auto-install, Sparkle, app bundle mutation, or background updater.
- No token leakage in logs/reports.
- No command injection through network/config input.

## Procedure

1. Identify network entry points and data inputs.
2. Check token storage and redaction.
3. Check outbound HTTPS request behavior.
4. Check update-check cannot mutate app bundle or install anything.
5. Check entitlements match actual behavior.
6. Check reports/logs do not leak sensitive values.

## Required Checks

- Telegram token is not logged.
- Chat IDs/config values are handled as data, not shell.
- GitHub update-check is manual and visibility-only.
- Network success/failure cannot affect copy, verify, report truth, or SAFE TO EJECT.
- Entitlement claims are accurate.
- Errors are visible but not secret-bearing.

## Output Format

Verdict:

Network surface reviewed:

Secret/logging risks:

Update-check risks:

Entitlement risks:

Required fix:

## Stop / Escalate If

- A network path can mutate the app or source/destination data.
- Sensitive tokens can leak.
- Network status affects safety truth.

## Do Not

- Include offensive exploitation steps.
- Add scanning/attack automation.
- Broaden network behavior beyond FST's manual update-check and Telegram visibility workflows.
