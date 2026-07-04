<!-- FST / CenVu | (+84) 842 841 222 -->

# Workflow: Implement UI Change

## Use When

Use for SwiftUI/UI/UX changes.

## Steps

1. Mi confirms task is UI-only.
2. Mi sends task to Antigravity/Gemini Pro.
3. Antigravity uses `fst-antigravity-ui-engineer`.
4. Antigravity implements UI changes.
5. Antigravity confirms no core logic changed.
6. Claude or Mi reviews with `fst-ui-state-review`.
7. Mi final review.

## If UI Needs Core Data

If the UI requires new data from core logic:

1. Stop UI implementation.
2. Mi routes model/data task to Codex.
3. Claude reviews core change.
4. Antigravity resumes UI work.

