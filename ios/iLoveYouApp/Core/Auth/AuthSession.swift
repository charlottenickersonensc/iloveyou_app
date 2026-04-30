import Foundation

public struct FirebaseAuthUser: Equatable {
    public let uid: String
    public let email: String?

    public init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
}

public struct AppleSignInToken: Equatable {
    public let identityToken: String
    public let rawNonce: String
    public let fullName: PersonNameComponents?

    public init(identityToken: String, rawNonce: String, fullName: PersonNameComponents? = nil) {
        self.identityToken = identityToken
        self.rawNonce = rawNonce
        self.fullName = fullName
    }
}

public struct CompleteSignupInput: Equatable {
    public var username: String
    public var displayUsername: String
    public var dateOfBirth: String
    public var pronouns: String?
    public var locationText: String?

    public init(username: String, displayUsername: String, dateOfBirth: String, pronouns: String? = nil, locationText: String? = nil) {
        self.username = username
        self.displayUsername = displayUsername
        self.dateOfBirth = dateOfBirth
        self.pronouns = pronouns
        self.locationText = locationText
    }
}

public struct UpdateProfileInput: Equatable {
    public var displayUsername: String
    public var pronouns: String?
    public var locationText: String?
    public var bio: String?
    public var interests: [String]
    public var isPrivate: Bool
    public var avatarUrl: URL?

    public init(displayUsername: String, pronouns: String?, locationText: String?, bio: String?, interests: [String], isPrivate: Bool, avatarUrl: URL? = nil) {
        self.displayUsername = displayUsername
        self.pronouns = pronouns
        self.locationText = locationText
        self.bio = bio
        self.interests = interests
        self.isPrivate = isPrivate
        self.avatarUrl = avatarUrl
    }
}

public protocol AuthRepository {
    func signInWithApple() async throws -> FirebaseAuthUser
    func signInWithApple(token: AppleSignInToken) async throws -> FirebaseAuthUser
    func registerWithEmail(email: String, password: String) async throws -> FirebaseAuthUser
    func signInWithEmail(email: String, password: String) async throws -> FirebaseAuthUser
    func completeSignup(input: CompleteSignupInput) async throws -> User
    func signOut() throws
}

public protocol ProfileRepository {
    func fetchMe() async throws -> User
    func updateProfile(input: UpdateProfileInput) async throws -> User
    func fetchFruit(id: String) async throws -> FruitCommunity
}

public struct FeedPage {
    public let posts: [Post]
    public let nextCursor: Any?
    public let hasMore: Bool

    public init(posts: [Post], nextCursor: Any?, hasMore: Bool) {
        self.posts = posts
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}

public struct NotificationPage {
    public let notifications: [NotificationItem]
    public let nextCursor: Any?
    public let hasMore: Bool

    public init(notifications: [NotificationItem], nextCursor: Any?, hasMore: Bool) {
        self.notifications = notifications
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}

public struct CreatePostInput: Equatable {
    public var contentText: String
    public var imageUrls: [URL]
    public var visibility: PostVisibility

    public init(contentText: String, imageUrls: [URL] = [], visibility: PostVisibility = .fruit) {
        self.contentText = contentText
        self.imageUrls = imageUrls
        self.visibility = visibility
    }
}

public struct ReportContentInput: Equatable {
    public var targetType: String
    public var targetId: String
    public var reason: ReportReason
    public var details: String?

    public init(targetType: String = "post", targetId: String, reason: ReportReason, details: String? = nil) {
        self.targetType = targetType
        self.targetId = targetId
        self.reason = reason
        self.details = details
    }
}

public enum Mood: String, CaseIterable, Codable, Equatable, Identifiable {
    case great
    case good
    case okay
    case low
    case hard

    public var id: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .low: return "Low"
        case .hard: return "Hard"
        }
    }

    public var systemImageName: String {
        switch self {
        case .great: return "sun.max.fill"
        case .good: return "leaf.fill"
        case .okay: return "circle.lefthalf.filled"
        case .low: return "cloud.fill"
        case .hard: return "cloud.rain.fill"
        }
    }
}

public struct MoodCheckin: Identifiable, Codable, Equatable {
    public let id: String
    public let userId: String
    public let fruitCommunityId: String
    public let date: String
    public let mood: Mood
    public let note: String?
    public let createdAt: Date
    public let updatedAt: Date
}

public struct MoodCheckinInput: Equatable {
    public var date: String
    public var mood: Mood
    public var note: String?

    public init(date: String, mood: Mood, note: String? = nil) {
        self.date = date
        self.mood = mood
        self.note = note
    }
}

public struct DailyAffirmation: Identifiable, Codable, Equatable {
    public let id: String
    public let date: String
    public let text: String
    public let active: Bool
    public let source: String
}

public enum ReportReason: String, CaseIterable, Codable, Equatable {
    case harassment
    case hate
    case selfHarm = "self_harm"
    case sexualContent = "sexual_content"
    case spam
    case violence
    case other

    public var displayTitle: String {
        switch self {
        case .harassment: return "Harassment"
        case .hate: return "Hate"
        case .selfHarm: return "Self-harm"
        case .sexualContent: return "Sexual content"
        case .spam: return "Spam"
        case .violence: return "Violence"
        case .other: return "Other"
        }
    }
}

public enum FriendRequestAction: String, Equatable {
    case accept
    case decline
}

public protocol FeedRepository {
    func fetchFruitFeed(currentUser: User, pageSize: Int, startAfter: Any?) async throws -> FeedPage
    func fetchTrendingFeed(currentUser: User, pageSize: Int, startAfter: Any?) async throws -> FeedPage
    func createPost(input: CreatePostInput) async throws -> Post
    func uploadPostImages(_ images: [PostImageUpload], draftPostId: String) async throws -> [URL]
    func toggleLike(postId: String) async throws -> LikeResult
    func createComment(postId: String, contentText: String) async throws -> PostComment
    func reportContent(input: ReportContentInput) async throws
}

public protocol FriendsRepository {
    func searchPeople(currentUser: User, query: String) async throws -> [User]
    func sendRequest(receiverId: String) async throws -> Friendship
    func respond(friendshipId: String, action: FriendRequestAction) async throws -> Friendship?
    func fetchFriends(currentUser: User) async throws -> [User]
    func fetchPendingRequests(currentUser: User) async throws -> [Friendship]
    func fetchFriendships(currentUser: User) async throws -> [Friendship]
    func fetchUsers(ids: [String]) async throws -> [User]
}

public protocol MentalHealthRepository {
    func fetchTodayMoodCheckin(date: String) async throws -> MoodCheckin?
    func submitMoodCheckin(input: MoodCheckinInput) async throws -> MoodCheckin
    func getTodayAffirmation() async throws -> DailyAffirmation
}

public protocol NotificationRepository {
    func fetchNotifications(currentUser: User, pageSize: Int, startAfter: Any?) async throws -> NotificationPage
    func markNotificationRead(notificationId: String) async throws
}
