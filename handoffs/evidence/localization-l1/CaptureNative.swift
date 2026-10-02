// FST / CenVu | (+84) 842 841 222

import AppKit
import SwiftUI

private struct LocalizationCaptureTokenStore: TelegramTokenStore {
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}

private struct LocalizationCaptureNoSendService: NotificationService {
    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        preconditionFailure("Localization capture must never send a notification")
    }
}

@main
struct CaptureNative {
    private struct Fixture {
        let name: String
        let width: CGFloat
        let height: CGFloat
        let state: TransferState
        let errorMessage: String?
        let language: AppLanguage
    }

    @MainActor
    private static func makeModel(fixture: Fixture, rsync: URL, source: URL, destination: URL) -> TransferViewModel {
        let suite = "FSTLocalizationCapture-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let model = TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: rsync),
            notificationCoordinator: NotificationCoordinator(service: LocalizationCaptureNoSendService()),
            notificationSettingsStore: NotificationSettingsStore(
                userDefaults: defaults,
                tokenStore: LocalizationCaptureTokenStore()
            )
        )

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
        model.verificationMode = fixture.state == .copyComplete ? .none : .random33
        model.bandwidthLimit = 125
        model.errorMessage = fixture.errorMessage
        model.applyTransferState(fixture.state)

        if fixture.state == .safeToFormat || fixture.state == .copyComplete {
            model.progress = 1
        }
        if fixture.state == .copyComplete || fixture.state == .safeToFormat {
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
    private static func captureSettings(language: AppLanguage, output: URL) {
        let suite = "FSTLocalizationSettingsCapture-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let preference = AppLanguagePreference(userDefaults: defaults)
        preference.select(language)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 240),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FishSockTransfer Settings"
        window.appearance = NSAppearance(named: .darkAqua)
        window.makeKeyAndOrderFront(nil)
        let host = NSHostingView(
            rootView: SettingsView(languagePreference: preference)
                .environment(\.locale, language.locale)
        )
        window.contentView = host
        host.frame = NSRect(x: 0, y: 0, width: 500, height: 240)
        host.layoutSubtreeIfNeeded()
        let languagePrefix = language == .english ? "EN" : "VI"
        capture(host, to: output.appendingPathComponent("\(languagePrefix)_SETTINGS.png"))
        print("CAPTURE \(languagePrefix)_SETTINGS content=500x240 DarkAqua syntheticFixture=YES transferStarted=NO notifySend=NO updateRequest=NO")
        window.close()
        defaults.removePersistentDomain(forName: suite)
    }

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        let rsync = URL(fileURLWithPath: CommandLine.arguments[3])
        let root = output.appendingPathComponent(".build/Fixture", isDirectory: true)
        precondition(!FileManager.default.fileExists(atPath: root.path), "Refusing to reuse an existing fixture path")
        try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("HDD", isDirectory: true)
        let destination = root.appendingPathComponent("TEMP", isDirectory: true)
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

        var fixtures: [Fixture] = []
        for language in [AppLanguage.english, .vietnamese] {
            let prefix = language == .english ? "EN" : "VI"
            fixtures.append(Fixture(name: "\(prefix)_READY", width: 1120, height: 760, state: .ready, errorMessage: nil, language: language))
            fixtures.append(Fixture(name: "\(prefix)_SAFE_TO_EJECT", width: 1120, height: 760, state: .safeToFormat, errorMessage: nil, language: language))
            fixtures.append(Fixture(name: "\(prefix)_TRANSFER_COMPLETE", width: 1120, height: 760, state: .copyComplete, errorMessage: nil, language: language))
            fixtures.append(Fixture(name: "\(prefix)_ERROR", width: 1120, height: 760, state: .error, errorMessage: "Synthetic runtime error. Keep the source media.\nRaw detail stays unchanged: /Volumes/SYNTHETIC", language: language))
            fixtures.append(Fixture(name: "\(prefix)_MANUAL_CHECK_REQUIRED", width: 1120, height: 760, state: .error, errorMessage: "MANUAL CHECK REQUIRED: Synthetic verification result needs review.\nRaw verification detail stays unchanged.", language: language))
            fixtures.append(Fixture(name: "\(prefix)_CANCELLED", width: 1120, height: 760, state: .cancelled, errorMessage: nil, language: language))
            fixtures.append(Fixture(name: "\(prefix)_READY_MINIMUM", width: 900, height: 660, state: .ready, errorMessage: nil, language: language))
            fixtures.append(Fixture(name: "\(prefix)_SAFE_TO_EJECT_MINIMUM", width: 900, height: 660, state: .safeToFormat, errorMessage: nil, language: language))
            fixtures.append(Fixture(name: "\(prefix)_MANUAL_CHECK_REQUIRED_MINIMUM", width: 900, height: 660, state: .error, errorMessage: "MANUAL CHECK REQUIRED: Synthetic verification result needs review.\nRaw verification detail stays unchanged.", language: language))
        }

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
                        initialTab: "transfer",
                        diagnosticsEnabled: false
                    )
                    .environment(\.locale, fixture.language.locale)
                )
                window.contentView = host
                try! await Task.sleep(nanoseconds: 450_000_000)
                scrollToTop(host)
                capture(host, to: output.appendingPathComponent("\(fixture.name).png"))
                print("CAPTURE \(fixture.name) content=\(Int(fixture.width))x\(Int(fixture.height)) DarkAqua syntheticFixture=YES transferStarted=NO notifySend=NO updateRequest=NO")
                if fixture.name.hasSuffix("READY_MINIMUM") {
                    let scroll = scrollViews(in: host).first!
                    let document = scroll.documentView!
                    let extent = max(0, document.bounds.height - scroll.contentView.bounds.height)
                    if extent > 0 {
                        scroll.contentView.scroll(to: NSPoint(x: 0, y: document.isFlipped ? extent : 0))
                        scroll.reflectScrolledClipView(scroll.contentView)
                        try! await Task.sleep(nanoseconds: 200_000_000)
                        capture(host, to: output.appendingPathComponent("\(fixture.name)_SCROLLED.png"))
                        print("SCROLL \(fixture.name) documentHeight=\(Int(document.bounds.height)) viewportHeight=\(Int(scroll.contentView.bounds.height)) extent=\(Int(extent))")
                    }
                }
            }

            captureSettings(language: .english, output: output)
            captureSettings(language: .vietnamese, output: output)
            try! FileManager.default.removeItem(at: root)
            app.terminate(nil)
        }
        app.run()
    }
}
