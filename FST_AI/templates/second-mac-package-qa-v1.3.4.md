<!-- FST / CenVu | (+84) 842 841 222 -->

# FST v1.3.4 Second-Mac Package QA Evidence Template

Status: PLANNED / NOT RUN  
Package: `FishSockTransfer-v1.3.4-b20260706-local-macOS13_5plus-arm64.zip`  
Checksum file: `SHA256SUMS-v1.3.4.txt`  
Expected SHA256: `a8487b89d4f3545f6cdd6f3e2aabe132c81657b108768924fde0923c9dda7826`  
Platform: macOS 13.5+, Apple Silicon arm64 only  
Signing: local ad-hoc, not Developer ID signed, not notarized

Use this template to verify the downloadable GitHub Release package on a second Apple Silicon Mac. Do not mark QA as passed unless evidence exists.

FST does not format, erase, reuse, or eject source media. It reports copy and verification evidence for operator judgment.

## Verdict Rules

- PASS: checksum, version/build, zip extraction, app launch, bundled rsync 3.4.4, small transfer, verification, report, and final state all match expectations.
- PASS WITH NOTES: app works, with expected ad-hoc/Gatekeeper warnings or minor UX notes that do not affect copy/verify/report safety.
- FAIL: wrong package/version/checksum/rsync, crash, false SAFE TO EJECT DESTINATION, report truth issue, unsafe wording, or missing required package contents.
- BLOCKED: QA cannot complete because of environment, permissions, missing second Mac, missing GitHub asset, or unavailable test storage.

## A. Machine Info

- Tester:
- Date/time:
- Mac model:
- Apple Silicon chip:
- macOS version:
- User account type:
- Internet available: YES / NO
- Notes:

## B. Download Evidence

- GitHub Release URL:
- Downloaded zip filename:
- Downloaded checksum filename:
- Download time:
- Download source: GitHub Release / other
- Confirm not local `dist/`: YES / NO
- Evidence path/screenshot:
- Pass/Fail: NOT RUN
- Notes:

## C. Checksum Verification

Run from the folder containing the downloaded files:

```bash
shasum -a 256 FishSockTransfer-v1.3.4-b20260706-local-macOS13_5plus-arm64.zip
cat SHA256SUMS-v1.3.4.txt
```

Expected:

```text
a8487b89d4f3545f6cdd6f3e2aabe132c81657b108768924fde0923c9dda7826
```

- Actual zip SHA256:
- SHA256SUMS value:
- Match: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## D. Zip Extraction

Steps:
1. Create a clean temporary folder.
2. Unzip the downloaded zip.
3. Confirm `FishSockTransfer.app` appears.
4. Check for obvious AppleDouble junk if visible.

Optional command:

```bash
unzip -l FishSockTransfer-v1.3.4-b20260706-local-macOS13_5plus-arm64.zip | grep -E '(^|/)\._' || true
```

Expected:
- Zip extracts cleanly.
- App bundle name is `FishSockTransfer.app`.
- No visible AppleDouble `._` junk issue.

- Actual result:
- App bundle path:
- AppleDouble entries found: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## E. App Metadata Verification

Run:

```bash
defaults read /path/to/FishSockTransfer.app/Contents/Info CFBundleShortVersionString
defaults read /path/to/FishSockTransfer.app/Contents/Info CFBundleVersion
defaults read /path/to/FishSockTransfer.app/Contents/Info LSMinimumSystemVersion
```

Expected:

```text
1.3.4
20260706
13.5
```

- Actual CFBundleShortVersionString:
- Actual CFBundleVersion:
- Actual LSMinimumSystemVersion:
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## F. Bundled Rsync Verification

Run:

```bash
find /path/to/FishSockTransfer.app/Contents/Resources -maxdepth 1 -name rsync -print
ls -l /path/to/FishSockTransfer.app/Contents/Resources/rsync
/path/to/FishSockTransfer.app/Contents/Resources/rsync --version | head -n 1
```

Expected:
- Bundled rsync exists inside the app bundle.
- Bundled rsync is executable.
- First version line includes `rsync version 3.4.4 protocol version 32` or equivalent canonical bundled output.
- No system `/usr/bin/rsync`, Homebrew, MacPorts, or PATH fallback claim appears.

- Bundled rsync path:
- Executable: YES / NO
- Version output:
- Any fallback claim: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## G. Codesign / Gatekeeper Behavior

Run:

```bash
codesign --verify --deep --strict --verbose=2 /path/to/FishSockTransfer.app
spctl -a -vv /path/to/FishSockTransfer.app
```

Expected:
- `codesign` may verify structurally as an ad-hoc local package.
- `spctl` / Gatekeeper may reject or warn because the app is not Developer ID signed and not notarized.
- This is expected for the current package.
- Do not call Gatekeeper rejection a product failure unless the app cannot launch after documented user approval/open flow.

- codesign result:
- spctl result:
- Gatekeeper warning shown: YES / NO
- Expected ad-hoc/notarization behavior: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## H. First Launch

Steps:
1. Launch the app.
2. Record launch method: double-click, right-click Open, Terminal `open`, or other.
3. Record any macOS warning.
4. Confirm the app opens and main UI is readable.
5. Confirm footer/header metadata where visible.

Expected:
- App opens without crash.
- UI is readable.
- Version/footer shows v1.3.4 where visible.
- Bundled rsync indicator shows 3.4.4 or truthful availability wording.
- No transfer starts automatically.

- Launch method:
- macOS warning:
- Right-click Open needed: YES / NO
- App opened: YES / NO
- UI readable: YES / NO
- Footer/version observed:
- Bundled rsync observed:
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## I. Permission Behavior

Steps:
1. Select a test source folder.
2. Select a separate test destination folder.
3. Observe security-scoped access / permission behavior.
4. Record any permission warnings.

Expected:
- Source and destination selection work.
- Permission prompts are understandable.
- Start remains blocked if source/destination are invalid.

- Source selection result:
- Destination selection result:
- Permission prompt/warning:
- UX understandable: YES / NO
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## J. Small Safe Transfer Test

Use test data only. Never use irreplaceable camera originals as the QA source.

Suggested setup:

```bash
mkdir -p ~/Desktop/FST_QA_Source ~/Desktop/FST_QA_Destination
printf 'clip-a\n' > ~/Desktop/FST_QA_Source/clip-a.txt
printf 'clip-b\n' > ~/Desktop/FST_QA_Source/clip-b.txt
mkdir -p ~/Desktop/FST_QA_Source/subfolder
printf 'clip-c\n' > ~/Desktop/FST_QA_Source/subfolder/clip-c.txt
```

Steps:
1. Select `FST_QA_Source` as source.
2. Select `FST_QA_Destination` as destination.
3. Run copy with Random33 or Full verification.
4. Observe copy progress.
5. Observe verify progress.
6. Observe final state.
7. Confirm source files remain unchanged.
8. Confirm destination contains copied files.
9. Save screenshot, technical log, and generated report path.

Expected:
- Copy completes.
- Verification passes for selected mode.
- `SAFE TO EJECT DESTINATION` appears only after copy and verification success.
- Report is generated.
- Logs/report remain truthful.
- No unsafe `SAFE TO FORMAT` wording appears.

- Verification mode used:
- Copy progress observed: YES / NO
- Verify progress observed: YES / NO
- Source unchanged: YES / NO
- Destination copied files present: YES / NO
- Final state:
- Report generated: YES / NO
- Report path:
- Evidence path/screenshot/log:
- Pass/Fail: NOT RUN
- Notes:

## K. Negative Observations

Record any of these if observed:

- Crash:
- Warning:
- Permission failure:
- Gatekeeper issue:
- Missing bundled rsync:
- Wrong rsync version:
- Wrong app version/build:
- Report wording issue:
- Unsafe `SAFE TO FORMAT` wording:
- Misleading UI state:
- False `SAFE TO EJECT DESTINATION`:
- Copy/verify/report contradiction:
- Other:

## L. Evidence Artifacts

Attach or list:

- Terminal checksum output:
- Terminal app metadata output:
- Terminal rsync output:
- codesign/spctl output:
- First-launch screenshot:
- Permission prompt screenshot:
- Transfer progress screenshot:
- Final state screenshot:
- Generated report text/path:
- Technical log text/path:
- Notes on warnings:

## Final User-Fillable Evidence Block

Paste this block back to Mi after second-Mac QA:

```text
SECOND-MAC QA RESULT:
- Verdict:
- Mac:
- macOS:
- Download source:
- Zip checksum:
- App version/build:
- Bundled rsync:
- Gatekeeper behavior:
- Launch:
- Small transfer:
- Verification:
- Final state:
- Report:
- Issues:
- Evidence files/screenshots:
- Recommendation:
```

