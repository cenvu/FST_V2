<!-- FST / CenVu | (+84) 842 841 222 -->

# FST v1.3.4 Failure / Cancel Truthfulness QA Evidence Template

Status: PLANNED / NOT RUN  
Release baseline: v1.3.4 build 20260706  
Workflow: SOURCE -> COPY -> VERIFY -> SAFE TO EJECT DESTINATION  
Scope: runtime failure, cancel, copy-only, mismatch, report/log truthfulness

Use this template to record runtime evidence for failure and cancellation behavior. Do not mark QA as passed unless evidence exists.

FST does not format, erase, reuse, or eject source media. Use disposable test data only. Never use irreplaceable camera original media for induced failure or mutation scenarios.

## Safety Truth Rules

- Safety truth = copy success + verification result + report/final state.
- Transfer truth = bundled rsync lifecycle, exit status, stderr, cancellation, and failure.
- Operator truth = UI progress, destination observer, speed, ETA, current item, verify ETA, logs, Telegram/update-check visibility.
- Destination observer and Verify ETA are UI-only. They must never decide copy success, verification success, report truth, or SAFE TO EJECT DESTINATION.
- Verification `none` is copy-only and must not appear verified.
- Cancel, copy failure, verify failure, mismatch, incomplete, and uncertainty must not reach SAFE TO EJECT DESTINATION.

## Verdict Rules

- PASS: no scenario incorrectly reaches SAFE TO EJECT DESTINATION; cancel/failure/mismatch are visible and truthful; reports/logs do not imply verified success when incomplete; source test data remains untouched except for explicitly planned disposable-source mutation checks.
- PASS WITH NOTES: safety truth is correct, but UX wording, evidence capture, or warning clarity could improve.
- FAIL: any false SAFE TO EJECT DESTINATION; copy failure appears successful; verify mismatch appears successful; copy-only appears verified; report contradicts UI terminal state; unexpected source mutation is observed.
- BLOCKED: scenario could not be tested safely or environment/test media did not allow completion.

## Test Environment

- Tester:
- Date/time:
- App version/build:
- Package/source:
- Mac:
- macOS:
- Source test data:
- Destination test path:
- Destination filesystem:
- Telegram configured: YES / NO
- Evidence root:
- Notes:

## Scenario A - Cancel During Copy

Purpose: Confirm cancelling active copy cannot produce success or SAFE TO EJECT DESTINATION.

Setup:
- Use a medium disposable source folder large enough to keep copy active long enough to cancel.
- Use a separate disposable destination folder.
- Optional: use a bandwidth limit to make cancellation easier to observe.

Steps:
1. Select source and destination.
2. Select Random33 or Full verification.
3. Start transfer.
4. Wait until copy is visibly active.
5. Press Cancel.
6. Capture final UI state, Technical Log, and report if generated.
7. Inspect destination partial state without treating it as complete.

Expected:
- App transitions to cancelled.
- Rsync/copy stops.
- No SAFE TO EJECT DESTINATION.
- No verified success notification.
- Report/log says cancelled if report exists.
- Partial destination data is not called safe.

- Actual result: NOT RUN
- UI final state:
- Report final state:
- Log evidence:
- Destination partial state:
- SAFE TO EJECT DESTINATION shown: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## Scenario B - Cancel During Verify

Purpose: Confirm cancelling verification cannot produce verified success.

Setup:
- Use test data large enough to enter and remain in verify phase.
- Full verification is preferred if it gives enough time to cancel.

Steps:
1. Start transfer with verification enabled.
2. Let copy complete and verification begin.
3. Press Cancel during verification.
4. Capture final UI state, Technical Log, and report if generated.

Expected:
- App transitions to cancelled or clearly incomplete.
- Verification does not pass.
- No SAFE TO EJECT DESTINATION.
- Report/log says verification cancelled or incomplete if report exists.

- Actual result: NOT RUN
- UI final state:
- Report final state:
- Verification status:
- SAFE TO EJECT DESTINATION shown: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## Scenario C - Copy Failure

Purpose: Confirm copy/preflight/rsync/destination failure cannot appear successful.

Safe simulation options:
- Remove/unmount disposable destination during copy if safe.
- Change destination permissions on a disposable folder.
- Make destination unavailable.
- Use an intentionally too-small disposable destination volume if practical.

Do not perform destructive tests on real camera media or important destination volumes.

Steps:
1. Prepare a disposable source and destination.
2. Start transfer.
3. Induce one safe copy failure condition.
4. Capture final UI state, Technical Log, and report if generated.

Expected:
- Copy fails or preflight blocks.
- Verification does not pass.
- Final state is TRANSFER ERROR or equivalent error state.
- No SAFE TO EJECT DESTINATION.
- Report/log captures failure reason if available.

- Simulation method:
- Actual result: NOT RUN
- UI final state:
- Report final state:
- Failure reason:
- Verification attempted: YES / NO
- SAFE TO EJECT DESTINATION shown: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## Scenario D - Verify Mismatch / Failure

Purpose: Confirm verification mismatch/failure blocks SAFE TO EJECT DESTINATION and is visible.

Safe simulation options:
- Complete copy, then modify a destination file before verification if timing/workflow allows.
- Use controlled source/destination test data with same path but altered destination content.
- Use a disposable test setup only.

Steps:
1. Prepare disposable test data.
2. Run or induce a verification mismatch safely.
3. Capture final UI state, Technical Log, and report.

Expected:
- Verification fails.
- Mismatch is visible in report/log.
- Final state is MANUAL CHECK REQUIRED or equivalent verification failure state.
- No SAFE TO EJECT DESTINATION.

- Simulation method:
- Actual result: NOT RUN
- UI final state:
- Report final state:
- Mismatch evidence:
- Failed files/count if shown:
- SAFE TO EJECT DESTINATION shown: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## Scenario E - Verification None Mode

Purpose: Confirm copy-only mode does not appear verified.

Setup:
- Use a small disposable source and destination.
- Set verification mode to None.

Steps:
1. Select source and destination.
2. Select verification None.
3. Start transfer.
4. Wait for copy completion.
5. Capture final UI state, Technical Log, and report.

Expected:
- Copy completes.
- Final state is TRANSFER COMPLETE / copy complete, not verified SAFE TO EJECT DESTINATION.
- Report clearly says verification was OFF / not verified by FST.
- No verified success notification.

- Actual result: NOT RUN
- UI final state:
- Report final state:
- Verification result wording:
- SAFE TO EJECT DESTINATION shown: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## Scenario F - Destination Observer False Confidence Check

Purpose: Confirm destination observer progress never becomes safety truth.

Setup:
- Use a transfer long enough to observe destination observer bytes/files.
- A slow/limited transfer is acceptable.

Steps:
1. Start transfer.
2. Observe copied bytes/files/progress/current item while copy is still active.
3. Capture UI/log evidence before rsync completion.
4. Confirm no terminal success state is shown before copy and verification complete.

Expected:
- Observer/progress may show activity.
- UI does not show SAFE TO EJECT DESTINATION during active copy or before verification pass.
- Report/final state remains controlled by transfer/verification lifecycle, not observer metrics.

- Actual result: NOT RUN
- Observer/progress evidence:
- UI state during copy:
- SAFE TO EJECT DESTINATION shown before terminal success: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## Scenario G - Telegram / Update Notification Truthfulness If Enabled

Purpose: Confirm optional notifications do not send misleading success for cancel/failure.

Setup:
- Run only if Telegram is already configured safely.
- Do not paste bot token into this template.

Steps:
1. Run one cancel or failure scenario with Telegram enabled.
2. Confirm notification behavior.
3. Inspect Technical Log for notification warning/status.

Expected:
- No success notification is sent for cancel/failure.
- Any notification reflects cancel/failure or remains a warning/status only.
- Telegram delivery does not affect transfer state, report truth, or SAFE TO EJECT DESTINATION.

- Telegram configured: YES / NO
- Scenario tested:
- Notification result:
- Misleading success sent: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN / SKIPPED
- Notes:

## Reports / Logs To Capture

For each scenario where available:
- Final UI screenshot.
- Technical Log export or screenshot.
- Generated TXT report path and text if safe to share.
- Destination folder state screenshot/listing.
- Any Telegram notification screenshot with secrets hidden.
- Notes on warnings/errors.

## Negative Findings Checklist

Mark any observed issue:

- [ ] False SAFE TO EJECT DESTINATION.
- [ ] Copy failure appears successful.
- [ ] Verify mismatch appears successful.
- [ ] Copy-only appears verified.
- [ ] Report contradicts UI terminal state.
- [ ] Report implies permission to erase, format, or reuse source media.
- [ ] Source test data unexpectedly mutated.
- [ ] Destination observer/progress appears to decide safety.
- [ ] Telegram sends misleading success after cancel/failure.
- [ ] App crashes or hangs.
- [ ] Permission/failure wording is unclear.

## User-Fillable Evidence Block

Paste this block back to Mi after runtime QA:

```text
FAILURE/CANCEL QA RESULT:
- Verdict: PASS / PASS WITH NOTES / FAIL / BLOCKED
- App version/build:
- Package/source:
- macOS:
- Test data:
- Verification modes tested:
- Scenario A cancel during copy:
- Scenario B cancel during verify:
- Scenario C copy failure:
- Scenario D verify mismatch:
- Scenario E verification none:
- Scenario F observer false confidence:
- Telegram notification if tested:
- Reports generated:
- Logs/screenshots:
- Issues:
- Recommendation:
```

