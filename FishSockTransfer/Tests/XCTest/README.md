<!-- FST / CenVu | (+84) 842 841 222 -->

# FST XCTest Coverage

`xcodebuild test` now runs the primary XCTest regression suite for pure model, parser, report, metadata-only safety, and bundled-rsync validation behavior.

Some standalone tests remain part of the full safety suite until they can be migrated without broadening the initial XCTest target:

- `TransferControlsLabelTests`
- actual bundled rsync binary fixture/path validation in `BundledRsyncServiceTests`

This split is intentional for now. It avoids pulling SwiftUI/app entry-point dependencies or resource-path complexity into the first XCTest target while keeping those checks available in the standalone safety suite.
