# FST Technical Guide

FST / FishSock Transfer is a native SwiftUI macOS application for media offload. It supports macOS 13.5+ with separate Apple Silicon (arm64) and Intel (x86_64) packages. The current release is 1.4.0, build 20261003.

## Build and test

Open `FishSockTransfer/FishSockTransfer.xcodeproj` in Xcode, select the `FishSockTransfer` scheme and a compatible Mac destination. The repository is Xcode-based; no JavaScript toolchain is required.

From the repository root on Apple Silicon:

```sh
xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/Developer CODE_SIGNING_ALLOWED=NO build

xcodebuild -project FishSockTransfer/FishSockTransfer.xcodeproj \
  -scheme FishSockTransfer -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath .build/DeveloperTests CODE_SIGNING_ALLOWED=NO \
  -parallel-testing-enabled NO test
```

On an Intel Mac, use `arch=x86_64`. The XCTest baseline is 301 tests. Some resource and presentation checks also have standalone entry points under `FishSockTransfer/Tests/`; see [XCTest coverage](../FishSockTransfer/Tests/XCTest/README.md). Use disposable fixtures for filesystem tests.

## Source layout and ownership

Production source is under `FishSockTransfer/FishSockTransfer/`. Tests linked to the Xcode scheme are under `FishSockTransfer/Tests/XCTest/`. The top-level `Tests/UnitTests/` directory contains additional test sources; it is not the canonical Xcode test target.

The dependency flow is:

```text
SwiftUI Views -> ViewModels -> Coordinators -> Engines -> Services
```

- `Views/` presents state and collects user input.
- `ViewModels/` prepares presentation data and forwards actions.
- `Coordinators/TransferCoordinator.swift` owns transfer-state changes and lifecycle ordering.
- `Engines/` owns copy, progress parsing, verification and TXT report work.
- `Services/` owns bundled executable resolution, filesystem access, bookmarks, logging and optional network services.
- `Models/` defines requests, results, storage information and state.

Copying, hashing, scanning and report work must stay off the UI thread. Cancellation and terminal cleanup must finish before another job can take ownership. Late events from an old job must not change a new job's state.

## Transfer runtime

Production transfer must use bundled **rsync 3.4.4**. `BundledRsyncService` validates the binary and version; failure must be explicit. Do not fall back to system, Homebrew or MacPorts rsync.

The canonical resources under `FishSockTransfer/FishSockTransfer/` include the ARM64 rsync binary and its supporting dylibs. The Xcode build copies these into the app. An Intel application build alone is therefore insufficient for an Intel package: [the Intel packaging script](../scripts/package-local-intel.sh) replaces only the staged runtime with a separately validated native Intel rsync binary and removes the ARM dylibs from staging.

Bandwidth presets are 50 / 75 / 100 / 125 / 150 / 175 / 200 MB/s. Unlimited omits `--bwlimit`. Metadata exclusions must remain explicit and must never delete or modify source contents. An existing destination job folder blocks the operation rather than silently merging or overwriting.

## Safety semantics

Each job has one source and one destination. Source media is read-only: no deletion, renaming, metadata writes, permission changes, formatting or ejection.

```text
SOURCE -> COPY -> VERIFY -> FINAL STATUS AND REPORT
```

- None performs copy only and ends at **TRANSFER COMPLETE**.
- Sample 33% uses SHA256 on a subset of files.
- Full 100% uses non-cryptographic xxHash64 on all files.
- **SAFE TO EJECT** requires complete successful copy and successful required verification.
- Failure, cancellation, incomplete work, uncertainty and None never authorize SAFE TO EJECT.

Progress estimates, destination observations and Telegram delivery cannot determine copy or verification success. Preserve source media when the result is uncertain. FST does not authorize formatting or reuse and does not replace independent backups.

## Packaging

[scripts/package-local-arm64.sh](../scripts/package-local-arm64.sh) builds, stages, validates and ad-hoc signs an ARM64 ZIP. It checks rsync version, architectures, loader paths, bundle structure and signing. Use `APP_VERSION` and `BUILD_NUMBER` to select package metadata. ARM64 packaging also requires `RSYNC_ARM64_SOURCE_ARCHIVE` pointing to a reviewed complete corresponding-source archive; archive readability alone does not prove completeness.

For a native Intel package, run [scripts/build-rsync-intel.sh](../scripts/build-rsync-intel.sh) on an Intel Mac to build checksum-validated upstream rsync 3.4.4. It uses included popt/zlib with optional OpenSSL, xxhash, zstd and lz4 disabled. Set `RSYNC_INTEL` to the resulting binary, then run `scripts/package-local-intel.sh`. [scripts/audit-intel-package.py](../scripts/audit-intel-package.py) checks the staged app and ZIP, including native architecture, loader dependencies, privacy and a disposable copy smoke test.

See [third-party licenses](legal/THIRD_PARTY_LICENSES.md) for notices and corresponding-source requirements before distribution. The scripts produce local ad-hoc packages; they do not notarize or Developer ID sign them. Existing release tags and assets must not be replaced by packaging work.

The workflows under `.github/workflows/` record the version-specific ARM64 and Intel release gates. They reject an existing tag or existing Intel asset and are not general update workflows.

## Further documentation

- [Product requirements](01_PRD.md)
- [Release notes](releases/README.md)
- [Telegram setup](guides/telegram-bot-setup.md)
- [Licensing and operator responsibility](legal/README.md)
