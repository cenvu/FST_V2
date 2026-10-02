#!/usr/bin/env python3
"""Capture Technical Log using isolated deterministic native fixtures."""
from pathlib import Path
import subprocess
import sys
import tempfile

repo = Path(__file__).resolve().parents[4]
production = repo / 'FishSockTransfer/FishSockTransfer'
scratch = Path(tempfile.mkdtemp(prefix='FSTPatch4NativeCapture-'))
prefix = sys.argv[1]
output = Path(sys.argv[2]).resolve()
output.mkdir(parents=True, exist_ok=True)

if prefix == 'BEFORE':
    production_sources = scratch / 'baseline'
    for original in production.rglob('*.swift'):
        target = production_sources / original.relative_to(production)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(subprocess.check_output([
            'git', '-C', str(repo), 'show',
            'a87479af645a344bf7ccae0722f3829348ea0fb8:' + str(original.relative_to(repo))
        ]))
else:
    production_sources = production

content = (production_sources / 'Views/ContentView.swift').read_text()
start = content.index('    @StateObject private var viewModel:')
end = content.index('    @State private var selectedTab:', start)
content = content[:start] + '    @StateObject private var viewModel: TransferViewModel\n' + content[end:]
content = content.replace('public init() {}', '''public init(viewModel: TransferViewModel, diagnosticsEnabled: Bool = false) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedTab = State(initialValue: .logs)
        _showDiagnostics = State(initialValue: diagnosticsEnabled)
    }''', 1)
(scratch / 'ContentView.swift').write_text(content)

sources = sorted(str(p) for p in production_sources.rglob('*.swift')
                 if p.name not in ('ContentView.swift', 'FishSockTransferApp.swift'))
bundle = scratch / 'CaptureNative.app/Contents'
(bundle / 'MacOS').mkdir(parents=True)
(bundle / 'Resources').mkdir()
(bundle / 'Info.plist').write_text(
    '<?xml version="1.0"?><plist version="1.0"><dict>'
    '<key>CFBundleExecutable</key><string>CaptureNative</string>'
    '<key>CFBundleIdentifier</key><string>com.fst.patch4.visual-capture</string>'
    '</dict></plist>'
)
subprocess.run([
    'xcrun', 'actool', str(production / 'Assets.xcassets'), '--compile',
    str(bundle / 'Resources'), '--platform', 'macosx',
    '--minimum-deployment-target', '13.5'
], check=True, stdout=subprocess.DEVNULL)
subprocess.run([
    'xcrun', 'swiftc', '-swift-version', '5', '-default-isolation', 'MainActor',
    '-D', 'DEBUG', '-parse-as-library', *sources, str(scratch / 'ContentView.swift'),
    str(Path(__file__).with_name('CaptureNative.swift')),
    '-o', str(bundle / 'MacOS/CaptureNative')
], check=True)
subprocess.run([
    str(bundle / 'MacOS/CaptureNative'), prefix, str(output),
    str(production / 'rsync')
], check=True)
