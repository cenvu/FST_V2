// FST / CenVu | (+84) 842 841 222

import Darwin
import Dispatch
import Foundation

nonisolated public struct BundledRsyncInfo: Equatable, Sendable {
    public let executableURL: URL?
    public let version: String
    public let diagnostics: [String]

    public var isAvailable: Bool {
        executableURL != nil
    }

    public var badgeText: String {
        guard let executableURL else {
            return diagnostics.first ?? "Bundled rsync unavailable"
        }

        return "\(executableURL.path) v\(version)"
    }

    public static func unavailable(version: String, diagnostics: [String]) -> BundledRsyncInfo {
        BundledRsyncInfo(executableURL: nil, version: version, diagnostics: diagnostics)
    }
}

public actor BundledRsyncService {
    public static let bundledVersion = "3.4.4"
    private static let versionCommandTimeout: TimeInterval = 2.0

    private var cachedInfo: BundledRsyncInfo?
    private let bundledExecutableURL: URL?
    private let versionOutputProvider: @Sendable (URL) throws -> String

    public init() {
        self.bundledExecutableURL = Bundle.main.url(forResource: "rsync", withExtension: nil)
        self.versionOutputProvider = { url in
            try BundledRsyncService.runVersionCommand(executableURL: url)
        }
    }

    init(
        bundledExecutableURL: URL?,
        versionOutputProvider: @escaping @Sendable (URL) throws -> String = { url in
            try BundledRsyncService.runVersionCommand(executableURL: url)
        }
    ) {
        self.bundledExecutableURL = bundledExecutableURL
        self.versionOutputProvider = versionOutputProvider
    }

    public func bundledInfo() -> BundledRsyncInfo {
        if let cachedInfo {
            return cachedInfo
        }

        let info = resolveBundledInfo()
        cachedInfo = info
        return info
    }

    private func resolveBundledInfo() -> BundledRsyncInfo {
        guard let executableURL = bundledExecutableURL else {
            return .unavailable(
                version: "unknown",
                diagnostics: ["Bundled rsync resource missing"]
            )
        }

        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            return .unavailable(
                version: "unknown",
                diagnostics: ["Bundled rsync missing at \(executableURL.path)"]
            )
        }

        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            return .unavailable(
                version: "unknown",
                diagnostics: ["Bundled rsync is not executable at \(executableURL.path)"]
            )
        }

        let versionOutput: String
        do {
            versionOutput = try versionOutputProvider(executableURL)
        } catch {
            return .unavailable(
                version: "unknown",
                diagnostics: diagnostics(for: error, executableURL: executableURL)
            )
        }

        guard let detectedVersion = Self.parseVersion(from: versionOutput) else {
            return .unavailable(
                version: "unknown",
                diagnostics: [
                    "Bundled rsync version output unrecognized",
                    "Expected canonical output starting with: rsync version \(Self.bundledVersion) protocol version ...",
                    "Bundled rsync path: \(executableURL.path)"
                ]
            )
        }

        guard detectedVersion == Self.bundledVersion else {
            return .unavailable(
                version: detectedVersion,
                diagnostics: [
                    "Bundled rsync version mismatch: expected \(Self.bundledVersion), detected \(detectedVersion)",
                    "Bundled rsync path: \(executableURL.path)"
                ]
            )
        }

        return BundledRsyncInfo(
            executableURL: executableURL,
            version: detectedVersion,
            diagnostics: [
                "Bundled rsync path: \(executableURL.path)",
                "Bundled rsync version: \(detectedVersion)"
            ]
        )
    }

    nonisolated static func parseVersion(from versionOutput: String) -> String? {
        guard let firstLine = versionOutput
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty }) else {
            return nil
        }

        let tokens = firstLine
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        guard tokens.count >= 6 else {
            return nil
        }

        guard tokens[0] == "rsync",
              tokens[1] == "version",
              isCanonicalVersionToken(tokens[2]),
              tokens[3] == "protocol",
              tokens[4] == "version",
              tokens[5].allSatisfy(\.isNumber) else {
            return nil
        }

        return tokens[2]
    }

    nonisolated private static func isCanonicalVersionToken(_ token: String) -> Bool {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            return false
        }

        return parts.allSatisfy { part in
            !part.isEmpty && part.allSatisfy(\.isNumber)
        }
    }

    nonisolated static func runVersionCommand(executableURL: URL) throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["--version"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        let terminationSemaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            terminationSemaphore.signal()
        }

        try process.run()
        let timeoutResult = terminationSemaphore.wait(timeout: .now() + Self.versionCommandTimeout)
        guard timeoutResult == .success else {
            process.terminate()
            if terminationSemaphore.wait(timeout: .now() + 1.0) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = terminationSemaphore.wait(timeout: .now() + 1.0)
            }

            throw BundledRsyncValidationError.versionCommandTimedOut(seconds: Self.versionCommandTimeout)
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw BundledRsyncValidationError.versionCommandFailed(
                status: process.terminationStatus,
                stderr: errorOutput
            )
        }

        return output
    }

    private func diagnostics(for error: Error, executableURL: URL) -> [String] {
        if let validationError = error as? BundledRsyncValidationError {
            switch validationError {
            case .versionCommandFailed:
                return [
                    "Bundled rsync version command failed: \(validationError.localizedDescription)",
                    "Bundled rsync path: \(executableURL.path)"
                ]
            case .versionCommandTimedOut:
                return [
                    "Bundled rsync version command timed out: \(validationError.localizedDescription)",
                    "Bundled rsync path: \(executableURL.path)"
                ]
            }
        }

        return [
            "Bundled rsync version command failed: \(error.localizedDescription)",
            "Bundled rsync path: \(executableURL.path)"
        ]
    }
}

nonisolated private enum BundledRsyncValidationError: LocalizedError {
    case versionCommandFailed(status: Int32, stderr: String)
    case versionCommandTimedOut(seconds: TimeInterval)

    var errorDescription: String? {
        switch self {
        case .versionCommandFailed(let status, let stderr):
            let trimmedStderr = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedStderr.isEmpty {
                return "rsync --version exited with status \(status)"
            }

            return "rsync --version exited with status \(status): \(trimmedStderr)"
        case .versionCommandTimedOut(let seconds):
            return String(format: "rsync --version exceeded %.1f seconds", seconds)
        }
    }
}
