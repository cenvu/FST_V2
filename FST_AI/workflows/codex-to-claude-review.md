# Workflow: Codex to Claude Review

## Purpose

Use this workflow to preserve Codex token for coding while using Claude for primary review.

## Steps

1. Codex implements.
2. Codex outputs summary:
   - files changed
   - behavior changed
   - safety impact
   - tests/build needed
   - known risks
   - what Claude should review
3. Mi sends Codex summary and diff to Claude.
4. Claude reviews.
5. Claude returns:
   - Accept / Accept with risk / Reject
   - safety impact
   - must-fix issues
   - revision prompt
6. Mi sends revision prompt to Codex if needed.

