import Combine
import Foundation

@MainActor
public final class FeedViewModel: ObservableObject {
    @Published public private(set) var posts: [Post] = []
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
            posts.insert(post, at: 0)
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
            let page = try await feedRepository.fetchFruitFeed(
                currentUser: currentUser,
                pageSize: pageSize,
                startAfter: reset ? nil : nextCursor
            )
            posts = reset ? page.posts : posts + page.posts
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = error.localizedDescription
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
