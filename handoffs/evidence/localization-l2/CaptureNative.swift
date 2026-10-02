// FST / CenVu | Synthetic L2 localization capture harness

import AppKit
import SwiftUI

private struct CaptureTokenStore: TelegramTokenStore {
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}

private struct CaptureNoSendService: NotificationService {
    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        preconditionFailure("L2 capture must never send a Telegram notification")
    }
}

@main
struct CaptureNative {
    private struct Fixture {
        let name: String
        let width: CGFloat
        let height: CGFloat
        let language: AppLanguage
        let initialTab: String
        let diagnosticsEnabled: Bool
        let logKind: String
    }

    private static var defaultsSuites: [String] = []

    @MainActor
    private static func makeModel(rsync: URL, fixture: Fixture) -> TransferViewModel {
        let suite = "FSTLocalizationL2Capture-\(UUID().uuidString)"
        defaultsSuites.append(suite)
        let defaults = UserDefaults(suiteName: suite)!
        let model = TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: rsync),
            notificationCoordinator: NotificationCoordinator(service: CaptureNoSendService()),
            notificationSettingsStore: NotificationSettingsStore(
                userDefaults: defaults,
                tokenStore: CaptureTokenStore()
            )
        )
        let source = URL(fileURLWithPath: "/synthetic/CARD_A", isDirectory: true)
        let destination = URL(fileURLWithPath: "/synthetic/RAID_A", isDirectory: true)
        model.sourceURL = source
        model.destinationURL = destination
        model.sourceMetadata = SourceStorageMetadata(
            folderName: source.lastPathComponent,
            fullPath: source.path,
            totalSizeBytes: 24_000_000_000,
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
            logicalPayloadBytes: 24_000_000_000,
            roundedPayloadBytes: 24_000_921_600,
            snapshot: model.destinationMetadata!
        )
        model.verificationMode = .random33
        model.bandwidthLimit = 125

        switch fixture.logKind {
        case "empty":
            model.logs = []
        case "populated":
            model.logs = [
                LogEntry(id: id(1), timestamp: Date(timeIntervalSince1970: 1_790_951_100), category: .info, message: "Synthetic capture fixture only; no media operation"),
                LogEntry(id: id(2), timestamp: Date(timeIntervalSince1970: 1_790_951_101), category: .warning, message: "WARNING: synthetic offline fixture warning"),
                LogEntry(id: id(3), timestamp: Date(timeIntervalSince1970: 1_790_951_102), category: .stderr, message: "rsync: synthetic stderr /Volumes/SYNTHETIC/CARD_A"),
                LogEntry(id: id(4), timestamp: Date(timeIntervalSince1970: 1_790_951_103), category: .info, message: "DIAG [CAPTURE] raw diagnostic fixture line")
            ]
        default:
            model.logs = []
        }

        if fixture.initialTab == "notification" {
            model.notificationSettings = NotificationSettings(
                isTelegramEnabled: false,
                heartbeatInterval: fixture.language == .vietnamese ? .thirtyMinutes : .fifteenMinutes,
                messageDetail: fixture.language == .vietnamese ? .compact : .standard
            )
            model.notificationStatus = NotificationRuntimeStatus(
                telegramStatus: "Disabled",
                connectionStatus: .notTested,
                lastMessageStatus: "No messages sent",
                lastErrorSummary: "Offline fixture; no send."
            )
        } else if fixture.name.hasSuffix("SAFE_TO_EJECT") {
            model.verificationMode = .random33
            model.applyTransferState(.safeToFormat)
            model.progress = 1
        } else if fixture.name.hasSuffix("READY") {
            model.applyTransferState(.ready)
        }
        return model
    }

    private static func id(_ value: UInt32) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012X", value))!
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
    private static func scrollToBottom(_ view: NSView) {
        for scroll in scrollViews(in: view) {
            guard let document = scroll.documentView else { continue }
            let extent = max(0, document.bounds.height - scroll.contentView.bounds.height)
            scroll.contentView.scroll(to: NSPoint(x: 0, y: document.isFlipped ? extent : 0))
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
        let suite = "FSTLocalizationL2SettingsCapture-\(UUID().uuidString)"
        defaultsSuites.append(suite)
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
        let prefix = language == .english ? "EN" : "VI"
        capture(host, to: output.appendingPathComponent("\(prefix)_SETTINGS.png"))
        print("CAPTURE \(prefix)_SETTINGS content=500x240 DarkAqua syntheticFixture=YES transferStarted=NO notifySend=NO updateRequest=NO")
        window.close()
    }

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let rsync = URL(fileURLWithPath: CommandLine.arguments[2])
        let fixtureRoot = output.appendingPathComponent(".build/Fixture", isDirectory: true)
        precondition(!FileManager.default.fileExists(atPath: fixtureRoot.path), "Refusing to reuse an existing fixture path")
        try! FileManager.default.createDirectory(at: fixtureRoot, withIntermediateDirectories: true)
        for name in ["CARD_A", "RAID_A"] {
            try! FileManager.default.createDirectory(at: fixtureRoot.appendingPathComponent(name, isDirectory: true), withIntermediateDirectories: true)
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
            Fixture(name: "EN_NOTIFICATION", width: 1120, height: 760, language: .english, initialTab: "notification", diagnosticsEnabled: false, logKind: "none"),
            Fixture(name: "VI_NOTIFICATION", width: 1120, height: 760, language: .vietnamese, initialTab: "notification", diagnosticsEnabled: false, logKind: "none"),
            Fixture(name: "EN_NOTIFICATION_MINIMUM", width: 900, height: 660, language: .english, initialTab: "notification", diagnosticsEnabled: false, logKind: "none"),
            Fixture(name: "VI_NOTIFICATION_MINIMUM", width: 900, height: 660, language: .vietnamese, initialTab: "notification", diagnosticsEnabled: false, logKind: "none"),
            Fixture(name: "EN_TECH_LOG_EMPTY", width: 1120, height: 760, language: .english, initialTab: "logs", diagnosticsEnabled: false, logKind: "empty"),
            Fixture(name: "VI_TECH_LOG_EMPTY", width: 1120, height: 760, language: .vietnamese, initialTab: "logs", diagnosticsEnabled: false, logKind: "empty"),
            Fixture(name: "EN_TECH_LOG_POPULATED", width: 1120, height: 760, language: .english, initialTab: "logs", diagnosticsEnabled: true, logKind: "populated"),
            Fixture(name: "VI_TECH_LOG_POPULATED", width: 1120, height: 760, language: .vietnamese, initialTab: "logs", diagnosticsEnabled: true, logKind: "populated"),
            Fixture(name: "EN_TECH_LOG_MINIMUM", width: 900, height: 660, language: .english, initialTab: "logs", diagnosticsEnabled: true, logKind: "populated"),
            Fixture(name: "VI_TECH_LOG_MINIMUM", width: 900, height: 660, language: .vietnamese, initialTab: "logs", diagnosticsEnabled: true, logKind: "populated"),
            Fixture(name: "EN_READY", width: 1120, height: 760, language: .english, initialTab: "transfer", diagnosticsEnabled: false, logKind: "none"),
            Fixture(name: "VI_READY", width: 1120, height: 760, language: .vietnamese, initialTab: "transfer", diagnosticsEnabled: false, logKind: "none"),
            Fixture(name: "EN_SAFE_TO_EJECT", width: 1120, height: 760, language: .english, initialTab: "transfer", diagnosticsEnabled: false, logKind: "none"),
            Fixture(name: "VI_SAFE_TO_EJECT", width: 1120, height: 760, language: .vietnamese, initialTab: "transfer", diagnosticsEnabled: false, logKind: "none")
        ]

        Task { @MainActor in
            for fixture in fixtures {
                let model = makeModel(rsync: rsync, fixture: fixture)
                for _ in 0..<30 {
                    if model.bundledRsyncInfo.isAvailable { break }
                    try! await Task.sleep(nanoseconds: 100_000_000)
                }
                precondition(model.bundledRsyncInfo.isAvailable, "Bundled rsync 3.4.4 must remain available for truthful presentation")
                window.setContentSize(NSSize(width: fixture.width, height: fixture.height))
                let host = NSHostingView(
                    rootView: ContentView(
                        viewModel: model,
                        initialTab: fixture.initialTab,
                        diagnosticsEnabled: fixture.diagnosticsEnabled
                    )
                    .environment(\.locale, fixture.language.locale)
                )
                window.contentView = host
                try! await Task.sleep(nanoseconds: 450_000_000)
                scrollToTop(host)
                capture(host, to: output.appendingPathComponent("\(fixture.name).png"))
                print("CAPTURE \(fixture.name) content=\(Int(fixture.width))x\(Int(fixture.height)) DarkAqua syntheticFixture=YES transferStarted=NO notifySend=NO updateRequest=NO")
                if fixture.name.hasSuffix("_NOTIFICATION_MINIMUM") {
                    scrollToBottom(host)
                    try! await Task.sleep(nanoseconds: 200_000_000)
                    let scrolledName = "\(fixture.name)_SCROLLED"
                    capture(host, to: output.appendingPathComponent("\(scrolledName).png"))
                    print("SCROLL \(scrolledName) content=\(Int(fixture.width))x\(Int(fixture.height)) notificationSectionsReachable=YES")
                }
            }

            captureSettings(language: .english, output: output)
            captureSettings(language: .vietnamese, output: output)
            try! FileManager.default.removeItem(at: fixtureRoot)
            for suite in defaultsSuites {
                UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
            }
            app.terminate(nil)
        }
        app.run()
    }
}
