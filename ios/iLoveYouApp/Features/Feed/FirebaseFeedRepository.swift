import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
#endif

public final class FirebaseFeedRepository: FeedRepository {
    private let imageUploadService: ImageUploadService

    public init(imageUploadService: ImageUploadService = FirebaseImageUploadService()) {
        self.imageUploadService = imageUploadService
    }

    public func fetchFruitFeed(currentUser: User, pageSize: Int, startAfter: Any?) async throws -> FeedPage {
        #if canImport(FirebaseFirestore)
        var query: Query = Firestore.firestore().collection("posts")
            .whereField("fruitCommunityId", isEqualTo: currentUser.fruitCommunityId)
            .whereField("visibility", isEqualTo: "fruit")
            .whereField("deletedAt", isEqualTo: NSNull())
            .order(by: "pinned", descending: true)
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize)

        if let cursor = startAfter as? DocumentSnapshot {
            query = query.start(afterDocument: cursor)
        }

        let snapshot = try await query.getDocuments()
        var posts = try snapshot.documents.map { document in
            try PostMapper.map(id: document.documentID, data: document.data())
        }
        let likedPostIds = try await fetchLikedPostIds(
            postIds: posts.map(\.id),
            currentUser: currentUser
        )
        for index in posts.indices where likedPostIds.contains(posts[index].id) {
            posts[index].isLikedByCurrentUser = true
        }

        return FeedPage(
            posts: posts,
            nextCursor: snapshot.documents.last,
            hasMore: snapshot.documents.count == pageSize
        )
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func fetchTrendingFeed(currentUser: User, pageSize: Int, startAfter: Any?) async throws -> FeedPage {
        #if canImport(FirebaseFirestore)
        var query: Query = Firestore.firestore().collection("posts")
            .whereField("fruitCommunityId", isEqualTo: currentUser.fruitCommunityId)
            .whereField("visibility", isEqualTo: "fruit")
            .whereField("deletedAt", isEqualTo: NSNull())
            .order(by: "trendingScore", descending: true)
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize)

        if let cursor = startAfter as? DocumentSnapshot {
            query = query.start(afterDocument: cursor)
        }

        let snapshot = try await query.getDocuments()
        var posts = try snapshot.documents.map { document in
            try PostMapper.map(id: document.documentID, data: document.data())
        }
        let likedPostIds = try await fetchLikedPostIds(
            postIds: posts.map(\.id),
            currentUser: currentUser
        )
        for index in posts.indices where likedPostIds.contains(posts[index].id) {
            posts[index].isLikedByCurrentUser = true
        }

        return FeedPage(
            posts: posts,
            nextCursor: snapshot.documents.last,
            hasMore: snapshot.documents.count == pageSize
        )
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    #if canImport(FirebaseFirestore)
    private func fetchLikedPostIds(postIds: [String], currentUser: User) async throws -> Set<String> {
        guard !postIds.isEmpty else { return [] }

        var likedPostIds = Set<String>()
        for chunk in postIds.chunked(into: 10) {
            let snapshot = try await Firestore.firestore().collection("postLikes")
                .whereField("fruitCommunityId", isEqualTo: currentUser.fruitCommunityId)
                .whereField("userId", isEqualTo: currentUser.id)
                .whereField("postId", in: chunk)
                .getDocuments()

            for document in snapshot.documents {
                if let postId = document.data()["postId"] as? String {
                    likedPostIds.insert(postId)
                }
            }
        }
        return likedPostIds
    }
    #endif

    public func createPost(input: CreatePostInput) async throws -> Post {
        #if canImport(FirebaseFunctions)
        let payload: [String: Any] = [
            "contentText": input.contentText,
            "imageUrls": input.imageUrls.map(\.absoluteString),
            "visibility": input.visibility.rawValue
        ]
        let result = try await Functions.functions().httpsCallable("createPost").call(payload)
        guard let post = PostMapper.mapCallablePost(from: result.data) else {
            throw AuthRepositoryError.missingCallableResponse("createPost")
        }
        return post
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func uploadPostImages(_ images: [PostImageUpload], draftPostId: String) async throws -> [URL] {
        try await withThrowingTaskGroup(of: URL.self) { group in
            for image in images {
                group.addTask {
                    try await self.imageUploadService.uploadPostImage(image, draftPostId: draftPostId)
                }
            }
            var urls: [URL] = []
            for try await url in group {
                urls.append(url)
            }
            return urls
        }
    }

    public func toggleLike(postId: String) async throws -> LikeResult {
        #if canImport(FirebaseFunctions)
        let result = try await Functions.functions().httpsCallable("togglePostLike").call(["postId": postId])
        guard let data = result.data as? [String: Any],
              let liked = data["liked"] as? Bool,
              let likeCount = data["likeCount"] as? Int else {
            throw AuthRepositoryError.missingCallableResponse("togglePostLike")
        }
        return LikeResult(liked: liked, likeCount: likeCount)
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func createComment(postId: String, contentText: String) async throws -> PostComment {
        #if canImport(FirebaseFunctions)
        let result = try await Functions.functions().httpsCallable("createComment").call([
            "postId": postId,
            "contentText": contentText
        ])
        guard let comment = PostMapper.mapCallableComment(from: result.data) else {
            throw AuthRepositoryError.missingCallableResponse("createComment")
        }
        return comment
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func reportContent(input: ReportContentInput) async throws {
        #if canImport(FirebaseFunctions)
        let payload: [String: Any?] = [
            "targetType": input.targetType,
            "targetId": input.targetId,
            "reason": input.reason.rawValue,
            "details": input.details
        ]
        _ = try await Functions.functions().httpsCallable("reportContent").call(payload.compactMapValues { $0 })
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

private enum PostMapper {
    static func mapCallablePost(from response: Any) -> Post? {
        guard let envelope = response as? [String: Any],
              let data = envelope["post"] as? [String: Any],
              let id = data["id"] as? String else {
            return nil
        }
        return try? map(id: id, data: data)
    }

    static func mapCallableComment(from response: Any) -> PostComment? {
        guard let envelope = response as? [String: Any],
              let data = envelope["comment"] as? [String: Any],
              let id = data["id"] as? String else {
            return nil
        }
        return PostComment(
            id: id,
            postId: data["postId"] as? String ?? "",
            authorId: data["authorId"] as? String ?? "",
            authorDisplayUsername: data["authorDisplayUsername"] as? String ?? "",
            authorAvatarUrl: url(from: data["authorAvatarUrl"]),
            fruitCommunityId: data["fruitCommunityId"] as? String ?? "",
            contentText: data["contentText"] as? String ?? "",
            reportCount: data["reportCount"] as? Int ?? 0,
            createdAt: date(from: data["createdAt"]) ?? Date(),
            updatedAt: date(from: data["updatedAt"]) ?? Date(),
            deletedAt: date(from: data["deletedAt"])
        )
    }

    static func map(id: String, data: [String: Any]) throws -> Post {
        Post(
            id: id,
            authorId: data["authorId"] as? String ?? "",
            authorUsername: data["authorUsername"] as? String ?? "",
            authorDisplayUsername: data["authorDisplayUsername"] as? String ?? "",
            authorAvatarUrl: url(from: data["authorAvatarUrl"]),
            fruitCommunityId: data["fruitCommunityId"] as? String ?? "",
            groupId: data["groupId"] as? String,
            contentText: data["contentText"] as? String ?? "",
            imageUrls: urls(from: data["imageUrls"]),
            visibility: PostVisibility(rawValue: data["visibility"] as? String ?? "fruit") ?? .fruit,
            locationText: data["locationText"] as? String,
            isAnonymous: data["isAnonymous"] as? Bool ?? false,
            pinned: data["pinned"] as? Bool ?? false,
            likeCount: data["likeCount"] as? Int ?? 0,
            commentCount: data["commentCount"] as? Int ?? 0,
            reportCount: data["reportCount"] as? Int ?? 0,
            trendingScore: data["trendingScore"] as? Int ?? 0,
            createdAt: date(from: data["createdAt"]) ?? Date(),
            updatedAt: date(from: data["updatedAt"]) ?? Date(),
            deletedAt: date(from: data["deletedAt"])
        )
    }

    private static func urls(from value: Any?) -> [URL] {
        guard let strings = value as? [String] else { return [] }
        return strings.compactMap(URL.init(string:))
    }

    private static func url(from value: Any?) -> URL? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    private static func date(from value: Any?) -> Date? {
        if let date = value as? Date {
            return date
        }
        #if canImport(FirebaseFirestore)
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        #endif
        if let data = value as? [String: Any] {
            let seconds = data["_seconds"] as? TimeInterval ?? data["seconds"] as? TimeInterval
            let nanoseconds = data["_nanoseconds"] as? TimeInterval ?? data["nanoseconds"] as? TimeInterval ?? 0
            if let seconds {
                return Date(timeIntervalSince1970: seconds + nanoseconds / 1_000_000_000)
            }
        }
        if let milliseconds = value as? TimeInterval {
            return Date(timeIntervalSince1970: milliseconds / 1_000)
        }
        return nil
    }
}
