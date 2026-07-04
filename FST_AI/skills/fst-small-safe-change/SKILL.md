<!-- FST / CenVu | (+84) 842 841 222 -->

---
name: fst-small-safe-change
description: Keep FST changes minimal, safe, scoped, and reviewable.
---

# SKILL: fst-small-safe-change

Inspired by minimal-change and anti-overengineering agent practices.

## Role

Use this skill to keep FST changes small, safe, and reviewable.

## Use When

Use this skill for:

- Bug fixes
- Safety-critical changes
- Progress/ETA changes
- Verify logic changes
- Report logic changes
- UI changes that could affect operator confidence

## Rule

Prefer the smallest safe change that solves the real problem.

## Do Not Add

Do not add unless explicitly approved:

- Dependency
- Database
- Cloud service
- Multi-job architecture
- Multi-destination support
- Background scheduler
- Telemetry
- Analytics
- New report format
- Large refactor

## Required Questions

Before changing code, answer:

1. What is the smallest surface area to change?
2. Can this be fixed without new architecture?
3. Can this be fixed without new dependency?
4. What safety behavior could regress?
5. How can Claude review this efficiently?
6. What runtime scenario proves the fix?

## Output Format

Smallest safe change:

Files changed:

Files intentionally not changed:

Why no larger refactor is needed:

Safety risk:

Review notes for Claude:
