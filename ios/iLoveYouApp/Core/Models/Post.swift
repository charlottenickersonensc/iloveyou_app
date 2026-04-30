import Foundation

public struct Post: Identifiable, Codable, Equatable {
    public let id: String
    public let authorId: String
    public let authorUsername: String
    public let authorDisplayUsername: String
    public let authorAvatarUrl: URL?
    public let fruitCommunityId: String
    public let groupId: String?
    public let contentText: String
    public let imageUrls: [URL]
    public let visibility: PostVisibility
    public let locationText: String?
    public let isAnonymous: Bool
    public let pinned: Bool
    public let likeCount: Int
    public let commentCount: Int
    public let reportCount: Int
    public let trendingScore: Int
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
    public var isLikedByCurrentUser: Bool

    public init(
        id: String,
        authorId: String,
        authorUsername: String,
        authorDisplayUsername: String,
        authorAvatarUrl: URL? = nil,
        fruitCommunityId: String,
        groupId: String? = nil,
        contentText: String,
        imageUrls: [URL] = [],
        visibility: PostVisibility = .fruit,
        locationText: String? = nil,
        isAnonymous: Bool = false,
        pinned: Bool = false,
        likeCount: Int = 0,
        commentCount: Int = 0,
        reportCount: Int = 0,
        trendingScore: Int = 0,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        isLikedByCurrentUser: Bool = false
    ) {
        self.id = id
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.authorDisplayUsername = authorDisplayUsername
        self.authorAvatarUrl = authorAvatarUrl
        self.fruitCommunityId = fruitCommunityId
        self.groupId = groupId
        self.contentText = contentText
        self.imageUrls = imageUrls
        self.visibility = visibility
        self.locationText = locationText
        self.isAnonymous = isAnonymous
        self.pinned = pinned
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.reportCount = reportCount
        self.trendingScore = trendingScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.isLikedByCurrentUser = isLikedByCurrentUser
    }
}

public enum PostVisibility: String, Codable, Equatable {
    case fruit
    case friends
}

public struct PostComment: Identifiable, Codable, Equatable {
    public let id: String
    public let postId: String
    public let authorId: String
    public let authorDisplayUsername: String
    public let authorAvatarUrl: URL?
    public let fruitCommunityId: String
    public let contentText: String
    public let reportCount: Int
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?
}

public struct LikeResult: Codable, Equatable {
    public let liked: Bool
    public let likeCount: Int
}
