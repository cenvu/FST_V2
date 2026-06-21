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
        log("Verification Mode: \(request.mode.rawValue)", onEvent: onEvent)
        log("Source Path: \(request.sourceURL.path)", onEvent: onEvent)
        log("Destination Path: \(request.destinationURL.path)", onEvent: onEvent)
        log("Phase: Verification run initialized", onEvent: onEvent)
        
        let startDate = Date()
        do {
            log("Phase: Source inventory build started", onEvent: onEvent)
            let sourceInventory = try await buildInventory(at: request.sourceURL, label: "Source", onEvent: onEvent)
            log("Phase: Source inventory build completed", onEvent: onEvent)
            log("Source File Count: \(sourceInventory.count)", onEvent: onEvent)

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
                let sourceHash = try await generateHash(url: sourceURL, label: "Source", relativePath: file.relativePath, onEvent: onEvent)
                let destHash = try await generateHash(url: destURL, label: "Destination", relativePath: file.relativePath, onEvent: onEvent)
                
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
            
            let relativePath = fileURL.path.replacingOccurrences(of: url.path + "/", with: "")
            let size = Int64(resourceValues.fileSize ?? 0)
            
            inventory[relativePath] = FileInfo(relativePath: relativePath, size: size)
        }

        log("\(label) Folder Count: \(folderCount)", onEvent: onEvent)
        log("\(label) File Count: \(inventory.count)", onEvent: onEvent)
        
        return inventory
    }
    
    internal func generateHash(url: URL, label: String, relativePath: String, onEvent: @Sendable (VerificationEvent) -> Void) async throws -> String {
        // NOTE: SHA256 is used here as an approved fallback for compilation/MVP constraints.
        // It provides the identical architecture pattern for streaming 4MB chunks securely.
        // This easily swaps with an `xxHash64` package implementer using the standard init()/update()/finalize() algorithm pattern.
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            log("Hash open error: \(label) \(relativePath) \(url.path) \(String(describing: error))", onEvent: onEvent)
            throw error
        }
        defer { try? handle.close() }
        
        var hasher = SHA256()
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
            hasher.update(data: data)
        }
        
        let digest = hasher.finalize()
        let hash = digest.map { String(format: "%02hhx", $0) }.joined()
        log("Hash generated: \(label) \(relativePath) \(hash)", onEvent: onEvent)
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
