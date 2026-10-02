import AppKit
import SwiftUI

nonisolated final class Patch5FixtureTokenStore: TelegramTokenStore {
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}

nonisolated final class Patch5NoSendService: NotificationService, @unchecked Sendable {
    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        fatalError("Patch 5 capture fixture must never send a notification")
    }
}

@main
struct CaptureNative {
    private struct Fixture {
        let name: String
        let width: CGFloat
        let height: CGFloat
        let tab: String
        let state: TransferState?
        let errorMessage: String?
        let populatedLogs: Bool
        let diagnostics: Bool
        let captureBottom: Bool
        let showCopyToast: Bool
    }

    @MainActor
    private static func makeModel(fixture: Fixture, rsync: URL, source: URL, destination: URL) -> TransferViewModel {
        let domain = "FSTPatch5Capture-\(UUID())"
        let defaults = UserDefaults(suiteName: domain)!
        let model = TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: rsync),
            notificationCoordinator: NotificationCoordinator(service: Patch5NoSendService()),
            notificationSettingsStore: NotificationSettingsStore(
                userDefaults: defaults,
                tokenStore: Patch5FixtureTokenStore()
            )
        )

        if fixture.state != nil {
            let payloadBytes: Int64 = 24_000_000_000
            model.sourceURL = source
            model.destinationURL = destination
            model.sourceMetadata = SourceStorageMetadata(
                folderName: source.lastPathComponent,
                fullPath: source.path,
                totalSizeBytes: payloadBytes,
                fileCount: 240,
                folderCount: 4
            )
            model.destinationMetadata = DestinationStorageMetadata(
                freeSpaceBytes: 96_000_000_000,
                filesystem: "APFS",
                isWritable: true,
                filesystemIdentity: "apfs",
                allocationUnit: 4096
            )
            model.capacityAssessment = try! DestinationCapacityAssessment.make(
                source: source,
                destination: destination,
                logicalPayloadBytes: payloadBytes,
                roundedPayloadBytes: 24_000_921_600,
                snapshot: model.destinationMetadata!
            )

            if fixture.state == .copyComplete {
                model.verificationMode = .none
            } else if fixture.state == .safeToFormat || fixture.state == .verifying {
                model.verificationMode = .random33
            }
            model.errorMessage = fixture.errorMessage
            model.applyTransferState(fixture.state!)

            switch fixture.state! {
            case .ready, .validating, .error, .cancelled:
                break
            case .copying:
                model.copyRuntimeSnapshot = CopyRuntimeSnapshot(
                    elapsedSeconds: 72,
                    currentItem: "CAM_A/CLIP_0042.mov",
                    copiedBytes: 10_800_000_000,
                    totalBytes: payloadBytes,
                    copiedFiles: 108,
                    totalFiles: 240,
                    progressFraction: 0.45,
                    currentSpeedBytesPerSecond: 150_000_000,
                    averageSpeedBytesPerSecond: 150_000_000,
                    etaSeconds: 88,
                    signalSource: .rsync,
                    lastObservedAt: Date(timeIntervalSince1970: 1_790_920_000),
                    activityState: .copying
                )
                model.progress = 45
                model.speed = 150
                model.eta = 88
                model.currentFile = "CAM_A/CLIP_0042.mov"
            case .verifying, .copyComplete, .safeToFormat:
                model.copyRuntimeSnapshot = CopyRuntimeSnapshot(
                    elapsedSeconds: 160,
                    currentItem: "CAM_A/CLIP_0042.mov",
                    copiedBytes: payloadBytes,
                    totalBytes: payloadBytes,
                    copiedFiles: 240,
                    totalFiles: 240,
                    progressFraction: 1,
                    currentSpeedBytesPerSecond: nil,
                    averageSpeedBytesPerSecond: 150_000_000,
                    etaSeconds: nil,
                    signalSource: .rsync,
                    lastObservedAt: Date(timeIntervalSince1970: 1_790_920_000),
                    activityState: .complete
                )
                model.progress = fixture.state == .verifying ? 0.62 : 1
                model.speed = 0
                model.eta = 0
                model.currentFile = ""
                if fixture.state == .verifying || fixture.state == .safeToFormat {
                    model.setVerifyElapsedSecondsForTesting(38)
                }
            }
        }

        if fixture.populatedLogs {
            let anchor = Date(timeIntervalSince1970: 1_790_920_000)
            model.logs = [
                LogEntry(timestamp: anchor, category: .system, message: "Technical log view opened."),
                LogEntry(timestamp: anchor.addingTimeInterval(4), category: .info, message: "Source volume mounted read-only."),
                LogEntry(timestamp: anchor.addingTimeInterval(8), category: .transfer, message: "Destination folder is available."),
                LogEntry(timestamp: anchor.addingTimeInterval(12), category: .stdout, message: "sending incremental file list"),
                LogEntry(timestamp: anchor.addingTimeInterval(16), category: .file, message: "A001_C003_1001AB.mov"),
                LogEntry(timestamp: anchor.addingTimeInterval(20), category: .progress, message: "Copy progress: 68% · 184.2 MB/s"),
                LogEntry(timestamp: anchor.addingTimeInterval(24), category: .verify, message: "Verification comparison is ready."),
                LogEntry(timestamp: anchor.addingTimeInterval(28), category: .warning, message: "Synthetic warning remains visible to the operator."),
                LogEntry(timestamp: anchor.addingTimeInterval(32), category: .success, message: "Synthetic copy record completed."),
                LogEntry(timestamp: anchor.addingTimeInterval(36), category: .stderr, message: "Synthetic stderr category sample."),
                LogEntry(timestamp: anchor.addingTimeInterval(40), category: .error, message: "Synthetic error category sample; no transfer was started."),
                LogEntry(timestamp: anchor.addingTimeInterval(44), category: .info, message: "A long synthetic operator message demonstrates natural wrapping inside the selectable feed without changing production log text."),
                LogEntry(timestamp: anchor.addingTimeInterval(48), category: .info, message: "DIAG [RSYNC RAW] synthetic diagnostic entry is hidden by the production filter."),
                LogEntry(timestamp: anchor.addingTimeInterval(52), category: .info, message: "[VERIFY DIAG] synthetic comparison detail is hidden by the production filter.")
            ]
        }

        return model
    }

    @MainActor
    private static func scrollViews(in view: NSView) -> [NSScrollView] {
        (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap { scrollViews(in: $0) }
    }

    @MainActor
    private static func scrollToTop(_ view: NSView) {
        for scroll in scrollViews(in: view) {
            guard let document = scroll.documentView else { continue }
            let extent = max(0, document.bounds.height - scroll.contentView.bounds.height)
            scroll.contentView.scroll(to: NSPoint(x: 0, y: document.isFlipped ? 0 : extent))
            scroll.reflectScrolledClipView(scroll.contentView)
            print("RESET_SCROLL flipped=\(document.isFlipped) originY=\(Int(scroll.contentView.bounds.origin.y)) extent=\(Int(extent))")
        }
    }

    @MainActor
    private static func capture(_ host: NSView, to url: URL) {
        host.layoutSubtreeIfNeeded()
        let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try! bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let prefix = CommandLine.arguments[1]
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let rsync = URL(fileURLWithPath: CommandLine.arguments[3])
        let locale = Locale(identifier: CommandLine.arguments[4])
        let root = URL(fileURLWithPath: CommandLine.arguments[5], isDirectory: true)
        precondition(!FileManager.default.fileExists(atPath: root.path), "Refusing to reuse an existing fixture path")
        try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("CAM_A_CARD_001")
        let destination = root.appendingPathComponent("OFFLOAD")
        for url in [source, destination] {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FishSock Transfer"
        window.appearance = NSAppearance(named: .darkAqua)
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)

        let fixtures: [Fixture] = [
            Fixture(name: "TRANSFER_READY", width: 1120, height: 760, tab: "transfer", state: .ready, errorMessage: nil, populatedLogs: false, diagnostics: false, captureBottom: false, showCopyToast: false),
            Fixture(name: "NOTIFICATION", width: 1120, height: 760, tab: "notification", state: nil, errorMessage: nil, populatedLogs: false, diagnostics: false, captureBottom: false, showCopyToast: false),
            Fixture(name: "TECH_LOG", width: 1120, height: 760, tab: "logs", state: nil, errorMessage: nil, populatedLogs: true, diagnostics: false, captureBottom: false, showCopyToast: false),
            Fixture(name: "TECH_LOG_MINIMUM", width: 900, height: 660, tab: "logs", state: nil, errorMessage: nil, populatedLogs: true, diagnostics: false, captureBottom: false, showCopyToast: false),
            Fixture(name: "COPY_TOAST", width: 1120, height: 760, tab: "logs", state: nil, errorMessage: nil, populatedLogs: true, diagnostics: false, captureBottom: false, showCopyToast: true)
        ]

        Task { @MainActor in
            for fixture in fixtures {
                let model = makeModel(fixture: fixture, rsync: rsync, source: source, destination: destination)
                for _ in 0..<30 {
                    if model.bundledRsyncInfo.isAvailable { break }
                    try! await Task.sleep(nanoseconds: 100_000_000)
                }
                precondition(model.bundledRsyncInfo.isAvailable, "Bundled rsync 3.4.4 should remain available for truthful presentation")
                window.setContentSize(NSSize(width: fixture.width, height: fixture.height))
                let host = NSHostingView(
                    rootView: ContentView(
                        viewModel: model,
                        initialTab: fixture.tab,
                        diagnosticsEnabled: fixture.diagnostics,
                        showCopyToast: fixture.showCopyToast
                    )
                    .environment(\.locale, locale)
                )
                window.contentView = host
                try! await Task.sleep(nanoseconds: 450_000_000)
                scrollToTop(host)
                capture(host, to: output.appendingPathComponent("\(prefix)_\(fixture.name).png"))
                print("CAPTURE \(prefix)_\(fixture.name) content=\(Int(fixture.width))x\(Int(fixture.height)) DarkAqua syntheticFixture=YES transferStarted=NO notifySend=NO updateRequest=NO")

                if fixture.captureBottom {
                    let scroll = scrollViews(in: host).first!
                    let document = scroll.documentView!
                    let extent = max(0, document.bounds.height - scroll.contentView.bounds.height)
                    scroll.contentView.scroll(to: NSPoint(x: 0, y: document.isFlipped ? extent : 0))
                    scroll.reflectScrolledClipView(scroll.contentView)
                    try! await Task.sleep(nanoseconds: 200_000_000)
                    capture(host, to: output.appendingPathComponent("\(prefix)_\(fixture.name)_SCROLLED.png"))
                    print("SCROLL \(prefix)_\(fixture.name) documentHeight=\(Int(document.bounds.height)) viewportHeight=\(Int(scroll.contentView.bounds.height)) extent=\(Int(extent))")
                }
            }
            try! FileManager.default.removeItem(at: root)
            app.terminate(nil)
        }
        app.run()
    }
}
