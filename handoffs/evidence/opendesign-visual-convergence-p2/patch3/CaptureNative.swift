import AppKit
import SwiftUI

nonisolated final class FixtureTokenStore: TelegramTokenStore {
    // Deliberately non-secret; only SecureField may display its masked state.
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}

nonisolated final class NoSendService: NotificationService, @unchecked Sendable {
    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        fatalError("Screenshot fixture must never attempt notification delivery")
    }
}

@main
struct CaptureNative {
    @MainActor static func scrollViews(in view: NSView) -> [NSScrollView] {
        (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap { scrollViews(in: $0) }
    }

    @MainActor static func capture(_ host: NSView, to url: URL) {
        host.layoutSubtreeIfNeeded()
        let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try! bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }

    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let prefix = CommandLine.arguments[1]
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let rsync = URL(fileURLWithPath: CommandLine.arguments[3])
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1120, height: 760),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "FishSock Transfer"
        window.appearance = NSAppearance(named: .darkAqua)
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)

        Task { @MainActor in
            for (suffix, width, height, configured) in [
                ("NOTIFICATION", 1120, 760, false),
                ("NOTIFICATION_CONFIGURED", 1120, 760, true),
                ("NOTIFICATION_MINIMUM", 900, 660, false),
                ("NOTIFICATION_LONG_ERROR", 900, 660, true)
            ] {
                let domain = "FSTPatch3Capture-\(UUID())"
                let defaults = UserDefaults(suiteName: domain)!
                let model = TransferViewModel(
                    bundledRsyncService: BundledRsyncService(bundledExecutableURL: rsync),
                    notificationCoordinator: NotificationCoordinator(service: NoSendService()),
                    notificationSettingsStore: NotificationSettingsStore(userDefaults: defaults, tokenStore: FixtureTokenStore())
                )
                if configured {
                    model.notificationSettings.isTelegramEnabled = true
                    model.notificationSettings.chatID = "SYNTHETIC_CHAT_ID"
                    model.telegramBotToken = String(repeating: "x", count: 16)
                    model.notificationSettings.heartbeatInterval = .thirtyMinutes
                    model.notificationSettings.messageDetail = .compact
                    model.persistNotificationSettings()
                }
                if suffix == "NOTIFICATION_LONG_ERROR" {
                    model.notificationStatus = NotificationRuntimeStatus(
                        telegramStatus: "Enabled", connectionStatus: .error,
                        lastMessageStatus: "Fixture: delivery unavailable; source media remains protected.",
                        lastErrorSummary: "Synthetic capture error: Cannot reach Telegram API host. Check internet/DNS/VPN/firewall. Notification is optional and best-effort; transfer, verification, report and SAFE TO EJECT results are unchanged."
                    )
                }
                window.setContentSize(NSSize(width: width, height: height))
                let host = NSHostingView(rootView: ContentView(viewModel: model))
                window.contentView = host
                try! await Task.sleep(nanoseconds: 400_000_000)
                host.layoutSubtreeIfNeeded()
                let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try! bitmap.representation(using: .png, properties: [:])!
                    .write(to: output.appendingPathComponent("\(prefix)_\(suffix).png"))
                print("CAPTURE \(prefix)_\(suffix) content=\(width)x\(height) pixels=\(bitmap.pixelsWide)x\(bitmap.pixelsHigh) DarkAqua NO_SEND")
                if suffix == "NOTIFICATION_MINIMUM" || suffix == "NOTIFICATION" || suffix == "NOTIFICATION_LONG_ERROR" {
                    let scroll = scrollViews(in: host).first!
                    let document = scroll.documentView!
                    let extent = max(0, document.bounds.height - scroll.contentView.bounds.height)
                    scroll.contentView.scroll(to: NSPoint(x: 0, y: document.isFlipped ? extent : 0))
                    scroll.reflectScrolledClipView(scroll.contentView)
                    try! await Task.sleep(nanoseconds: 200_000_000)
                    capture(host, to: output.appendingPathComponent("\(prefix)_\(suffix)_SCROLLED.png"))
                    print("SCROLL \(prefix)_\(suffix) documentHeight=\(document.bounds.height) viewportHeight=\(scroll.contentView.bounds.height) extent=\(extent)")
                }
                defaults.removePersistentDomain(forName: domain)
            }
            app.terminate(nil)
        }
        app.run()
    }
}
