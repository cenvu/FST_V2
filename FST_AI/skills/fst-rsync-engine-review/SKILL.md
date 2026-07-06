<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-rsync-engine-review
description: Review FST rsync engine behavior, bundled rsync usage, source safety, destructive flag risks, and progress output handling.
---

# Skill: fst-rsync-engine-review

## Purpose

Review rsync execution and copy truth for bundled-rsync-only safety.

## When to Use

Use when rsync path/version validation, arguments, process launch, stdout/stderr, cancellation, progress parsing, copy completion, or rsync-related error/report fields change.

## Owner Agent

Claude reviews. Codex implements. Mi gates.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `docs/02_FST_TECHNICAL_GUIDE.md`

## Inputs

- Diff.
- Rsync command construction.
- Process lifecycle/error mapping.
- Logs.
- Tests/build results.

## Safety Boundaries

- Bundled rsync 3.4.4 only.
- No Apple `/usr/bin/rsync`, Homebrew, MacPorts, or non-bundled fallback.
- Source volume must never be mutated, deleted, formatted, renamed, chmodded, chowned, or cleaned up.
- No destructive flags.

## Procedure

1. Confirm bundled path resolution and version validation.
2. Inspect rsync flags.
3. Inspect stdout/stderr draining and exit-code handling.
4. Inspect cancellation/error mapping.
5. Confirm observer/progress metrics remain UI-only.

## Required Checks

- `-a`, `-h`, `--info=progress2` retained.
- No `--delete`, `--remove-source-files`, `--inplace`, or source mutation flags.
- Wrong/missing/non-executable bundled rsync fails fast.
- Exit status, stderr, and cancellation decide copy truth.
- Logs separate app version and rsync version.

## Output Format

Verdict:

Rsync path/version risk:

Flag risk:

Copy truth risk:

Cancellation/error risk:

Required fix:

## Stop / Escalate If

- Any fallback can execute.
- Any destructive/source-mutating flag appears.
- Copy success can be inferred from progress/UI.

## Do Not

- Accept convenience fallback.
- Treat observer destination changes as copy completion.
