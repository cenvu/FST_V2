import Foundation

public struct ProgressData: Equatable {
    public let progress: Double
    public let speedMBps: Double
    public let eta: TimeInterval
}

public final class ProgressParser {
    public init() {}
    
    public func parse(line: String) -> ProgressData? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("%") else { return nil }
        
        let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard components.count >= 4 else { return nil }
        
        let progressString = components[1].replacingOccurrences(of: "%", with: "")
        guard let progress = Double(progressString) else { return nil }
        
        let speedString = components[2]
        let speedMBps = parseSpeed(speedString)
        
        let eta = parseETA(components[3])
        
        return ProgressData(progress: progress, speedMBps: speedMBps, eta: eta)
    }
    
    private func parseSpeed(_ string: String) -> Double {
        if string.hasSuffix("MB/s") {
            return Double(string.dropLast(4)) ?? 0
        } else if string.hasSuffix("kB/s") {
            return (Double(string.dropLast(4)) ?? 0) / 1024.0
        } else if string.hasSuffix("GB/s") {
            return (Double(string.dropLast(4)) ?? 0) * 1024.0
        } else if string.hasSuffix("B/s") {
            return (Double(string.dropLast(3)) ?? 0) / (1048576.0)
        }
        return 0
    }
    
    private func parseETA(_ string: String) -> TimeInterval {
        let parts = string.split(separator: ":").compactMap { Double($0) }
        if parts.count == 3 {
            return (parts[0] * 3600) + (parts[1] * 60) + parts[2]
        } else if parts.count == 2 {
            return (parts[0] * 60) + parts[1]
        }
        return 0
    }
}
