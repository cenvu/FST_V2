---
name: fst-progress-eta-review
description: Review FST progress, parser, and ETA behavior with whole-job ETA as the primary operator signal.
---

# SKILL: fst-progress-eta-review

## Role

Use this skill to review FST progress and ETA behavior.

## Use When

Use when:

- Progress appears stuck.
- ETA is wrong.
- ETA appears per-file.
- Operator cannot estimate remaining job time.
- UI shows confusing copy/verify progress.
- Producer-facing timing is unreliable.

## Core Rule

Primary ETA must be Project ETA / Whole Job ETA.

Current file progress is secondary.

## Required Checks

Check:

- Total bytes expected
- Total bytes copied
- Total files expected
- Files completed
- Current file name
- Current phase
- Rsync output
- Parser output
- UI binding
- Stale progress detection
- State transition after rsync completion

## Must Not

Do not:

- Fake ETA in UI.
- Present per-file ETA as project ETA.
- Hide stalled progress.
- Treat slow transfer as failure without evidence.
- Change verify/safety logic unless explicitly needed.

## Output Format

Progress diagnosis:

ETA source:

Is ETA whole-job or per-file?

Parser risk:

UI binding risk:

Smallest safe fix:

Runtime QA:
