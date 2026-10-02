# FST EN/VI Localization L2 Queue

TASK=FST_EN_VI_LOCALIZATION_L1_TRANSFER_AND_SETTINGS
WORKSTREAM_ID=FST_EN_VI_LOCALIZATION
STATUS=QUEUED;NOT_AUTHORIZED_IN_L1

L1 localizes the native Settings scene and Transfer experience. No L2 screen
content was changed. This queue records the remaining scope without starting
translation work.

## Notification UI

- Localize notification settings labels, Telegram connection controls, test
  message actions, status/error copy, help, and accessibility text.
- Keep notification delivery optional and best effort. Notification settings
  and delivery must not change transfer, verification, report, or eject-safety
  outcomes.
- Preserve Telegram identifiers, token values, and runtime service errors.

## Technical Log UI

- Localize the Technical Log screen title and explanatory copy, diagnostics
  controls, filters, auto-scroll state, entry counts, categories, and related
  accessibility/help text.
- Keep raw log entries, timestamps, paths, technical identifiers, and
  diagnostics unchanged.
- The Technical Log shell tab label is already localized in L1; the screen
  contents remain English pending L2.

## Metadata and update UI

- Localize app metadata labels, updater status text, update check/action labels,
  and their help/accessibility descriptions.
- Keep product names, version numbers, bundled tool versions, release URLs, and
  other identifiers unchanged.

## Remaining app-facing accessibility/help

- Audit and localize the remaining shell and non-Transfer accessibility labels,
  tooltips, and help text, including social-link descriptions.
- Preserve social brand names, URLs, paths, and other identifiers.

## Whole-app untranslated-string audit

- Audit all presentation outside L1 Transfer and Settings for missed
  String Catalog candidates.
- Classify each candidate before editing. Keep raw backend messages, log lines,
  filesystem/protocol/algorithm identifiers, values, paths, and filenames
  unchanged.
- Verify Vietnamese rendering and layout for each authorized L2 screen.
