# Behavior Review

TASK=FINAL_OWNER_TARGET_VISUAL_REPAIR
RESULT=PASS;PRESENTATION_ONLY

## Preserved contracts

- `Copy All Logs` still reaches `TechnicalLogClipboard.copyAll` with the full
  retained `TransferViewModel.logs` array. The filtered or viewport-visible
  list is not passed. Hidden diagnostic entries are included.
- Clipboard output remains `[HH:mm:ss] LEVEL message`, with message text
  unchanged, and is written through `NSPasteboard`.
- `Log details` still opens the complete retained array as selectable text.
- `Show Diagnostics` filtering and the user-controlled Auto-scroll toggle are
  unchanged. New log entries do not mutate or clear the independently owned
  toast state.
- `Check for Update` still uses `TechnicalLogsUpdateViewModel.checkForUpdates`.
  It remains disabled while copying or verifying. The secondary status view is
  absent in idle state and appears only for a real non-idle update state.
- The toast records the real clipboard result, announces its localized message
  through `NSAccessibility.announcementRequested`, and exposes an accessible
  label. Each click advances a generation; after 2.8 seconds only the current
  generation may dismiss the toast. An older timeout cannot clear a newer
  success or failure.
- Footer title and subtitle come from the existing
  `TransferControlsActionPresentation` helpers. The subtitle receives the
  same `TransferState` and `canStartTransfer` truth and uses the bounded
  existing EN/VI presentation lookup.
- Existing EN/VI catalog entries are reused; no new localization system or
  source-language behavior was added.

## Explicit non-changes

```text
TRANSFER_STATE_OR_SAFETY_LOGIC_CHANGED=NO
VERIFICATION_OR_REPORTING_CHANGED=NO
CAPACITY_LOGIC_CHANGED=NO
NOTIFICATION_DELIVERY_OR_OUTBOUND_PAYLOAD_CHANGED=NO
LOG_STORAGE_OR_FILTER_CLASSIFICATION_CHANGED=NO
RAW_LOG_CONTENT_OR_SERIALIZATION_CHANGED=NO
UPDATE_NETWORK_SEMANTICS_CHANGED=NO
SAFE_TO_EJECT_CHANGED=NO
SOURCE_MEDIA_ACCESSED=NO
```

The app's native titlebar was left alone. No fragile AppKit window-chrome
mutation was added to reposition `CenVu D.I.T Tools`.

## Copy evidence

`testCopyAllLogsWritesCompleteUnfilteredHistoryToClipboard` checks formatted
clipboard contents and a diagnostic entry hidden by the display filter.
`testCopyFeedbackTracksClipboardResultAndIgnoresStaleTimeouts` checks success,
failure, repeated-click generation advancement, stale-timeout rejection, and
current-timeout dismissal. The UI captures display the rendered success toast
from an isolated fixture; no real clipboard content was used for the images.
