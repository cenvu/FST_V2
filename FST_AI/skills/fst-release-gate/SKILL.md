<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-release-gate
description: Block unsafe or incomplete FST builds from being considered release-ready.
---

# SKILL: fst-release-gate

## Role

Use this skill before declaring a build release-ready.

## Must Block Release If

Block if:

- Build fails.
- Runtime QA is incomplete.
- Bundled rsync validation is missing.
- Apple/System/Homebrew rsync fallback exists.
- Verify can false-pass.
- SAFE TO EJECT can false-pass.
- Report omits safety decision.
- UI can mislead operator.
- Known safety-critical bug remains unresolved.

## Required Evidence

Require:

- Xcode build result
- Runtime QA result
- rsync validation
- Success report sample
- Failure report sample
- Cancel report sample
- Source-changed result when applicable
- Known issues list

## Output Format

Release verdict:
Ready / Not ready / Ready with known limitations

Blocking issues:

Required before release:

Known limitations:

Mi final decision:
