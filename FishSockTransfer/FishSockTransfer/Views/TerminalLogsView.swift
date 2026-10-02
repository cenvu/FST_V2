// FST / CenVu | (+84) 842 841 222

import SwiftUI

public struct TerminalLogsView: View {
    public let logs: [LogEntry]
    public let autoScroll: Bool

    public init(logs: [LogEntry], autoScroll: Bool) {
        self.logs = logs
        self.autoScroll = autoScroll
    }

    public var body: some View {
        ZStack {
            if logs.isEmpty {
                VStack(spacing: 6) {
                    Text("No log entries yet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FSTPalette.text)
                    Text("Select source and destination, then start a job.")
                        .font(.system(size: 14))
                        .foregroundStyle(FSTPalette.muted)
                }
                .multilineTextAlignment(.center)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TerminalLogTextView(logs: logs, autoScroll: autoScroll)
                    .padding(16)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 360, maxHeight: .infinity, alignment: .topLeading)
        .background(FSTPalette.inset)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(FSTPalette.line, lineWidth: 1)
        }
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
        textView.textContainerInset = .zero
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
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

        private let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter
        }()

        private let paragraphStyle: NSParagraphStyle = {
            let style = NSMutableParagraphStyle()
            style.alignment = .left
            style.lineBreakMode = .byWordWrapping
            style.lineSpacing = 3
            style.paragraphSpacing = 5
            return style
        }()

        func attributedLine(for log: LogEntry) -> NSAttributedString {
            let categoryColor = color(for: log)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
            let line = NSMutableAttributedString()
            line.append(NSAttributedString(
                string: "[\(timeFormatter.string(from: log.timestamp))] ",
                attributes: attributes.merging([.foregroundColor: NSColor.secondaryLabelColor]) { _, new in new }
            ))
            line.append(NSAttributedString(
                string: "\(log.level) ",
                attributes: attributes.merging([.foregroundColor: categoryColor]) { _, new in new }
            ))
            line.append(NSAttributedString(
                string: "\(log.message)\n",
                attributes: attributes.merging([.foregroundColor: categoryColor]) { _, new in new }
            ))
            return line
        }

        private func color(for log: LogEntry) -> NSColor {
            switch log.category {
            case .error, .stderr:
                return .systemRed
            case .warning:
                return .systemYellow
            case .success:
                return .systemGreen
            case .stdout, .file:
                return NSColor.textColor.withAlphaComponent(0.82)
            case .progress:
                return .systemCyan
            case .verify:
                return .systemOrange
            case .system:
                return .systemBlue
            case .info, .transfer:
                return .secondaryLabelColor
            }
        }
    }
}
