# Design System Page Override: Progress View

## Purpose

The progress view must help the operator understand current job progress and communicate timing to Producer/Post.

## Primary Information

Show:

1. Current phase
2. Overall job progress
3. Project ETA / Whole Job ETA
4. Transfer speed if reliable
5. Files completed / total files if reliable
6. Bytes copied / total bytes if reliable

## Secondary Information

Show:

- Current file name
- Current file progress
- Current folder
- Recent activity
- Technical parser detail only if useful

## Rules

- Project ETA is primary.
- Current file is secondary.
- Per-file ETA must not be presented as Project ETA.
- Stale progress must be distinguishable from slow progress.
- Verifying state must not look like stuck copy.
- Completed copy must not imply verified data.

## Anti-Patterns

Do not:

- Show only current file ETA.
- Hide total job progress.
- Hide verify progress.
- Use vague "Almost done" wording.
- Show 100% copy as final success before verify.
- Freeze UI during verify.

## Review Checklist

- [ ] Project ETA is clearly labeled.
- [ ] Current file is secondary.
- [ ] Copy and verify phases are distinct.
- [ ] Stale progress has a visible state.
- [ ] Cancel remains accessible during long operations.
- [ ] UI remains responsive.

