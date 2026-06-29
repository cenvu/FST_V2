import SwiftUI

public struct TerminalLogsView: View {
    public let logs: [LogEntry]
    public let autoScroll: Bool
    private let terminalHeight: CGFloat = 170
    
    public init(logs: [LogEntry], autoScroll: Bool) {
        self.logs = logs
        self.autoScroll = autoScroll
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if logs.isEmpty {
                Text("No log entries yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 48)
            } else {
                    TerminalLogTextView(logs: logs, autoScroll: autoScroll)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .padding(.bottom)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct TerminalLogTextView: NSViewRepresentable {
    let logs: [LogEntry]
    let autoScroll: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .overlay
        scrollView.autoresizingMask = [.width, .height]

        let textView = NSTextView()
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.allowsUndo = false
        textView.isRichText = true
        textView.importsGraphics = false
        textView.usesFontPanel = false
        textView.usesFindPanel = true
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.lineBreakMode = .byWordWrapping
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textColor = .textColor
        textView.font = context.coordinator.font

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if logs.count < context.coordinator.renderedCount {
            textView.textStorage?.setAttributedString(NSAttributedString())
            context.coordinator.renderedCount = 0
        }

        guard logs.count > context.coordinator.renderedCount else { return }

        let newLogs = logs[context.coordinator.renderedCount..<logs.count]
        let appendedText = NSMutableAttributedString()
        for log in newLogs {
            appendedText.append(context.coordinator.attributedLine(for: log))
        }

        textView.textStorage?.append(appendedText)
        context.coordinator.renderedCount = logs.count

        if autoScroll {
            let endRange = NSRange(location: textView.string.utf16.count, length: 0)
            textView.scrollRangeToVisible(endRange)
        }
    }

    final class Coordinator {
        var renderedCount = 0
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        private let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter
        }()

        private let paragraphStyle: NSParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.alignment = .left
            style.lineBreakMode = .byWordWrapping
            return style
        }()

        func attributedLine(for log: LogEntry) -> NSAttributedString {
            let line = "[\(timeFormatter.string(from: log.timestamp))] \(log.level) \(log.message)\n"
            return NSAttributedString(
                string: line,
                attributes: [
                    .font: font,
                    .foregroundColor: color(for: log),
                    .paragraphStyle: paragraphStyle
                ]
            )
        }

        private func color(for log: LogEntry) -> NSColor {
            switch log.category {
            case .error, .stderr:
                return .systemRed.withSystemEffect(.disabled)
            case .warning:
                return .systemYellow.withSystemEffect(.disabled)
            case .success:
                return .systemGreen.withSystemEffect(.disabled)
            case .stdout, .file:
                return NSColor.white.withAlphaComponent(0.7)
            case .progress:
                return .systemCyan.withSystemEffect(.disabled)
            case .verify:
                return .systemOrange.withSystemEffect(.disabled)
            case .system:
                return .systemBlue.withSystemEffect(.disabled)
            case .info, .transfer:
                return .systemGray.withSystemEffect(.disabled)
            }
        }
    }
}
