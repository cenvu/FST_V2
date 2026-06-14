import Foundation
import CryptoKit

public struct FileInfo: Equatable {
    public let relativePath: String
    public let size: Int64
}

public actor VerifyEngine {
    private var isCancelled = false
    
    public init() {}
    
    public func startVerification(request: VerificationRequest, onEvent: @escaping (VerificationEvent) -> Void) async {
        isCancelled = false
        onEvent(.started)
        
        let startDate = Date()
        do {
            let sourceInventory = try await buildInventory(at: request.sourceURL)
            let destInventory = try await buildInventory(at: request.destinationURL)
            
            if isCancelled {
                onEvent(.cancelled)
                return
            }
            
            // 1. Check for missing files via count mismatch
            if sourceInventory.count != destInventory.count {
                onEvent(.failed(.fileCountMismatch))
                return
            }
            
            // 2. Validate exact match of file names and identical sizes
            for (relativePath, sourceFile) in sourceInventory {
                guard let destFile = destInventory[relativePath] else {
                    onEvent(.failed(.destinationMissing))
                    return
                }
                
                // Mismatched size skips hashing and fails immediately
                if sourceFile.size != destFile.size {
                    onEvent(.failed(.fileSizeMismatch))
                    return
                }
            }
            
            // 3. Sampling logic based on VerificationMode
            let filesToVerify = sampleFiles(inventory: sourceInventory, mode: request.mode)
            let totalToVerify = filesToVerify.count
            var passedCount = 0
            
            guard totalToVerify > 0 else {
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
            for file in filesToVerify {
                if isCancelled {
                    onEvent(.cancelled)
                    return
                }
                
                onEvent(.currentFile(file.relativePath))
                
                let sourceURL = request.sourceURL.appendingPathComponent(file.relativePath)
                let destURL = request.destinationURL.appendingPathComponent(file.relativePath)
                
                let sourceHash = try await generateHash(url: sourceURL)
                let destHash = try await generateHash(url: destURL)
                
                // Fast failure: a single mismatch instantly fails verification
                if sourceHash != destHash {
                    onEvent(.failed(.hashMismatch))
                    return
                }
                
                onEvent(.hashGenerated("Hash matched for \(file.relativePath)"))
                
                // 5. Update progress
                passedCount += 1
                onEvent(.progress(Double(passedCount) / Double(totalToVerify)))
            }
            
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
            if isCancelled {
                onEvent(.cancelled)
            } else {
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
    
    private func buildInventory(at url: URL) async throws -> [String: FileInfo] {
        var inventory = [String: FileInfo]()
        let fm = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles]) else {
            throw VerificationError.sourceMissing
        }
        
        for case let fileURL as URL in enumerator {
            if isCancelled { throw VerificationError.cancelled }
            
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            guard resourceValues.isRegularFile == true else { continue }
            
            let relativePath = fileURL.path.replacingOccurrences(of: url.path + "/", with: "")
            let size = Int64(resourceValues.fileSize ?? 0)
            
            inventory[relativePath] = FileInfo(relativePath: relativePath, size: size)
        }
        
        return inventory
    }
    
    internal func generateHash(url: URL) async throws -> String {
        // NOTE: SHA256 is used here as an approved fallback for compilation/MVP constraints.
        // It provides the identical architecture pattern for streaming 4MB chunks securely.
        // This easily swaps with an `xxHash64` package implementer using the standard init()/update()/finalize() algorithm pattern.
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        
        var hasher = SHA256()
        let chunkSize = 4 * 1024 * 1024 // 4 MB chunks to reduce memory footprint
        
        while let data = try handle.read(upToCount: chunkSize), !data.isEmpty {
            await Task.yield()
            if isCancelled || Task.isCancelled { 
                isCancelled = true
                throw VerificationError.cancelled 
            }
            hasher.update(data: data)
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
