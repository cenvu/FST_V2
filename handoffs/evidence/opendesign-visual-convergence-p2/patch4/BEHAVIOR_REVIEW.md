# Patch 4 behavior and scope review

BEHAVIOR_REVIEW=PASS

- `Show Diagnostics` still binds to `showDiagnostics`; it selects either all `viewModel.logs` or `LogVisibilityFilter.operatorVisible(from:)`. The filter implementation and underlying model array are unchanged.
- The Technical Log tab badge still reads `viewModel.logs.count`.
- `autoScroll` still derives only from `transferState == .copying || transferState == .verifying`. The new “Auto-scroll active” text is conditional on that same value and is not interactive.
- `TerminalLogTextView` remains an AppKit `NSTextView` hosted in `NSScrollView`: editable is false, selectable is true, `usesFindPanel` is true, horizontal scrolling is false, vertical scrolling is enabled, and word wrapping remains enabled.
- Displayed text retains the exact production serialization `[HH:mm:ss] LEVEL message\n`; the implementation only assigns separate attributes to its timestamp, level, and message portions. Timestamps use each real `LogEntry.timestamp`; level and message still use each real `LogEntry.level` and `.message`.
- All `LogCategory` cases remain present with their existing category mapping. ERROR/stderr remain red and unmistakable; warning, success, stdout/file, progress, verify, system, and info/transfer remain visually distinct.
- `TechnicalLogsMetadataFooter` is unchanged. Version, bundled-rsync availability/version, license, update action/status, and transfer/verification-running disable input remain production-derived as before.
- No ViewModel, service, coordinator, log filter, transfer state, update behavior, notification behavior, report, verification, or SAFE TO EJECT code changed.
- The screenshot harness uses synthetic logs, a fake token store, and a send service that traps if called. Capture did not start a transfer, send a notification, access owner Keychain/media/logs, or invoke the update request.

Exact production path list and retained Patch 1/2/3 state are recorded in
`SCOPE_GATE.md`; the complete reviewed production diff is preserved byte for
byte in `PATCH4_PRODUCTION_REVIEWED.diff.gz`.
