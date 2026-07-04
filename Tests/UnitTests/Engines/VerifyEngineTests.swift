// FST / CenVu | (+84) 842 841 222

import XCTest

final class VerifyEngineTests: XCTestCase {
    
    func testSamplingLogicRandom33() async {
        let engine = VerifyEngine()
        let inventory = [
            "f1.mov": FileInfo(relativePath: "f1.mov", size: 1000),
            "f2.mov": FileInfo(relativePath: "f2.mov", size: 2000),
            "f3.mov": FileInfo(relativePath: "f3.mov", size: 3000),
            "f4.mov": FileInfo(relativePath: "f4.mov", size: 4000)
        ]
        
        let sampled = await engine.sampleFiles(inventory: inventory, mode: .random33)
        // 33% of 4 = 1.32, rounded up ensures at least 2 files
        XCTAssertEqual(sampled.count, 2)
        XCTAssertFalse(sampled.isEmpty)
    }

    func testSamplingLogicFull() async {
        let engine = VerifyEngine()
        let inventory = [
            "file1.mov": FileInfo(relativePath: "file1.mov", size: 1000),
            "file2.mov": FileInfo(relativePath: "file2.mov", size: 1500)
        ]
        
        let sampled = await engine.sampleFiles(inventory: inventory, mode: .full)
        XCTAssertEqual(sampled.count, 2)
    }
    
    func testSamplingLogicMinimumOne() async {
        let engine = VerifyEngine()
        let inventory = [
            "small.txt": FileInfo(relativePath: "small.txt", size: 50)
        ]
        
        let sampled = await engine.sampleFiles(inventory: inventory, mode: .random33)
        XCTAssertEqual(sampled.count, 1)
    }
    
    func testHashGenerationAndMismatch() async throws {
        let engine = VerifyEngine()
        let fm = FileManager.default
        let file1 = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let file2 = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try "Content A".write(to: file1, atomically: true, encoding: .utf8)
        try "Content B".write(to: file2, atomically: true, encoding: .utf8) // Different content
        
        defer {
            try? fm.removeItem(at: file1)
            try? fm.removeItem(at: file2)
        }
        
        let hash1 = try await engine.generateHash(url: file1)
        let hash2 = try await engine.generateHash(url: file2)
        
        // Ensure consistent hash for the same file
        let hash1_verify = try await engine.generateHash(url: file1)
        XCTAssertEqual(hash1, hash1_verify)
        
        // Single mismatch rule verification
        XCTAssertNotEqual(hash1, hash2, "Mismatched content must produce different hashes")
    }
}
