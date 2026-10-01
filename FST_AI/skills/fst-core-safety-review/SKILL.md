<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-core-safety-review
description: Independently review a diff that touches FST copy, verification, TransferState, cancellation, rsync, source access, report safety, or SAFE TO EJECT.
---

# Skill: fst-core-safety-review

## Purpose

Review safety-critical FST changes for false SAFE TO EJECT, source mutation, hidden failure, or report-truth risk.

## When to Use

Use for changes touching transfer, verify, state machine, cancellation, error handling, source identity, report safety decision, rsync path/flags, or terminal UI state.

## Owner Agent

Claude reviews. Codex implements. Mi gates.

## Required Startup Context

- `AGENTS.md` L0 kernel and CURRENT's HOT header.
- Fresh Git/worktree/upstream state and the exact change diff.
- Load only the relevant sections of `docs/02_FST_TECHNICAL_GUIDE.md`, direct
  source, tests, reports, and safety evidence. Load the full Command Center
  only for an L2 trigger.

## Inputs

- Diff.
- Changed files.
- Test/build results.
- Runtime evidence if available.
- Report samples if report behavior changed.

## Safety Boundaries

- Source media must never be mutated.
- Bundled rsync 3.4.4 only.
- No Apple/System/Homebrew rsync fallback.
- SAFE TO EJECT requires copy success and verification pass.
- UI estimates never decide safety truth.

## Procedure

1. Identify affected safety truths.
2. Check failure, cancel, incomplete, uncertain, and verify-fail paths.
3. Check source write/delete/rename/chmod/chown/format risks.
4. Check report and UI terminal state consistency.
5. Require runtime QA when evidence is insufficient.

## Required Checks

- Failed copy cannot become safe.
- Cancelled job cannot become safe.
- Verify failure cannot become safe.
- Copy-only `none` verification does not become verified SAFE TO EJECT.
- Report final decision matches canonical state.
- No destructive rsync flags or fallback.

## Output Format

Verdict:

Safety impact:

Blocking issues:

Evidence checked:

Required revision:

Runtime QA:

## Stop / Escalate If

- Any safety truth is inferred from UI progress.
- Source mutation is possible.
- Final state/report mismatch exists.

## Do Not

- Approve risky changes without independent review.
- Accept missing evidence for release-sensitive work.
