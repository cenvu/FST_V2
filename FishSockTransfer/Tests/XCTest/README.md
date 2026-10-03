# FST XCTest Coverage

Run the XCTest suite with `xcodebuild test` or Product → Test in Xcode using the `FishSockTransfer` scheme. See the [technical guide](../../../docs/02_FST_TECHNICAL_GUIDE.md) for commands.

The suite covers models, progress parsing, reports, source-safety checks, bundled-rsync validation, localization and transfer lifecycle behavior.

`TransferControlsLabelTests.swift` and `BundledRsyncServiceTests.swift` also have standalone entry points in the parent test directory for control labels and the checked-in runtime. Keep those checks available when changing the corresponding controls or bundled resources.
