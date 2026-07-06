<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-verify-engine-review
description: Review FST verify engine behavior, mismatch handling, source identity checks, and false-pass risks.
---

# Skill: fst-verify-engine-review

## Purpose

Review verification behavior so FST never false-passes verification or SAFE TO EJECT.

## When to Use

Use when VerifyEngine, verification modes, inventory, file count, file size, hashing, source-changed detection, skipped item handling, verify report fields, or SAFE TO EJECT inputs change.

## Owner Agent

Claude reviews. Codex implements. Mi gates.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `docs/02_FST_TECHNICAL_GUIDE.md`

## Inputs

- Diff.
- Verification mode.
- Source/destination inventory behavior.
- Hash behavior.
- Verification result samples.

## Safety Boundaries

- Verify must never false-pass.
- `none` is copy-only, not verified SAFE TO EJECT.
- `random33` uses SHA256 sample verification.
- `full` uses xxHash64 full verification.
- Verify ETA is UI-only and never decides verify truth.

## Procedure

1. Check inventory and relative path comparison.
2. Check file size comparison before hashing.
3. Check sample/full file selection.
4. Check hash mismatch and missing file handling.
5. Check cancellation/source-changed behavior.
6. Check report/state mapping.

## Required Checks

- Minimum one sampled file when files exist for random33.
- All eligible files checked for full verification.
- Missing/extra/size mismatch blocks verified success.
- Hash mismatch blocks verified success.
- Cancelled/uncertain verification blocks SAFE TO EJECT.

## Output Format

Verdict:

False-pass risk:

Mismatch handling:

Mode behavior:

Report/state mapping:

Required fix:

## Stop / Escalate If

- Verification result can be inferred from progress.
- Mismatch is downgraded without approved policy.
- `none` verification is presented as verified safe.

## Do Not

- Add new verification algorithms or manifests without spec approval.
- Let performance concerns weaken verification truth.
