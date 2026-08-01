# FST v1.3.5 - Workflow Controls and Retry

## v1.3.5 - 2026-08-02

### Added
* Added Clear Folder controls for Source and Destination.
* Added Start-to-Cancel behavior during copy and verification, with confirmation and duplicate-cancel suppression.
* Added Retry after transfer errors using a complete safe workflow.
* Added persistent security-scoped Source and Destination access across app relaunch.

### Fixed
* Fixed external-volume free space being reported as zero when macOS returned a misleading important-usage capacity value.
* Fixed Start remaining disabled when ordinary destination capacity proved sufficient.
* Fixed Retry admission and cleanup ordering so delayed or duplicate workflows cannot start.
* Fixed stale, corrupt, deleted, or inaccessible saved folder access handling.
* Fixed late bookmark save and restore operations overwriting newer folder choices.

### Verification
* Confirmed the full canonical XCTest suite passes before release.
* Confirmed the packaged app reports version 1.3.5 build 20260802.
* Confirmed the packaged app contains bundled rsync 3.4.4.
* Confirmed sandbox, network-client, user-selected read-write, and app-scoped bookmark entitlements are preserved.

### Safety
* Clear Folder removes only FST selection and saved access; it never deletes or modifies folder contents.
* Retry performs a fresh validation, copy, and verification workflow and does not claim exact byte-level resume.
* Verification mode None ends at TRANSFER COMPLETE and never SAFE TO EJECT.
* SAFE TO EJECT still requires successful copy and verification.
* The macOS package is ad-hoc signed and is not notarized or Developer ID signed.
