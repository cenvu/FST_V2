<!-- FST / CenVu | (+84) 842 841 222 -->

# Design System Page Override: Progress View

## Purpose

The progress view must help the operator understand current job progress and communicate timing to Producer/Post.

## Primary Information

PRIMARY ACTIVE-PHASE METRICS:

PROGRESS
ETA
CURRENT SPEED / CURRENT PHASE METRIC

During COPYING:
COPY PROGRESS
COPY ETA
CURRENT COPY SPEED

During VERIFYING:
VERIFY PROGRESS
VERIFY ETA
no verification-speed value unless backend truth exists

Secondary metrics may include:
- elapsed time
- copied bytes / total bytes
- copied files / total files
- average speed
- verification progress
- current item when useful

## Secondary Information

Show:

- Current file name
- Current file progress
- Current folder
- Recent activity
- Technical parser detail only if useful

## Rules

- ETA is explicitly phase-specific (Copy ETA or Verify ETA).
- Current file is secondary.
- Per-file ETA must not be presented as phase ETA.
- Stale progress must be distinguishable from slow progress.
- Verifying state must not look like stuck copy.
- Completed copy must not imply verified data.

## Anti-Patterns

Do not:

- Show only current file ETA.
- Hide total phase progress.
- Hide verify progress.
- Use vague "Almost done" wording.
- Show 100% copy as final success before verify.
- Freeze UI during verify.

## Review Checklist

- [ ] ETA is clearly labeled by phase (Copy/Verify).
- [ ] Current file is secondary.
- [ ] Copy and verify phases are distinct.
- [ ] Stale progress has a visible state.
- [ ] Cancel remains accessible during long operations.
- [ ] UI remains responsive.

