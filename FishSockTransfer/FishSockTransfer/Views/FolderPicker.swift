import AppKit

@MainActor
enum FolderPicker {
    static func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false

        return panel.runModal() == .OK ? panel.url : nil
    }
}
