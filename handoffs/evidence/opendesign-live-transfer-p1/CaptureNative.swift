import AppKit
import SwiftUI

nonisolated final class EmptyTokenStore: TelegramTokenStore {
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}

@main
struct CaptureNative {
    @MainActor static func views(_ root: NSView) -> [NSView] {
        [root] + root.subviews.flatMap { views($0) }
    }
    @MainActor static func elements(_ root: NSObject, depth: Int = 0) -> [NSObject] {
        guard depth < 20 else { return [] }
        let children = root.accessibilityAttributeValue(.children) as? [NSObject] ?? []
        return [root] + children.flatMap { elements($0, depth: depth + 1) }
    }

    @MainActor static func label(_ node: NSObject) -> String {
        (node.accessibilityAttributeValue(.description) as? String)
            ?? (node.accessibilityAttributeValue(.title) as? String) ?? ""
    }

    @MainActor static func click(_ point: NSPoint, in window: NSWindow) {
        for kind in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
            let event = NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                context: nil, eventNumber: 1, clickCount: 1, pressure: 1)!
            NSApplication.shared.postEvent(event, atStart: false)
        }
    }

    @MainActor static func main() {
        let app = NSApplication.shared
        // Request AppKit's accessibility tree for in-process native action QA.
        app.setValue(true, forKey: "accessibilityEnhancedUserInterface")
        app.setActivationPolicy(.regular)
        let prefix = CommandLine.arguments[1]
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let width = CommandLine.arguments.count > 3 ? Double(CommandLine.arguments[3])! : 1120
        let height = CommandLine.arguments.count > 4 ? Double(CommandLine.arguments[4])! : 760
        let appearance = CommandLine.arguments.count > 5 ? CommandLine.arguments[5] : "dark"
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("FST-Visual-P1-\(UUID())")
        try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("CAM_A_CARD_001")
        let destination = root.appendingPathComponent("OFFLOAD")
        for url in [source, destination] { try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) }
        let defaults = UserDefaults(suiteName: "FSTNativeCapture-\(UUID())")!
        let vm = TransferViewModel(bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil),
            notificationSettingsStore: NotificationSettingsStore(userDefaults: defaults, tokenStore: EmptyTokenStore()))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "FishSock Transfer"
        window.appearance = NSAppearance(named: appearance == "light" ? .aqua : .darkAqua)
        let host = NSHostingView(rootView: ContentView(viewModel: vm))
        window.contentView = host
        window.center()
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        Task { @MainActor in
            // Allow null bookmark restoration/rsync availability task to settle.
            try! await Task.sleep(nanoseconds: 300_000_000)
            vm.sourceURL = source
            vm.destinationURL = destination
            let bytes: Int64 = 24_000_000_000
            vm.sourceMetadata = SourceStorageMetadata(folderName: source.lastPathComponent, fullPath: source.path,
                totalSizeBytes: bytes, fileCount: 240, folderCount: 4)
            vm.destinationMetadata = DestinationStorageMetadata(freeSpaceBytes: 96_000_000_000, filesystem: "APFS", isWritable: true,
                filesystemIdentity: "apfs", allocationUnit: 4096)
            vm.capacityAssessment = try! DestinationCapacityAssessment.make(source: source, destination: destination,
                logicalPayloadBytes: bytes, roundedPayloadBytes: 24_000_921_600, snapshot: vm.destinationMetadata!)
            vm.bundledRsyncInfo = BundledRsyncInfo(executableURL: root.appendingPathComponent("rsync"), version: "3.4.4", diagnostics: [])
            for (name, state) in [("READY", TransferState.ready), ("COPYING", .copying), ("VERIFYING", .verifying), ("SAFE_TO_EJECT", .safeToFormat)] {
                vm.applyTransferState(state)
                let copying = state == .copying
                let copied: Int64 = state == .ready ? 0 : copying ? 10_800_000_000 : bytes
                vm.copyRuntimeSnapshot = CopyRuntimeSnapshot(elapsedSeconds: state == .ready ? 0 : copying ? 72 : 160,
                    currentItem: "CAM_A/CLIP_0042.mov", copiedBytes: copied, totalBytes: bytes,
                    copiedFiles: state == .ready ? 0 : copying ? 108 : 240, totalFiles: 240,
                    progressFraction: Double(copied) / Double(bytes), currentSpeedBytesPerSecond: copying ? 150_000_000 : nil,
                    averageSpeedBytesPerSecond: state == .ready ? nil : 150_000_000, etaSeconds: copying ? 88 : nil,
                    signalSource: .rsync, lastObservedAt: Date(), activityState: copying ? .copying : .complete)
                vm.progress = state == .ready ? 0 : copying ? 45 : state == .verifying ? 0.62 : 1
                vm.speed = copying ? 150 : 0
                vm.eta = copying ? 88 : 0
                vm.currentFile = copying ? "CAM_A/CLIP_0042.mov" : ""
                if state == .verifying { vm.setVerifyElapsedSecondsForTesting(38) }
                try! await Task.sleep(nanoseconds: 250_000_000)
                host.layoutSubtreeIfNeeded()
                let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try! bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("\(prefix)_\(name).png"))
                print("CAPTURE \(prefix)_\(name) content=\(width)x\(height) pixels=\(bitmap.pixelsWide)x\(bitmap.pixelsHigh) appearance=\(appearance)")
            }
            if prefix == "MIN_DARK" {
                guard let scroll = views(host).compactMap({ $0 as? NSScrollView }).first,
                      let document = scroll.documentView else { fatalError("Missing native scroll surface") }
                precondition(document.bounds.height > scroll.contentView.bounds.height)
                let bottom = max(0, document.bounds.height - scroll.contentView.bounds.height)
                scroll.contentView.scroll(to: NSPoint(x: 0, y: bottom))
                scroll.reflectScrolledClipView(scroll.contentView)
                try! await Task.sleep(nanoseconds: 250_000_000)
                host.layoutSubtreeIfNeeded()
                document.scrollToVisible(NSRect(x: 0, y: document.bounds.maxY - 1, width: 1, height: 1))
                try! await Task.sleep(nanoseconds: 250_000_000)
                let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try! bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("MIN_DARK_SCROLLED.png"))
                print("QA PASS minimum window: native scroll reaches secondary runtime/current item; footer remains fixed")
            }
            if prefix == "AFTER" {
                vm.applyTransferState(.ready)
                try! await Task.sleep(nanoseconds: 300_000_000)
                let dump = elements(host).map { "\(String(describing: $0.accessibilityAttributeValue(.role))) | \(label($0)) | \(String(describing: $0.accessibilityAttributeValue(.value)))" }.joined(separator: "\n")
                try! dump.write(to: output.appendingPathComponent("QA_ACCESSIBILITY.txt"), atomically: true, encoding: .utf8)
                for actionLabel in ["Choose Source Folder", "Choose Destination Folder"] {
                    var sawPanel = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let panel = app.modalWindow as? NSOpenPanel {
                            precondition(panel.canChooseDirectories && !panel.canChooseFiles && !panel.canCreateDirectories)
                            sawPanel = true
                            panel.cancel(nil)
                        }
                    }
                    click(NSPoint(x: width - 110, y: height - (actionLabel.contains("Source") ? 110 : 194)), in: window)
                    try! await Task.sleep(nanoseconds: 900_000_000)
                    precondition(sawPanel, "Native folder panel must open: \(actionLabel)")
                    print("QA PASS \(actionLabel): native directory-only panel opened and cancelled; no selection/transfer")
                }
                for tabLabel in ["NOTIFICATION", "TECHNICAL LOG"] {
                    click(NSPoint(x: width - (tabLabel == "NOTIFICATION" ? 260 : 110), y: height - 30), in: window)
                    try! await Task.sleep(nanoseconds: 300_000_000)
                    host.layoutSubtreeIfNeeded()
                    let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                    host.cacheDisplay(in: host.bounds, to: bitmap)
                    try! bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("QA_\(tabLabel.replacingOccurrences(of: " ", with: "_")).png"))
                    print("QA CLICK \(tabLabel): local native mouse event; inspect QA PNG for switched content")
                }
            }
            try! FileManager.default.removeItem(at: root)
            app.terminate(nil)
        }
        app.run()
    }
}
