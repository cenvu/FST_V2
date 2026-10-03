#!/usr/bin/env python3
"""Capture whole-app states using production SwiftUI and isolated fixtures."""
from pathlib import Path
import shutil
import subprocess
import sys

repo = Path(__file__).resolve().parents[3]
production = repo / "FishSockTransfer/FishSockTransfer"
output = Path(sys.argv[2]).resolve()
output.mkdir(parents=True, exist_ok=True)
scratch = output / f".capture-build-{sys.argv[1]}"
if scratch.exists():
    raise SystemExit(f"Refusing to reuse capture build directory: {scratch}")
scratch.mkdir(parents=True)

# Replace only ContentView's construction site in a temporary compilation unit.
# The production view bodies and all other production sources stay byte-exact.
content = (production / "Views/ContentView.swift").read_text()
content = content.replace(
    "    @State private var copyFeedbackState = TechnicalLogCopyFeedbackState()",
    "    @State private var copyFeedbackState: TechnicalLogCopyFeedbackState",
    1,
)
start = content.index("    @StateObject private var viewModel:")
end = content.index("    @State private var selectedTab:", start)
content = content[:start] + "    @StateObject private var viewModel: TransferViewModel\n" + content[end:]
content = content.replace(
    "public init() {}",
    '''public init(viewModel: TransferViewModel, initialTab: String = "transfer", diagnosticsEnabled: Bool = false, showCopyToast: Bool = false) {
        _viewModel = StateObject(wrappedValue: viewModel)
        switch initialTab {
        case "notification": _selectedTab = State(initialValue: .notification)
        case "logs": _selectedTab = State(initialValue: .logs)
        default: _selectedTab = State(initialValue: .transfer)
        }
        _showDiagnostics = State(initialValue: diagnosticsEnabled)
        var feedbackState = TechnicalLogCopyFeedbackState()
        if showCopyToast { feedbackState.record(copySucceeded: true) }
        _copyFeedbackState = State(initialValue: feedbackState)
    }''',
    1,
)
if "public init(viewModel: TransferViewModel, initialTab:" not in content or "showCopyToast: Bool = false" not in content:
    raise SystemExit("Could not inject the fixture initializer into temporary ContentView")
(scratch / "ContentView.swift").write_text(content)

sources = sorted(
    str(path)
    for path in production.rglob("*.swift")
    if path.name not in ("ContentView.swift", "FishSockTransferApp.swift")
)
bundle = scratch / "CaptureNative.app/Contents"
(bundle / "MacOS").mkdir(parents=True)
(bundle / "Resources").mkdir()
(bundle / "Info.plist").write_text(
    '<?xml version="1.0"?><plist version="1.0"><dict>'
    '<key>CFBundleExecutable</key><string>CaptureNative</string>'
    '<key>CFBundleIdentifier</key><string>com.fst.visual-finalization.capture</string>'
    '<key>CFBundleDevelopmentRegion</key><string>en</string>'
    '</dict></plist>'
)
subprocess.run(
    [
        "xcrun", "actool", str(production / "Assets.xcassets"), "--compile",
        str(bundle / "Resources"), "--platform", "macosx",
        "--minimum-deployment-target", "13.5",
    ],
    check=True,
    stdout=subprocess.DEVNULL,
)
subprocess.run(
    [
        "xcrun", "swiftc", "-swift-version", "5", "-default-isolation", "MainActor",
        "-D", "DEBUG", "-parse-as-library", "-module-cache-path", str(scratch / "ModuleCache"),
        *sources, str(scratch / "ContentView.swift"), str(Path(__file__).with_name("CaptureNative.swift")),
        "-o", str(bundle / "MacOS/CaptureNative"),
    ],
    check=True,
)
localization_resources = Path(sys.argv[4])
for localization in ("en.lproj", "vi.lproj"):
    source = localization_resources / localization
    if source.is_dir():
        shutil.copytree(source, bundle / "Resources" / localization)

subprocess.run(
    [
        str(bundle / "MacOS/CaptureNative"), sys.argv[1], str(output),
        str(production / "rsync"), sys.argv[3], str(scratch / "SyntheticFixtures"),
    ],
    check=True,
)
shutil.rmtree(scratch)
