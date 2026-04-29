import Foundation

public protocol ImageUploadService {
    func uploadAvatar(data: Data, fileName: String) async throws -> URL
}
