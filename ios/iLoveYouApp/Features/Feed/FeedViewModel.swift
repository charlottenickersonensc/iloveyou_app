import Combine
import Foundation

public enum FeedMode: String, CaseIterable, Identifiable, Equatable {
    case fruit
    case trending

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .fruit: return "Fruit"
        case .trending: return "Trending"
        }
    }

    public var emptyTitle: String {
        switch self {
        case .fruit: return "No posts yet"
        case .trending: return "No trending posts yet"
        }
    }

    public var emptyDescription: String {
        switch self {
        case .fruit: return "Start the conversation."
        case .trending: return "Likes and comments will lift posts here."
        }
    }
}

@MainActor
public final class FeedViewModel: ObservableObject {
    @Published public private(set) var posts: [Post] = []
    @Published public private(set) var feedMode: FeedMode = .fruit
    @Published public private(set) var isLoading = false
    @Published public private(set) var isRefreshing = false
    @Published public private(set) var isLoadingMore = false
    @Published public private(set) var hasMore = true
    @Published public var errorMessage: String?

    private let currentUser: User
    private let feedRepository: FeedRepository
    private let pageSize: Int
    private var nextCursor: Any?

    public init(currentUser: User, feedRepository: FeedRepository, pageSize: Int = 25) {
        self.currentUser = currentUser
        self.feedRepository = feedRepository
        self.pageSize = pageSize
    }

    public func loadInitial() async {
        guard posts.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        await load(reset: true)
    }

    public func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await load(reset: true)
    }

    public func selectFeedMode(_ mode: FeedMode) async {
        guard mode != feedMode else { return }
        feedMode = mode
        posts = []
        nextCursor = nil
        hasMore = true
        isLoading = true
        defer { isLoading = false }
        await load(reset: true)
    }

    public func loadMoreIfNeeded(currentPost: Post?) async {
        guard hasMore, !isLoadingMore, let currentPost, currentPost.id == posts.last?.id else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await load(reset: false)
    }

    public func createPost(contentText: String, imageUrls: [URL] = [], visibility: PostVisibility = .fruit) async {
        do {
            let post = try await feedRepository.createPost(input: CreatePostInput(
                contentText: contentText,
                imageUrls: imageUrls,
                visibility: visibility
            ))
            if feedMode == .fruit {
                posts.insert(post, at: 0)
            } else {
                await load(reset: true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func toggleLike(post: Post) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let original = posts[index]
        posts[index].isLikedByCurrentUser.toggle()
        posts[index] = optimisticLikeState(for: posts[index])

        do {
            let result = try await feedRepository.toggleLike(postId: post.id)
            posts[index].isLikedByCurrentUser = result.liked
            posts[index] = postWithLikeCount(posts[index], likeCount: result.likeCount)
        } catch {
            posts[index] = original
            errorMessage = error.localizedDescription
        }
    }

    public func createComment(postId: String, contentText: String) async throws -> PostComment {
        let comment = try await feedRepository.createComment(postId: postId, contentText: contentText)
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index] = postWithCommentCount(posts[index], commentCount: posts[index].commentCount + 1)
        }
        return comment
    }

    public func reportPost(postId: String, reason: ReportReason, details: String?) async {
        do {
            try await feedRepository.reportContent(input: ReportContentInput(
                targetId: postId,
                reason: reason,
                details: details
            ))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func load(reset: Bool) async {
        do {
            let page = try await fetchPage(reset: reset)
            posts = reset ? page.posts : posts + page.posts
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchPage(reset: Bool) async throws -> FeedPage {
        let cursor = reset ? nil : nextCursor
        switch feedMode {
        case .fruit:
            return try await feedRepository.fetchFruitFeed(
                currentUser: currentUser,
                pageSize: pageSize,
                startAfter: cursor
            )
        case .trending:
            return try await feedRepository.fetchTrendingFeed(
                currentUser: currentUser,
                pageSize: pageSize,
                startAfter: cursor
            )
        }
    }

    private func optimisticLikeState(for post: Post) -> Post {
        let delta = post.isLikedByCurrentUser ? 1 : -1
        return postWithLikeCount(post, likeCount: max(0, post.likeCount + delta))
    }

    private func postWithLikeCount(_ post: Post, likeCount: Int) -> Post {
        var copy = post
        copy = Post(
            id: copy.id,
            authorId: copy.authorId,
            authorUsername: copy.authorUsername,
            authorDisplayUsername: copy.authorDisplayUsername,
            authorAvatarUrl: copy.authorAvatarUrl,
            fruitCommunityId: copy.fruitCommunityId,
            groupId: copy.groupId,
            contentText: copy.contentText,
            imageUrls: copy.imageUrls,
            visibility: copy.visibility,
            locationText: copy.locationText,
            isAnonymous: copy.isAnonymous,
            pinned: copy.pinned,
            likeCount: likeCount,
            commentCount: copy.commentCount,
            reportCount: copy.reportCount,
            trendingScore: copy.trendingScore,
            createdAt: copy.createdAt,
            updatedAt: copy.updatedAt,
            deletedAt: copy.deletedAt,
            isLikedByCurrentUser: copy.isLikedByCurrentUser
        )
        return copy
    }

    private func postWithCommentCount(_ post: Post, commentCount: Int) -> Post {
        Post(
            id: post.id,
            authorId: post.authorId,
            authorUsername: post.authorUsername,
            authorDisplayUsername: post.authorDisplayUsername,
            authorAvatarUrl: post.authorAvatarUrl,
            fruitCommunityId: post.fruitCommunityId,
            groupId: post.groupId,
            contentText: post.contentText,
            imageUrls: post.imageUrls,
            visibility: post.visibility,
            locationText: post.locationText,
            isAnonymous: post.isAnonymous,
            pinned: post.pinned,
            likeCount: post.likeCount,
            commentCount: commentCount,
            reportCount: post.reportCount,
            trendingScore: post.trendingScore,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            deletedAt: post.deletedAt,
            isLikedByCurrentUser: post.isLikedByCurrentUser
        )
    }
}

@MainActor
public final class MentalHealthViewModel: ObservableObject {
    @Published public private(set) var affirmation: DailyAffirmation?
    @Published public private(set) var todayCheckin: MoodCheckin?
    @Published public private(set) var isLoading = false
    @Published public private(set) var isSaving = false
    @Published public var selectedMood: Mood?
    @Published public var noteText = ""
    @Published public var errorMessage: String?

    private let repository: MentalHealthRepository
    private let calendar: Calendar

    public init(repository: MentalHealthRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    public func loadToday() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            async let affirmationTask = repository.getTodayAffirmation()
            async let checkinTask = repository.fetchTodayMoodCheckin(date: todayDateString)
            let (affirmation, checkin) = try await (affirmationTask, checkinTask)
            self.affirmation = affirmation
            apply(checkin: checkin)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func submitMood() async {
        guard let selectedMood else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await repository.submitMoodCheckin(input: MoodCheckinInput(
                date: todayDateString,
                mood: selectedMood,
                note: trimmedNote
            ))
            apply(checkin: saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(checkin: MoodCheckin?) {
        todayCheckin = checkin
        selectedMood = checkin?.mood ?? selectedMood
        noteText = checkin?.note ?? noteText
    }

    private var trimmedNote: String? {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var todayDateString: String {
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        let components = utcCalendar.dateComponents([.year, .month, .day], from: Date())
        guard let year = components.year, let month = components.month, let day = components.day else {
            return "1970-01-01"
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

@MainActor
public final class NotificationViewModel: ObservableObject {
    @Published public private(set) var notifications: [NotificationItem] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isLoadingMore = false
    @Published public private(set) var hasMore = true
    @Published public var errorMessage: String?

    private let currentUser: User
    private let repository: NotificationRepository
    private let pageSize: Int
    private var nextCursor: Any?

    public init(currentUser: User, repository: NotificationRepository, pageSize: Int = 25) {
        self.currentUser = currentUser
        self.repository = repository
        self.pageSize = pageSize
    }

    public func loadInitial() async {
        guard notifications.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        await load(reset: true)
    }

    public func refresh() async {
        await load(reset: true)
    }

    public func loadMoreIfNeeded(currentNotification: NotificationItem?) async {
        guard hasMore,
              !isLoadingMore,
              let currentNotification,
              currentNotification.id == notifications.last?.id else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await load(reset: false)
    }

    public func markRead(_ notification: NotificationItem) async {
        guard !notification.isRead,
              let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        let original = notifications[index]
        notifications[index] = copy(notification, isRead: true, readAt: Date())

        do {
            try await repository.markNotificationRead(notificationId: notification.id)
        } catch {
            notifications[index] = original
            errorMessage = error.localizedDescription
        }
    }

    private func load(reset: Bool) async {
        do {
            let page = try await repository.fetchNotifications(
                currentUser: currentUser,
                pageSize: pageSize,
                startAfter: reset ? nil : nextCursor
            )
            notifications = reset ? page.notifications : notifications + page.notifications
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func copy(_ notification: NotificationItem, isRead: Bool, readAt: Date?) -> NotificationItem {
        NotificationItem(
            id: notification.id,
            userId: notification.userId,
            fruitCommunityId: notification.fruitCommunityId,
            title: notification.title,
            body: notification.body,
            isRead: isRead,
            createdAt: notification.createdAt,
            readAt: readAt
        )
    }
}
