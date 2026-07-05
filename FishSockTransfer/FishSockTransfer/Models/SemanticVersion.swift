// FST / CenVu | (+84) 842 841 222

import Foundation

nonisolated public struct SemanticVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withoutPrefix: Substring
        if let first = trimmed.first, first == "v" || first == "V" {
            withoutPrefix = trimmed.dropFirst()[...]
        } else {
            withoutPrefix = trimmed[...]
        }

        let core = withoutPrefix.split(maxSplits: 1, whereSeparator: { $0 == "-" || $0 == "+" }).first ?? ""
        let components = core.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...3).contains(components.count) else { return nil }

        var numbers: [Int] = []
        for component in components {
            guard !component.isEmpty, component.allSatisfy({ $0.isNumber }), let number = Int(component) else {
                return nil
            }
            numbers.append(number)
        }

        while numbers.count < 3 {
            numbers.append(0)
        }

        self.major = numbers[0]
        self.minor = numbers[1]
        self.patch = numbers[2]
    }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}
