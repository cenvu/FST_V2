import AppKit
import SwiftUI

nonisolated final class InertTokenStore: TelegramTokenStore {
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}
@main struct NativeCapacityQA {
    @MainActor static func main() throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        var windows: [NSWindow] = []
        for (index, scenario) in [("apfs", "light"), ("exfat", "light"), ("apfs", "dark"), ("exfat", "dark")].enumerated() {
            let (fs, theme) = scenario
            let vm = TransferViewModel(bundledRsyncService: BundledRsyncService(bundledExecutableURL: nil),
                notificationSettingsStore: NotificationSettingsStore(userDefaults: UserDefaults(suiteName: "FSTCapacityNativeQA")!, tokenStore: InertTokenStore()))
            let source = URL(fileURLWithPath: "/tmp/fst-native-qa-source"), dest = URL(fileURLWithPath: "/tmp/fst-native-qa-destination")
            vm.sourceURL = source; vm.destinationURL = dest
            vm.sourceMetadata = .init(folderName: "Fixture", fullPath: source.path, totalSizeBytes: 8192, fileCount: 8192, folderCount: 0)
            let snapshot = DestinationStorageMetadata(freeSpaceBytes: 100_663_296, filesystem: fs, isWritable: true,
                filesystemIdentity: fs, allocationUnit: fs == "apfs" ? 4096 : 512)
            vm.destinationMetadata = snapshot
            vm.capacityAssessment = try .make(source: source, destination: dest, logicalPayloadBytes: 8192,
                roundedPayloadBytes: fs == "apfs" ? 33_554_432 : nil, snapshot: snapshot)
            let view = StorageAnalysisView(viewModel: vm).padding(20)
                .frame(width: 600, height: 300).background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, theme == "light" ? .light : .dark)
            let host = NSHostingView(rootView: view)
            let window = NSWindow(contentRect: NSRect(x: 40 + index * 35, y: 100 + index * 40, width: 600, height: 300),
                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "FST Capacity QA \(fs) \(theme)"
            window.appearance = NSAppearance(named: theme == "light" ? .aqua : .darkAqua)
            window.contentView = host
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
        app.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            for (index, window) in windows.enumerated() {
                guard let host = window.contentView, let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { continue }
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try? bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "/tmp/fst-capacity-native-\(index).png"))
            }
            app.terminate(nil)
        }
        app.run()
    }
}
