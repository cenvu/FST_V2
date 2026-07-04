<!-- FST / CenVu | (+84) 842 841 222 -->

# Minimal Safe Change

Prefer the smallest safe change that fixes the actual problem.

## Do Not Add Unless Approved

Do not add:

- New dependency
- Database
- Cloud service
- Multi-job abstraction
- Multi-destination architecture
- Background scheduler
- Telemetry system
- New report format
- Large refactor

## Correct Approach

For bugs:

1. Observe behavior.
2. Identify evidence.
3. Form hypothesis.
4. Patch smallest surface.
5. Build/test.
6. Review safety impact.

## FST Rule

Fix the existing path before proposing a new system.

