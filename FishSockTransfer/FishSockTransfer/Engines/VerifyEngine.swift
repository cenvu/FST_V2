import Foundation
import CryptoKit

nonisolated public struct FileInfo: Equatable, Sendable {
    public let relativePath: String
    public let size: Int64
}

public actor VerifyEngine {
    private var isCancelled = false
    
    public init() {}
    
    public func startVerification(request: VerificationRequest, onEvent: @escaping @Sendable (VerificationEvent) -> Void) async {
        isCancelled = false
        onEvent(.started)
        log("Verification Mode: \(request.mode.reportLabel)", onEvent: onEvent)
        log("Verification Coverage: \(request.mode.coverageDescription)", onEvent: onEvent)
        if let algorithm = request.mode.hashAlgorithm {
            log("Hash Algorithm: \(algorithm.displayName)", onEvent: onEvent)
            log("Hash Note: \(algorithm.verificationNote)", onEvent: onEvent)
        } else {
            log("Hash Algorithm: none", onEvent: onEvent)
        }
        log("Source Path: \(request.sourceURL.path)", onEvent: onEvent)
        log("Destination Path: \(request.destinationURL.path)", onEvent: onEvent)
        log("Phase: Verification run initialized", onEvent: onEvent)
        
        let startDate = Date()
        do {
            log("Phase: Source inventory build started", onEvent: onEvent)
            let sourceInventory = try await buildInventory(at: request.sourceURL, label: "Source", onEvent: onEvent)
            log("Phase: Source inventory build completed", onEvent: onEvent)
            log("Source File Count: \(sourceInventory.count)", onEvent: onEvent)

            if request.mode != .none && sourceInventory.isEmpty {
                log("No transferable files found after exclusions", onEvent: onEvent)
                log("VerificationError created: noTransferableFiles", onEvent: onEvent)
                log("VerificationError propagated from VerifyEngine: noTransferableFiles", onEvent: onEvent)
                onEvent(.failed(.noTransferableFiles))
                return
            }

            log("Phase: Destination inventory build started", onEvent: onEvent)
            let destInventory = try await buildInventory(at: request.destinationURL, label: "Destination", onEvent: onEvent)
            log("Phase: Destination inventory build completed", onEvent: onEvent)
            log("Destination File Count: \(destInventory.count)", onEvent: onEvent)
            
            if isCancelled {
                log("Cancellation detected after inventory build", onEvent: onEvent)
                onEvent(.cancelled)
                return
            }
            
            // 1. Check for missing files via count mismatch
            log("Phase: File count comparison started", onEvent: onEvent)
            if sourceInventory.count != destInventory.count {
                log("Mismatch: file count source=\(sourceInventory.count) destination=\(destInventory.count)", onEvent: onEvent)
                logInventoryMismatch(sourceInventory: sourceInventory, destInventory: destInventory, onEvent: onEvent)
                log("VerificationError created: fileCountMismatch", onEvent: onEvent)
                log("VerificationError propagated from VerifyEngine: fileCountMismatch", onEvent: onEvent)
                onEvent(.failed(.fileCountMismatch))
                return
            }
            log("Phase: File count comparison completed", onEvent: onEvent)
            
            // 2. Validate exact match of file names and identical sizes
            log("Phase: Relative path and size comparison started", onEvent: onEvent)
            for (relativePath, sourceFile) in sourceInventory {
                guard let destFile = destInventory[relativePath] else {
                    log("Missing file: \(relativePath)", onEvent: onEvent)
                    log("VerificationError created: destinationMissing", onEvent: onEvent)
                    log("VerificationError propagated from VerifyEngine: destinationMissing", onEvent: onEvent)
                    onEvent(.failed(.destinationMissing))
                    return
                }
                
                // Mismatched size skips hashing and fails immediately
                if sourceFile.size != destFile.size {
                    log("Mismatch: file size \(relativePath) source=\(sourceFile.size) destination=\(destFile.size)", onEvent: onEvent)
                    log("VerificationError created: fileSizeMismatch", onEvent: onEvent)
                    log("VerificationError propagated from VerifyEngine: fileSizeMismatch", onEvent: onEvent)
                    onEvent(.failed(.fileSizeMismatch))
                    return
                }
            }
            log("Phase: Relative path and size comparison completed", onEvent: onEvent)
            
            // 3. Sampling logic based on VerificationMode
            log("Phase: Verification sample selection started", onEvent: onEvent)
            let filesToVerify = sampleFiles(inventory: sourceInventory, mode: request.mode)
            let totalToVerify = filesToVerify.count
            log("Phase: Verification sample selection completed", onEvent: onEvent)
            log("Files selected for hash verification: \(totalToVerify)", onEvent: onEvent)
            var passedCount = 0
            
            guard totalToVerify > 0 else {
                log("Phase: No hash verification required for mode \(request.mode.rawValue)", onEvent: onEvent)
                let result = VerificationResult(
                    totalFiles: sourceInventory.count,
                    verifiedFiles: 0,
                    passedFiles: 0,
                    failedFiles: 0,
                    duration: Date().timeIntervalSince(startDate),
                    status: .passed
                )
                onEvent(.completed(result))
                return
            }
            
            // 4. Hash generation and comparison
            guard let hashAlgorithm = request.mode.hashAlgorithm else {
                log("VerificationError created: unknown", onEvent: onEvent)
                onEvent(.failed(.unknown))
                return
            }
            log("Phase: Hash comparison started", onEvent: onEvent)
            for file in filesToVerify {
                if isCancelled {
                    log("Cancellation detected before hashing \(file.relativePath)", onEvent: onEvent)
                    onEvent(.cancelled)
                    return
                }
                
                onEvent(.currentFile(file.relativePath))
                
                let sourceURL = request.sourceURL.appendingPathComponent(file.relativePath)
                let destURL = request.destinationURL.appendingPathComponent(file.relativePath)
                
                log("Hash comparison started: \(file.relativePath)", onEvent: onEvent)
                log("Hash source path: \(sourceURL.path)", onEvent: onEvent)
                log("Hash destination path: \(destURL.path)", onEvent: onEvent)
                let sourceHash = try await generateHash(url: sourceURL, algorithm: hashAlgorithm, label: "Source", relativePath: file.relativePath, onEvent: onEvent)
                let destHash = try await generateHash(url: destURL, algorithm: hashAlgorithm, label: "Destination", relativePath: file.relativePath, onEvent: onEvent)
                
                // Fast failure: a single mismatch instantly fails verification
                if sourceHash != destHash {
                    log("Mismatch: hash \(file.relativePath) source=\(sourceHash) destination=\(destHash)", onEvent: onEvent)
                    log("VerificationError created: hashMismatch", onEvent: onEvent)
                    log("VerificationError propagated from VerifyEngine: hashMismatch", onEvent: onEvent)
                    onEvent(.failed(.hashMismatch))
                    return
                }
                
                onEvent(.hashGenerated("Hash matched for \(file.relativePath)"))
                
                // 5. Update progress
                passedCount += 1
                onEvent(.progress(Double(passedCount) / Double(totalToVerify)))
            }
            log("Phase: Hash comparison completed", onEvent: onEvent)
            
            let result = VerificationResult(
                totalFiles: sourceInventory.count,
                verifiedFiles: totalToVerify,
                passedFiles: passedCount,
                failedFiles: 0,
                duration: Date().timeIntervalSince(startDate),
                status: .passed
            )
            onEvent(.completed(result))
            
        } catch {
            log("Catch block reached in VerifyEngine.startVerification: \(String(describing: error))", onEvent: onEvent)
            if isCancelled {
                log("Cancellation detected in VerifyEngine catch block", onEvent: onEvent)
                onEvent(.cancelled)
            } else {
                log("Thrown error caught: \(String(describing: error))", onEvent: onEvent)
                log("VerificationError created: unknown", onEvent: onEvent)
                log("VerificationError propagated from VerifyEngine: unknown", onEvent: onEvent)
                onEvent(.failed(.unknown))
            }
        }
    }
    
    public func cancel() {
        isCancelled = true
    }
    
    internal func sampleFiles(inventory: [String: FileInfo], mode: VerificationMode) -> [FileInfo] {
        let allFiles = Array(inventory.values)
        switch mode {
        case .none:
            return []
        case .full:
            return allFiles
        case .random33:
            guard !allFiles.isEmpty else { return [] }
            let targetCount = max(1, Int((Double(allFiles.count) * 0.33).rounded(.up)))
            
            // Weighted random sampling favoring larger files
            let scoredFiles = allFiles.map { file -> (FileInfo, Double) in
                let random = Double.random(in: 0..<1)
                let score = random * Double(file.size + 1)
                return (file, score)
            }
            
            // Sort by top scores and pick `targetCount`
            return scoredFiles.sorted { $0.1 > $1.1 }.prefix(targetCount).map { $0.0 }
        }
    }
    
    private func buildInventory(at url: URL, label: String, onEvent: @Sendable (VerificationEvent) -> Void) async throws -> [String: FileInfo] {
        var inventory = [String: FileInfo]()
        var folderCount = 0
        let fm = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .fileSizeKey]
        
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: resourceKeys, options: []) else {
            log("Inventory Build Failed: \(label) enumerator unavailable at \(url.path)", onEvent: onEvent)
            log("VerificationError created: sourceMissing", onEvent: onEvent)
            throw VerificationError.sourceMissing
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            if isCancelled {
                log("Cancellation detected during \(label) inventory at \(fileURL.path)", onEvent: onEvent)
                log("VerificationError created: cancelled", onEvent: onEvent)
                throw VerificationError.cancelled
            }
            
            let resourceValues: URLResourceValues
            do {
                resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            } catch {
                log("Inventory resource error: \(label) \(fileURL.path) \(String(describing: error))", onEvent: onEvent)
                throw error
            }
            if TransferFileExclusionPolicy.shouldExclude(fileURL, rootURL: url) {
                if resourceValues.isDirectory == true {
                    enumerator.skipDescendants()
                }
                log("Excluded metadata path: \(label) \(fileURL.path)", onEvent: onEvent)
                continue
            }

            if resourceValues.isDirectory == true {
                folderCount += 1
                continue
            }
            guard resourceValues.isRegularFile == true else { continue }
            
            let relativePath = TransferFileExclusionPolicy.relativePath(for: fileURL, rootURL: url)
            let size = Int64(resourceValues.fileSize ?? 0)
            
            inventory[relativePath] = FileInfo(relativePath: relativePath, size: size)
        }

        log("\(label) Folder Count: \(folderCount)", onEvent: onEvent)
        log("\(label) File Count: \(inventory.count)", onEvent: onEvent)
        
        return inventory
    }
    
    internal func generateHash(
        url: URL,
        algorithm: HashAlgorithm,
        label: String,
        relativePath: String,
        onEvent: @Sendable (VerificationEvent) -> Void
    ) async throws -> String {
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            log("Hash open error: \(label) \(relativePath) \(url.path) \(String(describing: error))", onEvent: onEvent)
            throw error
        }
        defer { try? handle.close() }
        
        var sha256Hasher = SHA256()
        var xxHash64Hasher = XXHash64()
        let chunkSize = 4 * 1024 * 1024 // 4 MB chunks to reduce memory footprint
        
        while true {
            let data: Data?
            do {
                data = try handle.read(upToCount: chunkSize)
            } catch {
                log("Hash read error: \(label) \(relativePath) \(url.path) \(String(describing: error))", onEvent: onEvent)
                throw error
            }
            guard let data, !data.isEmpty else { break }
            await Task.yield()
            if isCancelled || Task.isCancelled { 
                isCancelled = true
                log("Cancellation detected during hash: \(label) \(relativePath)", onEvent: onEvent)
                log("VerificationError created: cancelled", onEvent: onEvent)
                throw VerificationError.cancelled 
            }
            switch algorithm {
            case .sha256:
                sha256Hasher.update(data: data)
            case .xxHash64:
                xxHash64Hasher.update(data)
            }
        }

        let hash: String
        switch algorithm {
        case .sha256:
            let digest = sha256Hasher.finalize()
            hash = digest.map { String(format: "%02hhx", $0) }.joined()
        case .xxHash64:
            hash = xxHash64Hasher.hexDigest()
        }

        log("Hash generated: \(label) \(relativePath) \(algorithm.displayName) \(hash)", onEvent: onEvent)
        return hash
    }

    private func log(_ message: String, onEvent: @Sendable (VerificationEvent) -> Void) {
        onEvent(.log("[VERIFY DIAG] \(message)"))
    }

    private func logInventoryMismatch(
        sourceInventory: [String: FileInfo],
        destInventory: [String: FileInfo],
        onEvent: @Sendable (VerificationEvent) -> Void
    ) {
        let sourcePaths = Set(sourceInventory.keys)
        let destPaths = Set(destInventory.keys)
        let missingFiles = sourcePaths.subtracting(destPaths).sorted()
        let extraFiles = destPaths.subtracting(sourcePaths).sorted()

        log("SOURCE FILE INVENTORY", onEvent: onEvent)
        for path in sourcePaths.sorted() {
            log("SOURCE: \(path)", onEvent: onEvent)
        }

        log("DESTINATION FILE INVENTORY", onEvent: onEvent)
        for path in destPaths.sorted() {
            log("DESTINATION: \(path)", onEvent: onEvent)
        }

        log("MISSING FILES", onEvent: onEvent)
        if missingFiles.isEmpty {
            log("MISSING: none", onEvent: onEvent)
        } else {
            for path in missingFiles {
                log("MISSING: \(path)", onEvent: onEvent)
            }
        }

        log("EXTRA FILES", onEvent: onEvent)
        if extraFiles.isEmpty {
            log("EXTRA: none", onEvent: onEvent)
        } else {
            for path in extraFiles {
                log("EXTRA: \(path)", onEvent: onEvent)
            }
        }
    }
}

nonisolated public struct XXHash64: Sendable {
    private static let prime1: UInt64 = 11_400_714_785_074_694_791
    private static let prime2: UInt64 = 14_029_467_366_897_019_727
    private static let prime3: UInt64 = 1_609_587_929_392_839_161
    private static let prime4: UInt64 = 9_650_029_242_287_828_579
    private static let prime5: UInt64 = 2_870_177_450_012_600_261

    private let seed: UInt64
    private var totalLength: UInt64 = 0
    private var v1: UInt64
    private var v2: UInt64
    private var v3: UInt64
    private var v4: UInt64
    private var buffer: [UInt8] = []

    public init(seed: UInt64 = 0) {
        self.seed = seed
        self.v1 = seed &+ Self.prime1 &+ Self.prime2
        self.v2 = seed &+ Self.prime2
        self.v3 = seed
        self.v4 = seed &- Self.prime1
    }

    public mutating func update(_ data: Data) {
        updateBytes([UInt8](data))
    }

    public mutating func digest() -> UInt64 {
        var hash: UInt64

        if totalLength >= 32 {
            hash = Self.rotateLeft(v1, by: 1)
                &+ Self.rotateLeft(v2, by: 7)
                &+ Self.rotateLeft(v3, by: 12)
                &+ Self.rotateLeft(v4, by: 18)
            hash = Self.mergeRound(hash, v1)
            hash = Self.mergeRound(hash, v2)
            hash = Self.mergeRound(hash, v3)
            hash = Self.mergeRound(hash, v4)
        } else {
            hash = seed &+ Self.prime5
        }

        hash &+= totalLength

        var index = 0
        while index + 8 <= buffer.count {
            let lane = Self.readUInt64LE(buffer, at: index)
            hash ^= Self.round(0, lane)
            hash = Self.rotateLeft(hash, by: 27) &* Self.prime1 &+ Self.prime4
            index += 8
        }

        if index + 4 <= buffer.count {
            hash ^= UInt64(Self.readUInt32LE(buffer, at: index)) &* Self.prime1
            hash = Self.rotateLeft(hash, by: 23) &* Self.prime2 &+ Self.prime3
            index += 4
        }

        while index < buffer.count {
            hash ^= UInt64(buffer[index]) &* Self.prime5
            hash = Self.rotateLeft(hash, by: 11) &* Self.prime1
            index += 1
        }

        hash ^= hash >> 33
        hash &*= Self.prime2
        hash ^= hash >> 29
        hash &*= Self.prime3
        hash ^= hash >> 32
        return hash
    }

    public mutating func hexDigest() -> String {
        String(format: "%016llx", digest())
    }

    private mutating func updateBytes(_ bytes: [UInt8]) {
        totalLength &+= UInt64(bytes.count)
        var input = bytes

        if !buffer.isEmpty {
            let needed = 32 - buffer.count
            if input.count < needed {
                buffer.append(contentsOf: input)
                return
            }

            buffer.append(contentsOf: input.prefix(needed))
            processStripe(buffer, at: 0)
            buffer.removeAll(keepingCapacity: true)
            input.removeFirst(needed)
        }

        var index = 0
        while index + 32 <= input.count {
            processStripe(input, at: index)
            index += 32
        }

        if index < input.count {
            buffer.append(contentsOf: input[index...])
        }
    }

    private mutating func processStripe(_ bytes: [UInt8], at index: Int) {
        v1 = Self.round(v1, Self.readUInt64LE(bytes, at: index))
        v2 = Self.round(v2, Self.readUInt64LE(bytes, at: index + 8))
        v3 = Self.round(v3, Self.readUInt64LE(bytes, at: index + 16))
        v4 = Self.round(v4, Self.readUInt64LE(bytes, at: index + 24))
    }

    private static func round(_ accumulator: UInt64, _ input: UInt64) -> UInt64 {
        var accumulator = accumulator
        accumulator &+= input &* prime2
        accumulator = rotateLeft(accumulator, by: 31)
        accumulator &*= prime1
        return accumulator
    }

    private static func mergeRound(_ accumulator: UInt64, _ value: UInt64) -> UInt64 {
        var accumulator = accumulator
        accumulator ^= round(0, value)
        accumulator = accumulator &* prime1 &+ prime4
        return accumulator
    }

    private static func rotateLeft(_ value: UInt64, by count: UInt64) -> UInt64 {
        (value << count) | (value >> (64 - count))
    }

    private static func readUInt64LE(_ bytes: [UInt8], at index: Int) -> UInt64 {
        UInt64(bytes[index])
            | (UInt64(bytes[index + 1]) << 8)
            | (UInt64(bytes[index + 2]) << 16)
            | (UInt64(bytes[index + 3]) << 24)
            | (UInt64(bytes[index + 4]) << 32)
            | (UInt64(bytes[index + 5]) << 40)
            | (UInt64(bytes[index + 6]) << 48)
            | (UInt64(bytes[index + 7]) << 56)
    }

    private static func readUInt32LE(_ bytes: [UInt8], at index: Int) -> UInt32 {
        UInt32(bytes[index])
            | (UInt32(bytes[index + 1]) << 8)
            | (UInt32(bytes[index + 2]) << 16)
            | (UInt32(bytes[index + 3]) << 24)
    }
}
