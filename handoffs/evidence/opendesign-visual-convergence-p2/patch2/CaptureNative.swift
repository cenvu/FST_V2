import AppKit
import SwiftUI

nonisolated final class EmptyTokenStore: TelegramTokenStore {
    func loadToken() throws -> String { "" }
    func saveToken(_ token: String) throws {}
    func deleteToken() throws {}
}

@main
struct CaptureNative {
    @MainActor
    static func makeViewModel(
        state: TransferState,
        source: URL,
        destination: URL,
        rsyncExecutable: URL
    ) -> TransferViewModel {
        let defaults = UserDefaults(suiteName: "FSTPatch2Capture-\(UUID())")!
        let model = TransferViewModel(
            bundledRsyncService: BundledRsyncService(
                bundledExecutableURL: rsyncExecutable
            ),
            notificationSettingsStore: NotificationSettingsStore(
                userDefaults: defaults,
                tokenStore: EmptyTokenStore()
            )
        )
        let bytes: Int64 = 24_000_000_000
        model.sourceURL = source
        model.destinationURL = destination
        model.sourceMetadata = SourceStorageMetadata(
            folderName: source.lastPathComponent,
            fullPath: source.path,
            totalSizeBytes: bytes,
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
            logicalPayloadBytes: bytes,
            roundedPayloadBytes: 24_000_921_600,
            snapshot: model.destinationMetadata!
        )
        model.applyTransferState(state)

        switch state {
        case .ready:
            break
        case .copying:
            model.copyRuntimeSnapshot = CopyRuntimeSnapshot(
                elapsedSeconds: 72,
                currentItem: "CAM_A/CLIP_0042.mov",
                copiedBytes: 10_800_000_000,
                totalBytes: bytes,
                copiedFiles: 108,
                totalFiles: 240,
                progressFraction: 0.45,
                currentSpeedBytesPerSecond: 150_000_000,
                averageSpeedBytesPerSecond: 150_000_000,
                etaSeconds: 88,
                signalSource: .rsync,
                lastObservedAt: Date(),
                activityState: .copying
            )
            model.progress = 45
            model.speed = 150
            model.eta = 88
            model.currentFile = "CAM_A/CLIP_0042.mov"
        case .verifying, .safeToFormat:
            model.copyRuntimeSnapshot = CopyRuntimeSnapshot(
                elapsedSeconds: 160,
                currentItem: "CAM_A/CLIP_0042.mov",
                copiedBytes: bytes,
                totalBytes: bytes,
                copiedFiles: 240,
                totalFiles: 240,
                progressFraction: 1,
                currentSpeedBytesPerSecond: nil,
                averageSpeedBytesPerSecond: 150_000_000,
                etaSeconds: nil,
                signalSource: .rsync,
                lastObservedAt: Date(),
                activityState: .complete
            )
            model.progress = state == .verifying ? 0.62 : 1
            model.speed = 0
            model.eta = 0
            model.currentFile = ""
            // Existing native capture fixture value; this is layout evidence only.
            model.setVerifyElapsedSecondsForTesting(38)
        case .error:
            // Existing operator wording used by the canonical report tests.
            model.errorMessage = "TRANSFER ERROR: rsync failed."
            model.copyRuntimeSnapshot = nil
            model.progress = 0
            model.speed = 0
            model.eta = 0
            model.currentFile = ""
            model.setVerifyElapsedSecondsForTesting(0)
        case .validating, .copyComplete, .cancelled:
            fatalError("This capture harness only supports its five named states.")
        }
        return model
    }

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let prefix = CommandLine.arguments[1]
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let width = CommandLine.arguments.count > 3 ? Double(CommandLine.arguments[3])! : 1120
        let height = CommandLine.arguments.count > 4 ? Double(CommandLine.arguments[4])! : 760
        let appearance = CommandLine.arguments.count > 5 ? CommandLine.arguments[5] : "dark"
        let rsyncExecutable = URL(fileURLWithPath: CommandLine.arguments[6])
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("FST-Visual-P2-\(UUID())")
        try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("CAM_A_CARD_001")
        let destination = root.appendingPathComponent("OFFLOAD")
        for url in [source, destination] {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "FishSock Transfer"
        window.appearance = NSAppearance(named: appearance == "light" ? .aqua : .darkAqua)
        window.center()
        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)

        Task { @MainActor in
            try! await Task.sleep(nanoseconds: 300_000_000)
            let states: [(String, TransferState)] = [
                ("READY", .ready),
                ("COPYING", .copying),
                ("VERIFYING", .verifying),
                ("SAFE_TO_EJECT", .safeToFormat),
                ("ERROR", .error)
            ]
            for (name, state) in states {
                let model = makeViewModel(state: state, source: source, destination: destination, rsyncExecutable: rsyncExecutable)
                for _ in 0..<30 {
                    if model.bundledRsyncInfo.isAvailable { break }
                    try! await Task.sleep(nanoseconds: 100_000_000)
                }
                precondition(model.bundledRsyncInfo.isAvailable, "Bundled rsync 3.4.4 must resolve for the READY fixture.")
                let host = NSHostingView(rootView: ContentView(viewModel: model))
                window.contentView = host
                try! await Task.sleep(nanoseconds: 250_000_000)
                host.layoutSubtreeIfNeeded()
                let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
                host.cacheDisplay(in: host.bounds, to: bitmap)
                try! bitmap.representation(using: .png, properties: [:])!
                    .write(to: output.appendingPathComponent("\(prefix)_\(name).png"))
                print("CAPTURE \(prefix)_\(name) content=\(width)x\(height) pixels=\(bitmap.pixelsWide)x\(bitmap.pixelsHigh) appearance=\(appearance)")
            }
            try! FileManager.default.removeItem(at: root)
            app.terminate(nil)
        }
        app.run()
    }
}
