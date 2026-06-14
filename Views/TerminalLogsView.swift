import SwiftUI

public struct TerminalLogsView: View {
    public let logs: [String]
    
    public init(logs: [String]) {
        self.logs = logs
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "greaterthan.square")
                Text("REAL-TIME RSYNC TERMINAL LOGS")
                    .font(.caption)
                    .bold()
            }
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.top)
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(logs.indices, id: \.self) { index in
                            let log = logs[index]
                            Text(log)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(colorForLog(log))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                    .padding()
                }
                .onChange(of: logs.count) { _ in
                    if !logs.isEmpty {
                        withAnimation {
                            proxy.scrollTo(logs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .padding([.horizontal, .bottom])
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func colorForLog(_ log: String) -> Color {
        let upperLog = log.uppercased()
        if upperLog.contains("[ERROR]") { return .red }
        if upperLog.contains("[WARNING]") { return .yellow }
        if upperLog.contains("[SYSTEM]") || upperLog.contains("[STATS]") { return .blue }
        if upperLog.contains("[VERIFY]") { return .orange }
        if upperLog.contains("[TRANSFER]") { return .green }
        return .gray
    }
}
