<!-- FST / CenVu | (+84) 842 841 222 -->

# FST Redesign vNext Documentation Baseline

## Product Character
- **Identity:** FST is a professional cinema/media offload utility.
- **Target User:** Starts with a small technical team but future users must include less-experienced operators.
- **Visual Personality:** 70% macOS native utility, 30% cinema/offload control panel.
- **Aesthetics:** Friendly/readable in the spirit of mature offload utilities. Dark-first reference design using semantic design tokens (so architecture is not permanently hard-coded to dark-only).

## Design Direction Name
**FST Hybrid Progressive Control Panel**

## Default UI Contract
- Compact, low-noise, professional.
- Technical enough for diagnosis, but understandable for a first-time operator.
- Backend truth always wins over mockup aesthetics.

## Main Information Flow
One stable vertical hierarchy that does not radically reflow on resize:

1. HEADER + EXISTING THREE TABS
2. SOURCE
3. DESTINATION
4. TRANSFER SETUP
5. CONTROL BAR
6. WHOLE-JOB STATUS
7. INLINE WARNING/ERROR WHEN PRESENT
8. SECONDARY RUNTIME INFORMATION

### Tabs
Keep: TRANSFER, NOTIFICATION, TECHNICAL LOG.
Technical Log remains a dedicated diagnostic surface (may later gain a preference allowing it to be hidden for simpler operator setups).

## Source / Destination
- **Compact View:** Exposes at minimum identity/name, path, and free-space information when backend truth supports it.
- **Advanced Information Target:** full path, filesystem, volume name, total capacity, free capacity, file count, total bytes, connection type.
- **Preferred Advanced Presentation:** Right-side inspector when practical (inline disclosure is an allowed narrow-layout fallback).
- **Backend Truth Rule:** Do not instruct mockups to fake unavailable device metadata. If a datum is not currently available from DriveService/models, documentation must explicitly mark it as requiring backend metadata support before implementation.

## Responsive Window Contract
- Define a minimum usable window size.
- Layout must remain valid at that minimum.
- Above minimum, widths and spacing adapt naturally.
- Avoid fixed content heights for primary panels.
- Avoid clipping/disappearing controls.
- Long paths must truncate safely while remaining inspectable.
- Main hierarchy does not radically reflow on resize.

## Bandwidth Product Contract
- **Options:** 50 MB/s, 75 MB/s, 100 MB/s, 125 MB/s, 150 MB/s, 175 MB/s, 200 MB/s, Unlimited.
- **Custom:** NO CUSTOM BANDWIDTH CONTROL.
- **Presentation:** Compact dropdown/menu.
- **Note:** Conversion (MB/s to KiB/s) occurs exactly once at the downstream rsync boundary. Unlimited omits `--bwlimit`.

## Verification Presentation
- **Presentation Labels:**
  - COPY ONLY — Fastest
  - SAMPLE 33% — Balanced
  - FULL 100% — Maximum confidence
- **Preserved Canonical Semantics:**
  - none -> copy-only / TRANSFER COMPLETE
  - random33 -> SHA256 sample
  - full -> xxHash64 full verification
- Verification failure blocks SAFE TO EJECT.
- Do not imply that "Maximum confidence" means mathematical certainty.

## Control Bar + Terminal Outcomes
- **Design Target:** A dedicated compact Control Bar owns the primary operational action/presentation.
- **Accommodates:** START TRANSFER, CANCEL, RETRY, plus canonical state presentation.
- **Terminal Outcomes:**
  - TRANSFER COMPLETE
  - SAFE TO EJECT
  - MANUAL CHECK REQUIRED
  - TRANSFER ERROR
- Keep UI minimal: terminal outcome should be clear through control/action state + text badge. Do not require a giant celebratory final card. CANCELLED remains a legitimate runtime terminal state.

## Active-Phase Hero Metrics
The three primary hero metrics have equal hierarchy and are phase-specific:
- PROGRESS (Copy/Verify)
- ETA (Copy/Verify)
- CURRENT SPEED / PHASE METRIC (Current Copy Speed / Verify Elapsed)

Secondary metrics may include elapsed time, copied bytes/total bytes, copied files/total files, average speed, verification progress, current item.

## ETA Trust Contract
- ETA is a responsive truthful estimate. Do NOT document ETA as exact future truth.
- Preferred display: `~18 min remaining`
- Warm-up display: `Estimating...`
- **Product targets:** normal estimation warm-up <= 120 seconds. After a material sustained throughput change, target useful ETA adaptation within <= 10 seconds.
- **Rules:** Never show per-file ETA as phase ETA. Never leave stale ETA presented as current. Never invent numeric ETA before sufficient evidence. Never allow an ETA estimate to affect copy success, verify success, report safety, or SAFE TO EJECT.
- If unable to estimate, allow a truthful degraded state (e.g. ETA unavailable) rather than indefinite Estimating.
- **Future direction:** a bounded ETA estimator/presentation component may own smoothing, recent throughput history, stale detection and adaptation.

## High-File-Count / CinemaDNG Behavior
- FST must remain readable for cinema jobs containing roughly 40k–50k files.
- DNG/CinemaDNG frame churn should be suppressed from compact Current Item presentation.
- Video/clip-style media and useful clip-level RAW may remain eligible for compact current-item display.
- Advanced/technical surfaces may expose exact current filenames.
- Exact media-extension policy is an implementation/data-set decision requiring real production samples. Do NOT invent a full extension allow/deny taxonomy in documentation without evidence.

## Error Presentation
Two-layer operator model:
- **Layer 1:** Human-readable problem/action.
- **Layer 2:** Technical detail / diagnostic code + route to Technical Log.
- Warnings and blocking errors must appear inline on Transfer. Full evidence remains in Technical Log. Do not hide blocking information behind tabs.

## OpenDesign Contract
Define three OpenDesign exploration directions sharing ONE information architecture:
- **A — Native Compact:** macOS utility character strongest.
- **B — Cinema Control Panel:** operator/offload character stronger.
- **C — Hybrid Progressive:** native compact default + progressive inspector/telemetry. (PRIMARY DESIGN HYPOTHESIS based on Owner interview).

Future OpenDesign mockups must cover at minimum:
- setup/ready
- copying
- verifying
- TRANSFER COMPLETE
- SAFE TO EJECT
- MANUAL CHECK REQUIRED / transfer error
- minimum window size
- nominal window size
- Advanced inspector closed
- Advanced inspector open
- long source/destination path
- 40k–50k-file workflow
- Estimating ETA
- numeric refreshed ETA
- inline warning/error

*(Note: No Swift implementation before Owner/BRAIN accepts a mockup direction).*

## Intel / Apple Silicon Roadmap
- FST should target both Apple Silicon and Intel Mac.
- Intel Mac support is a target requiring proof that the complete bundled runtime is safe and repeatable. It must not be claimed until proven.
- Bundled-rsync-only architecture remains mandatory. Never achieve Intel support by silent Homebrew/System/MacPorts fallback.
