import AppKit
import ApplicationServices
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

private struct CaptureAppLocaleRoot: View {
    let viewModel: TransferViewModel
    let initialTab: String
    let diagnosticsEnabled: Bool
    let showCopyToast: Bool
    @ObservedObject var languagePreference: AppLanguagePreference

    var body: some View {
        ContentView(
            viewModel: viewModel,
            initialTab: initialTab,
            diagnosticsEnabled: diagnosticsEnabled,
            showCopyToast: showCopyToast
        )
        .environmentObject(languagePreference)
        .environment(\.locale, languagePreference.language.locale)
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
        host.needsDisplay = true
        host.window?.contentView?.needsDisplay = true
        host.window?.displayIfNeeded()
        host.displayIfNeeded()
        let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try! bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }

    @MainActor
    private static func captureLatestPopover(from host: NSView, to url: URL) -> Bool {
        guard let popover = host.window?.childWindows?.last(where: \.isVisible),
              let content = popover.contentView else { return false }
        capture(content, to: url)
        return true
    }

    @MainActor
    private static func pressAccessibilityElement(label: String) -> Bool {
        let application = AXUIElementCreateApplication(getpid())
        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(application, "AXWindows" as CFString, &windowValue) == .success,
              let windows = windowValue as? [AXUIElement] else {
            print("AX_PRESS label=\(label) result=WINDOWS_UNAVAILABLE")
            return false
        }

        var pending = windows
        while let element = pending.popLast() {
            func attribute(_ name: String) -> (AXError, CFTypeRef?) {
                var value: CFTypeRef?
                let status = AXUIElementCopyAttributeValue(element, name as CFString, &value)
                return (status, value)
            }
            let (_, titleValue) = attribute("AXTitle")
            let (_, labelValue) = attribute("AXLabel")
            let (_, valueValue) = attribute("AXValue")
            let (_, descriptionValue) = attribute("AXDescription")
            let (_, helpValue) = attribute("AXHelp")
            let (_, identifierValue) = attribute("AXIdentifier")
            if (titleValue as? String == label)
                || (labelValue as? String == label)
                || (valueValue as? String == label)
                || (descriptionValue as? String == label)
                || (helpValue as? String == label)
                || (identifierValue as? String == label) {
                let status = AXUIElementPerformAction(element, "AXPress" as CFString)
                print("AX_PRESS label=\(label) result=\(status.rawValue)")
                return status == .success
            }

            var childrenValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, "AXChildren" as CFString, &childrenValue) == .success,
               let children = childrenValue as? [AXUIElement] {
                pending.append(contentsOf: children)
            }
        }

        print("AX_PRESS label=\(label) result=NOT_FOUND")
        return false
    }

    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let prefix = CommandLine.arguments[1]
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let rsync = URL(fileURLWithPath: CommandLine.arguments[3])
        let locale = Locale(identifier: CommandLine.arguments[4])
        let languageDefaultsDomain = "FSTTransferLanguageCapture-\(UUID().uuidString)"
        let languageDefaults = UserDefaults(suiteName: languageDefaultsDomain)!
        let languagePreference = AppLanguagePreference(userDefaults: languageDefaults)
        languagePreference.select(prefix == "VI" ? .vietnamese : .english)
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
            Fixture(name: "TRANSFER_READY_MINIMUM", width: 900, height: 660, tab: "transfer", state: .ready, errorMessage: nil, populatedLogs: false, diagnostics: false, captureBottom: false, showCopyToast: false),
            Fixture(name: "TRANSFER_VERIFYING", width: 1120, height: 760, tab: "transfer", state: .verifying, errorMessage: nil, populatedLogs: false, diagnostics: false, captureBottom: false, showCopyToast: false)
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
                    rootView: CaptureAppLocaleRoot(
                        viewModel: model,
                        initialTab: fixture.tab,
                        diagnosticsEnabled: fixture.diagnostics,
                        showCopyToast: fixture.showCopyToast,
                        languagePreference: languagePreference
                    )
                )
                window.contentView = host
                try! await Task.sleep(nanoseconds: 450_000_000)
                scrollToTop(host)
                capture(host, to: output.appendingPathComponent("\(prefix)_\(fixture.name).png"))
                print("CAPTURE \(prefix)_\(fixture.name) content=\(Int(fixture.width))x\(Int(fixture.height)) DarkAqua syntheticFixture=YES transferStarted=NO notifySend=NO updateRequest=NO")

                if fixture.name == "TRANSFER_READY" {
                    let bandwidthTitle = prefix == "VI" ? "Giới hạn tốc độ" : "Bandwidth Limit"
                    let unlimitedLabel = TransferPresentationLocalization.text("Unlimited", locale: locale)
                    let openedBandwidth = pressAccessibilityElement(label: bandwidthTitle)
                        || pressAccessibilityElement(label: unlimitedLabel)
                    if openedBandwidth {
                        try! await Task.sleep(nanoseconds: 250_000_000)
                        let capturedMenu = captureLatestPopover(
                            from: host,
                            to: output.appendingPathComponent("\(prefix)_BANDWIDTH_MENU.png")
                        )
                        precondition(capturedMenu, "Bandwidth custom popover should be visible in the capture fixture")
                        let selectedBandwidth = pressAccessibilityElement(label: "50 MB/s")
                        precondition(selectedBandwidth && model.bandwidthLimit == 50, "Bandwidth menu must select the bound MB/s value")
                    }
                    let verificationTitle = prefix == "VI" ? "Chế độ xác minh" : "Verification Mode"
                    let selectedModeLabel = TransferPresentationLocalization.text(
                        VerificationMode.random33.selectionLabel,
                        locale: locale
                    )
                    let openedVerification = pressAccessibilityElement(label: verificationTitle)
                        || pressAccessibilityElement(label: selectedModeLabel)
                    if openedVerification {
                        try! await Task.sleep(nanoseconds: 250_000_000)
                        let capturedMenu = captureLatestPopover(
                            from: host,
                            to: output.appendingPathComponent("\(prefix)_VERIFICATION_MENU.png")
                        )
                        precondition(capturedMenu, "Verification custom popover should be visible in the capture fixture")
                        let fullLabel = TransferPresentationLocalization.text(
                            VerificationMode.full.selectionLabel,
                            locale: locale
                        )
                        let selectedVerification = pressAccessibilityElement(label: fullLabel)
                        precondition(selectedVerification && model.verificationMode == .full, "Verification menu must select the bound mode")
                    }

                    let originalLanguage = languagePreference.language
                    let toggleLabel = originalLanguage == .english ? "Application Language" : "Ngôn ngữ ứng dụng"
                    let nextLanguage: AppLanguage = originalLanguage == .english ? .vietnamese : .english
                    let didSwitchLanguage = pressAccessibilityElement(label: toggleLabel)
                    precondition(didSwitchLanguage && languagePreference.language == nextLanguage, "Header flag should persistently toggle the app language")
                    try! await Task.sleep(nanoseconds: 350_000_000)
                    capture(
                        host,
                        to: output.appendingPathComponent("\(prefix)_FLAG_TO_\(nextLanguage.rawValue.uppercased()).png")
                    )

                    let reverseToggleLabel = nextLanguage == .english ? "Application Language" : "Ngôn ngữ ứng dụng"
                    let didSwitchBack = pressAccessibilityElement(label: reverseToggleLabel)
                    precondition(didSwitchBack && languagePreference.language == originalLanguage, "Header flag should switch back to the original app language")
                    try! await Task.sleep(nanoseconds: 350_000_000)
                    capture(
                        host,
                        to: output.appendingPathComponent("\(prefix)_FLAG_BACK_TO_\(originalLanguage.rawValue.uppercased()).png")
                    )
                }

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
            languageDefaults.removePersistentDomain(forName: languageDefaultsDomain)
            app.terminate(nil)
        }
        app.run()
    }
}
