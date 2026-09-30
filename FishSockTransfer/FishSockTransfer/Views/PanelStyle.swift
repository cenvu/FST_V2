// FST / CenVu | (+84) 842 841 222

import SwiftUI

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
