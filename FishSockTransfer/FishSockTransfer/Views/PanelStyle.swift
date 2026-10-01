// FST / CenVu | (+84) 842 841 222

import SwiftUI

/// OpenDesign operational colors adapt to the window's native appearance.
nonisolated public enum FSTPalette {
    public static let background = adaptive(0x161a1f, light: .windowBackgroundColor)
    public static let surface = adaptive(0x20252c, light: .controlBackgroundColor)
    public static let inset = adaptive(0x11161c, light: .textBackgroundColor)
    public static let raised = adaptive(0x2a3038, light: .selectedControlColor)
    public static let line = adaptive(0x343c47, light: .separatorColor)
    public static let text = adaptive(0xedf1f6, light: .labelColor)
    public static let muted = adaptive(0xa7b1bd, light: .secondaryLabelColor)
    public static let active = adaptive(0x7ab6ff, light: NSColor(srgbRed: 0.12, green: 0.34, blue: 0.68, alpha: 1))
    public static let verified = adaptive(0x70d8a0, light: NSColor(srgbRed: 0.12, green: 0.42, blue: 0.25, alpha: 1))
    public static let warning = adaptive(0xffd080, light: NSColor(srgbRed: 0.62, green: 0.30, blue: 0.05, alpha: 1))
    public static let error = adaptive(0xff9094, light: NSColor(srgbRed: 0.70, green: 0.14, blue: 0.18, alpha: 1))

    private static func adaptive(_ rgb: UInt32, light: NSColor) -> Color {
        let dark = NSColor(srgbRed: Double((rgb >> 16) & 255) / 255,
                           green: Double((rgb >> 8) & 255) / 255,
                           blue: Double(rgb & 255) / 255, alpha: 1)
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

public extension View {
    /// Flat operational grouping; standardPanel remains available to other tabs.
    func operationalPanel(tint: Color? = nil) -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(tint.map { $0.opacity(0.08) } ?? FSTPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// A thin SwiftUI track keeps the phase fraction legible without motion.
struct FSTThinProgressStyle: ProgressViewStyle {
    var tint: Color

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(FSTPalette.line)
                Capsule().fill(tint)
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0))
            }
        }
        .frame(height: 4)
    }
}

public struct StandardPanelModifier: ViewModifier {
    var strokeColor: Color
    var strokeWidth: CGFloat
    var strokeDash: [CGFloat]
    
    public init(strokeColor: Color = Color.secondary.opacity(0.15), strokeWidth: CGFloat = 1, strokeDash: [CGFloat] = []) {
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.strokeDash = strokeDash
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: strokeWidth, dash: strokeDash))
            )
    }
}

public extension View {
    func standardPanel(
        strokeColor: Color = Color.secondary.opacity(0.15),
        strokeWidth: CGFloat = 1,
        strokeDash: [CGFloat] = []
    ) -> some View {
        modifier(StandardPanelModifier(strokeColor: strokeColor, strokeWidth: strokeWidth, strokeDash: strokeDash))
    }
}
