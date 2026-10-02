import AppKit
import SwiftUI

nonisolated final class Patch4FixtureTokenStore: TelegramTokenStore {
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}

nonisolated final class Patch4NoSendService: NotificationService, @unchecked Sendable {
    func sendMessage(_ message: String, configuration: TelegramNotificationConfiguration) async throws {
        fatalError("Patch 4 screenshot fixture must never send a notification")
    }
}

@main
struct CaptureNative {
    private struct CaptureState {
        let name: String
        let width: CGFloat
        let height: CGFloat
        let populated: Bool
        let diagnostics: Bool
    }

    @MainActor
    private static func makeModel(rsync: URL, populated: Bool) -> TransferViewModel {
        let defaultsName = "FSTPatch4Capture-\(UUID())"
        let defaults = UserDefaults(suiteName: defaultsName)!
        let settings = NotificationSettingsStore(
            userDefaults: defaults,
            tokenStore: Patch4FixtureTokenStore()
        )
        let model = TransferViewModel(
            bundledRsyncService: BundledRsyncService(bundledExecutableURL: rsync),
            notificationCoordinator: NotificationCoordinator(service: Patch4NoSendService()),
            notificationSettingsStore: settings
        )

        if populated {
            let calendar = Calendar(identifier: .gregorian)
            let anchor = calendar.date(from: DateComponents(year: 2026, month: 10, day: 2, hour: 9, minute: 14))!
            model.logs = [
                LogEntry(timestamp: anchor, category: .system, message: "Technical log view opened."),
                LogEntry(timestamp: anchor.addingTimeInterval(4), category: .info, message: "Source volume mounted read-only."),
                LogEntry(timestamp: anchor.addingTimeInterval(8), category: .transfer, message: "Destination folder is available."),
                LogEntry(timestamp: anchor.addingTimeInterval(12), category: .stdout, message: "sending incremental file list"),
                LogEntry(timestamp: anchor.addingTimeInterval(16), category: .file, message: "A001_C003_1001AB.mov"),
                LogEntry(timestamp: anchor.addingTimeInterval(20), category: .progress, message: "Copy progress: 68% · 184.2 MB/s"),
                LogEntry(timestamp: anchor.addingTimeInterval(24), category: .verify, message: "Verification comparison is ready."),
                LogEntry(timestamp: anchor.addingTimeInterval(28), category: .warning, message: "A synthetic warning remains visible to the operator."),
                LogEntry(timestamp: anchor.addingTimeInterval(32), category: .success, message: "Synthetic copy record completed."),
                LogEntry(timestamp: anchor.addingTimeInterval(36), category: .stderr, message: "Synthetic stderr entry for category contrast."),
                LogEntry(timestamp: anchor.addingTimeInterval(40), category: .error, message: "Synthetic error entry; no transfer was started."),
                LogEntry(timestamp: anchor.addingTimeInterval(44), category: .info, message: "A long synthetic operator message demonstrates natural wrapping within the available log feed width without changing the actual production serialization or hiding any text from selection."),
                LogEntry(timestamp: anchor.addingTimeInterval(48), category: .info, message: "DIAG [RSYNC RAW] synthetic diagnostic entry is hidden by the production filter."),
                LogEntry(timestamp: anchor.addingTimeInterval(52), category: .info, message: "[VERIFY DIAG] synthetic comparison detail is hidden by the production filter.")
            ]
        }

        return model
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
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 760),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FishSock Transfer"
        window.appearance = NSAppearance(named: .darkAqua)
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)

        Task { @MainActor in
            let states = [
                CaptureState(name: "TECH_LOG_EMPTY", width: 1120, height: 760, populated: false, diagnostics: false),
                CaptureState(name: "TECH_LOG_POPULATED", width: 1120, height: 760, populated: true, diagnostics: false),
                CaptureState(name: "TECH_LOG_DIAGNOSTICS", width: 1120, height: 760, populated: true, diagnostics: true),
                CaptureState(name: "TECH_LOG_MINIMUM", width: 900, height: 660, populated: false, diagnostics: false)
            ]

            for state in states {
                let model = makeModel(rsync: rsync, populated: state.populated)
                window.setContentSize(NSSize(width: state.width, height: state.height))
                let host = NSHostingView(rootView: ContentView(viewModel: model, diagnosticsEnabled: state.diagnostics))
                window.contentView = host
                try! await Task.sleep(nanoseconds: 400_000_000)
                capture(host, to: output.appendingPathComponent("\(prefix)_\(state.name).png"))
                print("CAPTURE \(prefix)_\(state.name) content=\(Int(state.width))x\(Int(state.height)) DarkAqua syntheticLogs=\(state.populated) diagnostics=\(state.diagnostics) notificationSend=NONE transfer=NONE")
            }

            app.terminate(nil)
        }
        app.run()
    }
}
