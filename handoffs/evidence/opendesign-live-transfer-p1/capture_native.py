#!/usr/bin/env python3
"""Render production SwiftUI with isolated synthetic state. Never runs a transfer.

Only ContentView's construction site is replaced in a temporary compilation
unit to inject a model. Production view bodies are compiled verbatim.
"""
from pathlib import Path
import subprocess
import tempfile
import sys

repo = Path(__file__).resolve().parents[3]
production = repo / 'FishSockTransfer/FishSockTransfer'
scratch = Path(tempfile.mkdtemp(prefix='FSTNativeCapture-'))
if sys.argv[1] == 'BEFORE':
    # Replay the original pre-mutation view bodies without changing the worktree.
    baseline = scratch / 'baseline'
    for original in production.rglob('*.swift'):
        target = baseline / original.relative_to(production)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(subprocess.check_output([
            'git', '-C', str(repo), 'show',
            '0c230033eaa413629459c1495c84e26d94bdf1c2:' + str(original.relative_to(repo))
        ]))
    production_sources = baseline
else:
    production_sources = production
content = (production_sources / 'Views/ContentView.swift').read_text()
start = content.index('    @StateObject private var viewModel:')
end = content.index('    @State private var selectedTab:', start)
content = content[:start] + '    @StateObject private var viewModel: TransferViewModel\n' + content[end:]
content = content.replace('public init() {}', 'public init(viewModel: TransferViewModel) { _viewModel = StateObject(wrappedValue: viewModel) }', 1)
(scratch / 'ContentView.swift').write_text(content)
sources = sorted(str(p) for p in production_sources.rglob('*.swift') if p.name not in ('ContentView.swift', 'FishSockTransferApp.swift'))
output = Path(sys.argv[2]).resolve()
output.mkdir(parents=True, exist_ok=True)
bundle = scratch / 'CaptureNative.app/Contents'
(bundle / 'MacOS').mkdir(parents=True)
(bundle / 'Resources').mkdir()
(bundle / 'Info.plist').write_text('<?xml version="1.0"?><plist version="1.0"><dict><key>CFBundleExecutable</key><string>CaptureNative</string><key>CFBundleIdentifier</key><string>com.fst.visual-capture</string></dict></plist>')
subprocess.run(['xcrun', 'actool', str(production / 'Assets.xcassets'), '--compile', str(bundle / 'Resources'), '--platform', 'macosx', '--minimum-deployment-target', '13.5'], check=True, stdout=subprocess.DEVNULL)
command = ['xcrun', 'swiftc', '-swift-version', '5', '-default-isolation', 'MainActor', '-D', 'DEBUG', '-parse-as-library', *sources, str(scratch / 'ContentView.swift'), str(Path(__file__).with_name('CaptureNative.swift')), '-o', str(bundle / 'MacOS/CaptureNative')]
subprocess.run(command, check=True)
subprocess.run([str(bundle / 'MacOS/CaptureNative'), sys.argv[1], str(output), *sys.argv[3:]], check=True)
if sys.argv[1] == 'AFTER':
    for label, width, height, mode in [('MIN_DARK', '900', '660', 'dark'), ('LIGHT', '1120', '760', 'light')]:
        subprocess.run([str(bundle / 'MacOS/CaptureNative'), label, str(output), width, height, mode], check=True)
