import Foundation

nonisolated public struct ProgressData: Equatable, Sendable {
    public let progress: Double
    public let speedMBps: Double
    public let eta: TimeInterval
}

nonisolated public final class ProgressParser: Sendable {
    public static let activeCopyMaximumProgress = 99.0
    public static let completedCopyProgress = 100.0

    public init() {}

    public static func activeCopyProgress(_ progress: Double) -> Double {
        guard progress.isFinite else { return 0.0 }
        return min(max(progress, 0.0), activeCopyMaximumProgress)
    }
    
    public func parse(line: String) -> ProgressData? {
        let records = line.components(separatedBy: CharacterSet(charactersIn: "\r\n"))
        for record in records.reversed() {
            if let progressData = parseRecord(record) {
                return progressData
            }
        }

        return nil
    }

    private func parseRecord(_ line: String) -> ProgressData? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("%") else { return nil }

        let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard components.count >= 4 else { return nil }

        guard isByteCount(components[0]) else { return nil }

        let progressToken = components[1]
        guard progressToken.hasSuffix("%") else { return nil }

        let progressString = progressToken.dropLast()
        guard !progressString.contains("%"),
              let progress = Double(progressString),
              (0.0...100.0).contains(progress) else {
            return nil
        }

        guard let speedMBps = parseSpeed(components[2]),
              let eta = parseETA(components[3]) else {
            return nil
        }

        return ProgressData(progress: progress, speedMBps: speedMBps, eta: eta)
    }
    
    private func parseSpeed(_ string: String) -> Double? {
        if string.hasSuffix("MB/s") {
            return Double(string.dropLast(4))
        } else if string.hasSuffix("kB/s") || string.hasSuffix("KB/s") {
            guard let value = Double(string.dropLast(4)) else { return nil }
            return value / 1024.0
        } else if string.hasSuffix("GB/s") {
            guard let value = Double(string.dropLast(4)) else { return nil }
            return value * 1024.0
        } else if string.hasSuffix("B/s") {
            guard let value = Double(string.dropLast(3)) else { return nil }
            return value / 1048576.0
        }

        return nil
    }
    
    private func parseETA(_ string: String) -> TimeInterval? {
        let rawParts = string.split(separator: ":")
        let parts = rawParts.compactMap { Double($0) }
        guard parts.count == rawParts.count else { return nil }

        if parts.count == 3 {
            return (parts[0] * 3600) + (parts[1] * 60) + parts[2]
        } else if parts.count == 2 {
            return (parts[0] * 60) + parts[1]
        }

        return nil
    }

    private func isByteCount(_ string: String) -> Bool {
        if isCommaSeparatedInteger(string) {
            return true
        }

        guard let unit = string.last, "KMGT".contains(unit) else {
            return false
        }

        return isPlainNumber(String(string.dropLast()))
    }

    private func isCommaSeparatedInteger(_ string: String) -> Bool {
        let groups = string.split(separator: ",", omittingEmptySubsequences: false)
        guard let firstGroup = groups.first,
              !firstGroup.isEmpty,
              firstGroup.allSatisfy(\.isNumber) else {
            return false
        }

        if groups.count == 1 {
            return true
        }

        guard (1...3).contains(firstGroup.count) else {
            return false
        }

        return groups.dropFirst().allSatisfy { group in
            group.count == 3 && group.allSatisfy(\.isNumber)
        }
    }

    private func isPlainNumber(_ string: String) -> Bool {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)

        switch parts.count {
        case 1:
            return !parts[0].isEmpty && parts[0].allSatisfy(\.isNumber)
        case 2:
            return !parts[0].isEmpty
                && !parts[1].isEmpty
                && parts[0].allSatisfy(\.isNumber)
                && parts[1].allSatisfy(\.isNumber)
        default:
            return false
        }
    }
}
