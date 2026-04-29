import Foundation

public struct PostImageUpload: Equatable {
    public let data: Data
    public let fileName: String
    public let contentType: String

    public init(data: Data, fileName: String = UUID().uuidString + ".jpg", contentType: String = "image/jpeg") {
        self.data = data
        self.fileName = fileName
        self.contentType = contentType
    }
}

public protocol ImageUploadService {
    func uploadAvatar(data: Data, fileName: String) async throws -> URL
    func uploadPostImage(_ image: PostImageUpload, draftPostId: String) async throws -> URL
}

#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseStorage
#endif

public final class FirebaseImageUploadService: ImageUploadService {
    public init() {}

    public func uploadAvatar(data: Data, fileName: String) async throws -> URL {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthRepositoryError.missingAuthenticatedUser
        }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        return try await upload(data: data, metadata: metadata, path: "avatars/\(uid)/\(fileName)")
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func uploadPostImage(_ image: PostImageUpload, draftPostId: String) async throws -> URL {
        #if canImport(FirebaseStorage)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthRepositoryError.missingAuthenticatedUser
        }
        let metadata = StorageMetadata()
        metadata.contentType = image.contentType
        let path = "postImages/\(uid)/\(draftPostId)/\(image.fileName)"
        return try await upload(data: image.data, metadata: metadata, path: path)
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    #if canImport(FirebaseStorage)
    private func upload(data: Data, metadata: StorageMetadata, path: String) async throws -> URL {
        let reference = Storage.storage().reference().child(path)
        _ = try await withCheckedThrowingContinuation { continuation in
            reference.putData(data, metadata: metadata) { metadata, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: AuthRepositoryError.missingCallableResponse("storageUpload"))
                }
            }
        } as StorageMetadata
        return try await reference.downloadURL()
    }
    #endif
}
