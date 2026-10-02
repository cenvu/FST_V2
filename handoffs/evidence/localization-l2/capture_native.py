#!/usr/bin/env python3
"""Capture L2 EN/VI screens with production views and isolated fixtures."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: capture_native.py OUTPUT_DIR DERIVED_DATA_DIR BUNDLED_RSYNC")

    repo = Path(__file__).resolve().parents[3]
    production = repo / "FishSockTransfer/FishSockTransfer"
    output = Path(sys.argv[1]).resolve()
    derived_data = Path(sys.argv[2]).resolve()
    rsync = Path(sys.argv[3]).resolve()
    output.mkdir(parents=True, exist_ok=True)
    scratch_root = output / ".build"
    scratch_root.mkdir(parents=True, exist_ok=True)
    scratch = Path(tempfile.mkdtemp(prefix="CaptureBuild-", dir=scratch_root))

    # Swap only ContentView's model construction site in this temporary source.
    content = (production / "Views/ContentView.swift").read_text()
    start = content.index("    @StateObject private var viewModel:")
    end = content.index("    @State private var selectedTab:", start)
    content = content[:start] + "    @StateObject private var viewModel: TransferViewModel\n" + content[end:]
    content = content.replace(
        "public init() {}",
        '''public init(viewModel: TransferViewModel, initialTab: String = "transfer", diagnosticsEnabled: Bool = false) {
        _viewModel = StateObject(wrappedValue: viewModel)
        switch initialTab {
        case "notification": _selectedTab = State(initialValue: .notification)
        case "logs": _selectedTab = State(initialValue: .logs)
        default: _selectedTab = State(initialValue: .transfer)
        }
        _showDiagnostics = State(initialValue: diagnosticsEnabled)
    }''',
        1,
    )
    if "public init(viewModel: TransferViewModel, initialTab:" not in content:
        raise SystemExit("Could not inject the fixture initializer into temporary ContentView")
    (scratch / "ContentView.swift").write_text(content)

    sources = sorted(
        str(path)
        for path in production.rglob("*.swift")
        if path.name not in ("ContentView.swift", "FishSockTransferApp.swift")
    )
    resources = scratch / "CaptureNative.app/Contents/Resources"
    executable = scratch / "CaptureNative.app/Contents/MacOS/CaptureNative"
    resources.mkdir(parents=True)
    executable.parent.mkdir(parents=True)
    (resources.parent / "Info.plist").write_text(
        '<?xml version="1.0"?><plist version="1.0"><dict>'
        '<key>CFBundleExecutable</key><string>CaptureNative</string>'
        '<key>CFBundleIdentifier</key><string>com.fst.localization.l2-capture</string>'
        '<key>CFBundleDevelopmentRegion</key><string>en</string>'
        '</dict></plist>'
    )
    subprocess.run(
        [
            "xcrun", "actool", str(production / "Assets.xcassets"), "--compile",
            str(resources), "--platform", "macosx", "--minimum-deployment-target", "13.5",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )

    app_resources = derived_data / "Build/Products/Debug/FishSockTransfer.app/Contents/Resources"
    localizations = sorted(app_resources.glob("*.lproj"))
    if not localizations:
        raise SystemExit(f"No compiled String Catalog resources found in {app_resources}")
    for localization in localizations:
        shutil.copytree(localization, resources / localization.name, dirs_exist_ok=True)

    subprocess.run(
        [
            "xcrun", "swiftc", "-swift-version", "5", "-default-isolation", "MainActor",
            "-D", "DEBUG", "-parse-as-library", *sources,
            str(scratch / "ContentView.swift"), str(output / "CaptureNative.swift"),
            "-o", str(executable),
        ],
        check=True,
    )
    subprocess.run([str(executable), str(output), str(rsync)], check=True)
    shutil.rmtree(scratch)


if __name__ == "__main__":
    main()
