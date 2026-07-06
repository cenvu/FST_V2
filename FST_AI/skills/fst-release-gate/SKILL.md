<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-release-gate
description: Block unsafe or incomplete FST builds from being considered release-ready.
---

# Skill: fst-release-gate

## Purpose

Review whether an FST build can be called release-ready.

## When to Use

Use before tagging, packaging, publishing, or saying a build is releasable.

## Owner Agent

Claude reviews. Codex collects evidence. Mi makes the final release decision.

## Required Startup Docs

- `AGENTS.md`
- `FST_AI/memory/COMMAND_CENTER_HANDOVER.md`
- `FST_AI/memory/WORK_HISTORY.md`
- `FST_AI/memory/TASK_REGISTRY.md`
- `docs/00_AI_AGENT_START_HERE.md`

## Inputs

- Diff/commit.
- Build/test results.
- Package validation.
- Runtime QA evidence.
- Report samples.
- Release asset/checksum evidence.

## Safety Boundaries

- Git tag alone is not a downloadable release.
- Local package alone is not release completion.
- Release is complete only after GitHub Release has zip + checksum assets uploaded and verified.
- Do not claim Developer ID signing or notarization without evidence.

## Procedure

1. Confirm version/build/package metadata.
2. Confirm bundled rsync 3.4.4 validation.
3. Confirm build/test/package validation.
4. Review runtime QA for success, fail, cancel, verify fail, and report cases.
5. Confirm GitHub Release zip + checksum assets exist and match.

## Required Checks

- Build passes.
- Required tests or Mi-approved waiver.
- Package validates app version, arm64, macOS minimum, rsync executable/version, dylibs, codesign, zip contents.
- SAFE TO EJECT cannot false-pass.
- Reports include final safety decision.
- UI cannot mislead operator.
- Known safety-critical bugs are resolved or explicitly blocked.

## Output Format

Release verdict:
Ready / Not ready / Ready with known limitations

Blocking issues:

Evidence reviewed:

Required before release:

Mi final decision:

## Stop / Escalate If

- Any failure/cancel/verify-fail path can show SAFE TO EJECT.
- GitHub Release assets are missing.
- Package validation is incomplete.
- Signing/notarization claims are unsupported.

## Do Not

- Treat tag-only or package-only state as release complete.
- Skip runtime QA for release-sensitive changes.
- Hide known safety limitations.
