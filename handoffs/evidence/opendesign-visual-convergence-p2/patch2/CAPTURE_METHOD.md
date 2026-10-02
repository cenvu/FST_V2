# Patch 2 native capture method

VISUAL_AUTHORITY=Live OpenDesign MCP read-only project source
RUNTIME_AUTHORITY=Canonical FST SwiftUI sources from the repository
APPEARANCE=Dark Aqua (`NSAppearanceNameDarkAqua`)
NOMINAL_GEOMETRY=1120 x 760 content points
CAPTURED_BITMAP=2240 x 1520 pixels (2x backing scale)
WINDOW=Native `NSWindow` hosting production `ContentView` through `NSHostingView`

`capture_native.py` compiles the production SwiftUI views and assets, replacing
only `ContentView`'s construction site in a temporary source copy so the
approved state fixture can inject a `TransferViewModel`. The BEFORE set reads
all production Swift sources from the exact start commit
`be06423712b18495bd552034d7e541f511b89b66`; the Pass A and Pass B sets compile
the current worktree sources. `CaptureNative.swift` creates an isolated
temporary source and destination directory, configures the stated window size
and appearance, renders through AppKit, and saves PNGs. No owner media is used.

The five fixtures are READY, COPYING, VERIFYING, SAFE_TO_EJECT, and ERROR.
Copying and verifying values reuse the previously approved Patch 1 native
capture fixture values. ERROR uses the existing report-test wording
`TRANSFER ERROR: rsync failed.` and supplies no runtime snapshot, progress,
ETA, speed, or file counts. The only rsync interaction is the bundled 3.4.4
availability/version probe needed for READY's real startable state. No copy,
verification, report, or notification is performed. Fixture setup derives the
capacity presentation from the production assessment model; it does not
change business rules.

Capture records:

- `CAPTURE_BEFORE.log` — baseline capture from the exact start commit.
- `CAPTURE_PASS_A.log` — successful five-state Pass A capture.
- `CAPTURE_PASS_A_INITIAL_ATTEMPT.log` — preserved initial attempt, including
  the failure after the five requested images when an inherited optional
  minimum-size capture was invoked without its optional argument.
- `CAPTURE_PASS_B.log` — final five-state capture at the same geometry.
- `BEFORE_*.png`, `PASS_A_*.png`, and `AFTER_*.png` — baseline, comparison,
  and final native captures, respectively.

The images are comparison evidence, not visual-parity acceptance. The Worker
does not self-accept the result.
