import XCTest

final class DriveServiceTests: XCTestCase {
    
    func testValidateSourceEmptyDirectoryThrowsError() async throws {
        let service = DriveService()
        let fm = FileManager.default
        let emptyDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try fm.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        
        defer {
            try? fm.removeItem(at: emptyDir)
        }
        
        do {
            try await service.validateSource(at: emptyDir)
            XCTFail("Expected validateSource to throw for an empty directory, but it didn't.")
        } catch let error as TransferError {
            XCTAssertEqual(error, .sourceEmpty)
            XCTAssertEqual(error.localizedDescription, "The selected source folder is empty.")
        } catch {
            XCTFail("Expected TransferError.sourceEmpty, instead got: \(error)")
        }
    }
}
