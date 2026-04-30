import XCTest
@testable import iLoveYouAppCore

final class FeedViewModelTests: XCTestCase {
    @MainActor
    func testInitialLoadUsesFruitFeed() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let fruitPost = TestFeedData.post(id: "fruit-post", fruitCommunityId: currentUser.fruitCommunityId)
        let repository = MockFeedRepository()
        repository.fruitPages = [
            FeedPage(posts: [fruitPost], nextCursor: "fruit-cursor", hasMore: true)
        ]
        let viewModel = FeedViewModel(currentUser: currentUser, feedRepository: repository, pageSize: 1)

        await viewModel.loadInitial()

        XCTAssertEqual(repository.fruitFetches, [
            RecordedFeedFetch(userId: currentUser.id, fruitCommunityId: "apple", pageSize: 1, startAfter: nil)
        ])
        XCTAssertTrue(repository.trendingFetches.isEmpty)
        XCTAssertEqual(viewModel.feedMode, .fruit)
        XCTAssertEqual(viewModel.posts, [fruitPost])
        XCTAssertTrue(viewModel.hasMore)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testInitialLoadIgnoresDuplicateInFlightRequest() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let fruitPost = TestFeedData.post(id: "fruit-post", fruitCommunityId: currentUser.fruitCommunityId)
        let repository = MockFeedRepository()
        repository.fetchDelayNanos = 50_000_000
        repository.fruitPages = [
            FeedPage(posts: [fruitPost], nextCursor: nil, hasMore: false)
        ]
        let viewModel = FeedViewModel(currentUser: currentUser, feedRepository: repository, pageSize: 10)

        async let firstLoad: Void = viewModel.loadInitial()
        async let duplicateLoad: Void = viewModel.loadInitial()
        _ = await (firstLoad, duplicateLoad)

        XCTAssertEqual(repository.fruitFetches.count, 1)
        XCTAssertEqual(viewModel.posts, [fruitPost])
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testSelectingTrendingLoadsTrendingFeedAndClearsFruitPosts() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let fruitPost = TestFeedData.post(id: "fruit-post", fruitCommunityId: currentUser.fruitCommunityId)
        let trendingPost = TestFeedData.post(
            id: "trending-post",
            fruitCommunityId: currentUser.fruitCommunityId,
            likeCount: 5,
            commentCount: 2,
            trendingScore: 16
        )
        let repository = MockFeedRepository()
        repository.fruitPages = [
            FeedPage(posts: [fruitPost], nextCursor: nil, hasMore: false)
        ]
        repository.trendingPages = [
            FeedPage(posts: [trendingPost], nextCursor: "trending-cursor", hasMore: true)
        ]
        let viewModel = FeedViewModel(currentUser: currentUser, feedRepository: repository, pageSize: 10)

        await viewModel.loadInitial()
        await viewModel.selectFeedMode(.trending)

        XCTAssertEqual(repository.trendingFetches, [
            RecordedFeedFetch(userId: currentUser.id, fruitCommunityId: "apple", pageSize: 10, startAfter: nil)
        ])
        XCTAssertEqual(viewModel.feedMode, .trending)
        XCTAssertEqual(viewModel.posts, [trendingPost])
        XCTAssertTrue(viewModel.hasMore)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testTrendingPaginationUsesTrendingCursor() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let firstPost = TestFeedData.post(id: "trending-1", fruitCommunityId: currentUser.fruitCommunityId)
        let secondPost = TestFeedData.post(id: "trending-2", fruitCommunityId: currentUser.fruitCommunityId)
        let repository = MockFeedRepository()
        repository.trendingPages = [
            FeedPage(posts: [firstPost], nextCursor: "cursor-1", hasMore: true),
            FeedPage(posts: [secondPost], nextCursor: nil, hasMore: false)
        ]
        let viewModel = FeedViewModel(currentUser: currentUser, feedRepository: repository, pageSize: 1)

        await viewModel.selectFeedMode(.trending)
        await viewModel.loadMoreIfNeeded(currentPost: firstPost)

        XCTAssertEqual(repository.trendingFetches, [
            RecordedFeedFetch(userId: currentUser.id, fruitCommunityId: "apple", pageSize: 1, startAfter: nil),
            RecordedFeedFetch(userId: currentUser.id, fruitCommunityId: "apple", pageSize: 1, startAfter: "cursor-1")
        ])
        XCTAssertEqual(viewModel.posts, [firstPost, secondPost])
        XCTAssertFalse(viewModel.hasMore)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testCaptainCanPinPostAndPinnedPostsSortFirst() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current", isCaptain: true)
        let olderPost = TestFeedData.post(
            id: "older-post",
            fruitCommunityId: currentUser.fruitCommunityId,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let newerPost = TestFeedData.post(
            id: "newer-post",
            fruitCommunityId: currentUser.fruitCommunityId,
            createdAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let repository = MockFeedRepository()
        repository.fruitPages = [
            FeedPage(posts: [newerPost, olderPost], nextCursor: nil, hasMore: false)
        ]
        repository.pinResults = [
            TestFeedData.post(
                id: "older-post",
                fruitCommunityId: currentUser.fruitCommunityId,
                pinned: true,
                createdAt: olderPost.createdAt
            )
        ]
        let viewModel = FeedViewModel(currentUser: currentUser, feedRepository: repository)

        await viewModel.loadInitial()
        await viewModel.setPinned(true, for: olderPost)

        XCTAssertTrue(viewModel.canPinPosts)
        XCTAssertEqual(repository.pinRequests, [RecordedPinRequest(postId: "older-post", pinned: true)])
        XCTAssertEqual(viewModel.posts.map(\.id), ["older-post", "newer-post"])
        XCTAssertEqual(viewModel.posts.first?.pinned, true)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testNonCaptainPinActionDoesNotCallRepository() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let post = TestFeedData.post(id: "post-1", fruitCommunityId: currentUser.fruitCommunityId)
        let repository = MockFeedRepository()
        repository.fruitPages = [
            FeedPage(posts: [post], nextCursor: nil, hasMore: false)
        ]
        let viewModel = FeedViewModel(currentUser: currentUser, feedRepository: repository)

        await viewModel.loadInitial()
        await viewModel.setPinned(true, for: post)

        XCTAssertFalse(viewModel.canPinPosts)
        XCTAssertTrue(repository.pinRequests.isEmpty)
        XCTAssertEqual(viewModel.posts, [post])
        XCTAssertNil(viewModel.errorMessage)
    }
}

final class FriendsViewModelTests: XCTestCase {
    @MainActor
    func testLoadFetchesFriendsRequestsAndRelationshipStates() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let acceptedFriend = TestSocialData.user(id: "uid-friend", username: "friend")
        let requester = TestSocialData.user(id: "uid-requester", username: "requester")
        let requested = TestSocialData.user(id: "uid-requested", username: "requested")
        let stranger = TestSocialData.user(id: "uid-stranger", username: "stranger")

        let acceptedFriendship = TestSocialData.friendship(
            currentUserId: currentUser.id,
            otherUserId: acceptedFriend.id,
            requesterId: acceptedFriend.id,
            receiverId: currentUser.id,
            status: .accepted
        )
        let incomingRequest = TestSocialData.friendship(
            currentUserId: currentUser.id,
            otherUserId: requester.id,
            requesterId: requester.id,
            receiverId: currentUser.id,
            status: .pending
        )
        let outgoingRequest = TestSocialData.friendship(
            currentUserId: currentUser.id,
            otherUserId: requested.id,
            requesterId: currentUser.id,
            receiverId: requested.id,
            status: .pending
        )

        let repository = MockFriendsRepository()
        repository.friendsResult = .success([acceptedFriend])
        repository.pendingRequestsResult = .success([incomingRequest])
        repository.friendshipsResult = .success([acceptedFriendship, incomingRequest, outgoingRequest])
        repository.usersById[requester.id] = requester
        repository.searchResults = .success([acceptedFriend, requester, requested, stranger])

        let viewModel = FriendsViewModel(currentUser: currentUser, friendsRepository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.friends, [acceptedFriend])
        XCTAssertEqual(viewModel.pendingRequests, [incomingRequest])
        XCTAssertEqual(viewModel.requester(for: incomingRequest), requester)
        XCTAssertEqual(viewModel.discoveredPeople, [acceptedFriend, requester, requested, stranger])
        XCTAssertEqual(viewModel.relationshipState(for: acceptedFriend), .friends)
        XCTAssertEqual(viewModel.relationshipState(for: requester), .respond(incomingRequest))
        XCTAssertEqual(viewModel.relationshipState(for: requested), .requested)
        XCTAssertEqual(viewModel.relationshipState(for: stranger), .none)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testSendRequestPassesReceiverOnlyAndUpdatesRelationshipState() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let target = TestSocialData.user(id: "uid-target", username: "target")
        let pendingFriendship = TestSocialData.friendship(
            currentUserId: currentUser.id,
            otherUserId: target.id,
            requesterId: currentUser.id,
            receiverId: target.id,
            status: .pending
        )
        let repository = MockFriendsRepository()
        repository.sendRequestResult = .success(pendingFriendship)
        let viewModel = FriendsViewModel(currentUser: currentUser, friendsRepository: repository)

        await viewModel.sendRequest(to: target)

        XCTAssertEqual(repository.sentReceiverIds, [target.id])
        XCTAssertEqual(viewModel.relationshipState(for: target), .requested)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testAcceptRequestRefreshesFriendsList() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let requester = TestSocialData.user(id: "uid-requester", username: "requester")
        let incomingRequest = TestSocialData.friendship(
            currentUserId: currentUser.id,
            otherUserId: requester.id,
            requesterId: requester.id,
            receiverId: currentUser.id,
            status: .pending
        )
        let acceptedFriendship = TestSocialData.friendship(
            currentUserId: currentUser.id,
            otherUserId: requester.id,
            requesterId: requester.id,
            receiverId: currentUser.id,
            status: .accepted
        )
        let repository = MockFriendsRepository()
        repository.respondResult = .success(acceptedFriendship)
        repository.friendsResult = .success([requester])
        repository.pendingRequestsResult = .success([])
        repository.friendshipsResult = .success([acceptedFriendship])

        let viewModel = FriendsViewModel(currentUser: currentUser, friendsRepository: repository)

        await viewModel.respond(to: incomingRequest, action: .accept)

        XCTAssertEqual(repository.responses, [RecordedFriendResponse(
            friendshipId: incomingRequest.id,
            action: .accept
        )])
        XCTAssertEqual(viewModel.friends, [requester])
        XCTAssertEqual(viewModel.relationshipState(for: requester), .friends)
        XCTAssertNil(viewModel.errorMessage)
    }
}

final class MentalHealthViewModelTests: XCTestCase {
    @MainActor
    func testLoadTodayFetchesAffirmationAndExistingMood() async {
        let repository = MockMentalHealthRepository()
        repository.affirmationResult = .success(TestMentalHealthData.affirmation(text: "Small steps count."))
        repository.fetchCheckinResult = .success(TestMentalHealthData.checkin(mood: .low, note: "Tired"))
        let viewModel = MentalHealthViewModel(repository: repository)

        await viewModel.loadToday()

        XCTAssertEqual(viewModel.affirmation?.text, "Small steps count.")
        XCTAssertEqual(viewModel.todayCheckin?.mood, .low)
        XCTAssertEqual(viewModel.selectedMood, .low)
        XCTAssertEqual(viewModel.noteText, "Tired")
        XCTAssertEqual(repository.fetchedDates.count, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testSubmitMoodSendsOnlyDateMoodAndNote() async {
        let repository = MockMentalHealthRepository()
        repository.submitResult = .success(TestMentalHealthData.checkin(mood: .good, note: "Better"))
        let viewModel = MentalHealthViewModel(repository: repository)
        viewModel.selectedMood = .good
        viewModel.noteText = "  Better  "

        await viewModel.submitMood()

        XCTAssertEqual(repository.submittedInputs.count, 1)
        XCTAssertEqual(repository.submittedInputs[0].mood, .good)
        XCTAssertEqual(repository.submittedInputs[0].note, "Better")
        XCTAssertEqual(viewModel.todayCheckin?.mood, .good)
        XCTAssertEqual(viewModel.noteText, "Better")
        XCTAssertNil(viewModel.errorMessage)
    }
}

final class NotificationViewModelTests: XCTestCase {
    @MainActor
    func testLoadFetchesCurrentUserFruitNotifications() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let notification = TestNotificationData.notification(id: "note-1", userId: currentUser.id)
        let repository = MockNotificationRepository()
        repository.pages = [
            NotificationPage(notifications: [notification], nextCursor: "cursor-1", hasMore: true)
        ]
        let viewModel = NotificationViewModel(currentUser: currentUser, repository: repository, pageSize: 1)

        await viewModel.loadInitial()

        XCTAssertEqual(repository.fetches, [
            RecordedNotificationFetch(userId: currentUser.id, fruitCommunityId: "apple", pageSize: 1, startAfter: nil)
        ])
        XCTAssertEqual(viewModel.notifications, [notification])
        XCTAssertTrue(viewModel.hasMore)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testMarkReadSendsOnlyNotificationIdAndUpdatesLocalState() async {
        let currentUser = TestSocialData.user(id: "uid-current", username: "current")
        let notification = TestNotificationData.notification(id: "note-1", userId: currentUser.id)
        let repository = MockNotificationRepository()
        repository.pages = [
            NotificationPage(notifications: [notification], nextCursor: nil, hasMore: false)
        ]
        let viewModel = NotificationViewModel(currentUser: currentUser, repository: repository)

        await viewModel.loadInitial()
        await viewModel.markRead(notification)

        XCTAssertEqual(repository.markedNotificationIds, ["note-1"])
        XCTAssertEqual(viewModel.notifications.first?.isRead, true)
        XCTAssertNotNil(viewModel.notifications.first?.readAt)
        XCTAssertNil(viewModel.errorMessage)
    }
}

private enum TestSocialData {
    static func user(
        id: String,
        username: String,
        fruitCommunityId: String = "apple",
        isCaptain: Bool = false
    ) -> User {
        User(
            id: id,
            email: "\(username)@example.com",
            username: username,
            displayUsername: username.capitalized,
            dateOfBirth: "2000-01-01",
            fruitCommunityId: fruitCommunityId,
            fruitCode: fruitCommunityId,
            isCaptain: isCaptain,
            memberSince: Date(timeIntervalSince1970: 1_700_000_000),
            profileCompleted: true
        )
    }

    static func friendship(
        currentUserId: String,
        otherUserId: String,
        requesterId: String,
        receiverId: String,
        status: FriendshipStatus
    ) -> Friendship {
        let sortedIds = [currentUserId, otherUserId].sorted()
        return Friendship(
            id: "\(sortedIds[0])_\(sortedIds[1])",
            userLowId: sortedIds[0],
            userHighId: sortedIds[1],
            requesterId: requesterId,
            receiverId: receiverId,
            participantIds: sortedIds,
            fruitCommunityId: "apple",
            status: status,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100),
            acceptedAt: status == .accepted ? Date(timeIntervalSince1970: 1_700_000_100) : nil
        )
    }
}

private enum TestMentalHealthData {
    static func checkin(mood: Mood, note: String?) -> MoodCheckin {
        MoodCheckin(
            id: "uid-current_20260430",
            userId: "uid-current",
            fruitCommunityId: "apple",
            date: "2026-04-30",
            mood: mood,
            note: note,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
    }

    static func affirmation(text: String) -> DailyAffirmation {
        DailyAffirmation(
            id: "2026-04-30",
            date: "2026-04-30",
            text: text,
            active: true,
            source: "scheduled"
        )
    }
}

private enum TestNotificationData {
    static func notification(id: String, userId: String, isRead: Bool = false) -> NotificationItem {
        NotificationItem(
            id: id,
            userId: userId,
            fruitCommunityId: "apple",
            title: "New like",
            body: "Someone liked your post.",
            isRead: isRead,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            readAt: nil
        )
    }
}

private enum TestFeedData {
    static func post(
        id: String,
        fruitCommunityId: String,
        pinned: Bool = false,
        likeCount: Int = 0,
        commentCount: Int = 0,
        trendingScore: Int = 0,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> Post {
        Post(
            id: id,
            authorId: "uid-author",
            authorUsername: "author",
            authorDisplayUsername: "Author",
            fruitCommunityId: fruitCommunityId,
            contentText: "Post \(id)",
            pinned: pinned,
            likeCount: likeCount,
            commentCount: commentCount,
            trendingScore: trendingScore,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}

private struct RecordedFeedFetch: Equatable {
    let userId: String
    let fruitCommunityId: String
    let pageSize: Int
    let startAfter: String?
}

private struct RecordedFriendResponse: Equatable {
    let friendshipId: String
    let action: FriendRequestAction
}

private struct RecordedNotificationFetch: Equatable {
    let userId: String
    let fruitCommunityId: String
    let pageSize: Int
    let startAfter: String?
}

private struct RecordedPinRequest: Equatable {
    let postId: String
    let pinned: Bool
}

private final class MockFeedRepository: FeedRepository {
    var fruitPages: [FeedPage] = []
    var trendingPages: [FeedPage] = []
    var fruitFetches: [RecordedFeedFetch] = []
    var trendingFetches: [RecordedFeedFetch] = []
    var createPostInputs: [CreatePostInput] = []
    var pinRequests: [RecordedPinRequest] = []
    var pinResults: [Post] = []
    var fetchDelayNanos: UInt64 = 0

    func fetchFruitFeed(currentUser: User, pageSize: Int, startAfter: Any?) async throws -> FeedPage {
        if fetchDelayNanos > 0 {
            try await Task.sleep(nanoseconds: fetchDelayNanos)
        }
        fruitFetches.append(RecordedFeedFetch(
            userId: currentUser.id,
            fruitCommunityId: currentUser.fruitCommunityId,
            pageSize: pageSize,
            startAfter: startAfter as? String
        ))
        guard !fruitPages.isEmpty else { throw MockSocialError.missingResult }
        return fruitPages.removeFirst()
    }

    func fetchTrendingFeed(currentUser: User, pageSize: Int, startAfter: Any?) async throws -> FeedPage {
        trendingFetches.append(RecordedFeedFetch(
            userId: currentUser.id,
            fruitCommunityId: currentUser.fruitCommunityId,
            pageSize: pageSize,
            startAfter: startAfter as? String
        ))
        guard !trendingPages.isEmpty else { throw MockSocialError.missingResult }
        return trendingPages.removeFirst()
    }

    func createPost(input: CreatePostInput) async throws -> Post {
        createPostInputs.append(input)
        return TestFeedData.post(id: "created-post", fruitCommunityId: "apple")
    }

    func uploadPostImages(_ images: [PostImageUpload], draftPostId: String) async throws -> [URL] {
        []
    }

    func toggleLike(postId: String) async throws -> LikeResult {
        LikeResult(liked: true, likeCount: 1)
    }

    func pinPost(postId: String, pinned: Bool) async throws -> Post {
        pinRequests.append(RecordedPinRequest(postId: postId, pinned: pinned))
        guard !pinResults.isEmpty else { throw MockSocialError.missingResult }
        return pinResults.removeFirst()
    }

    func createComment(postId: String, contentText: String) async throws -> PostComment {
        PostComment(
            id: "comment-1",
            postId: postId,
            authorId: "uid-current",
            authorDisplayUsername: "Current",
            authorAvatarUrl: nil,
            fruitCommunityId: "apple",
            contentText: contentText,
            reportCount: 0,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            deletedAt: nil
        )
    }

    func reportContent(input: ReportContentInput) async throws {}
}

private final class MockFriendsRepository: FriendsRepository {
    var searchQueries: [String] = []
    var searchResults: Result<[User], Error> = .success([])
    var sentReceiverIds: [String] = []
    var sendRequestResult: Result<Friendship, Error> = .failure(MockSocialError.missingResult)
    var responses: [RecordedFriendResponse] = []
    var respondResult: Result<Friendship?, Error> = .success(nil)
    var friendsResult: Result<[User], Error> = .success([])
    var pendingRequestsResult: Result<[Friendship], Error> = .success([])
    var friendshipsResult: Result<[Friendship], Error> = .success([])
    var usersById: [String: User] = [:]

    func searchPeople(currentUser: User, query: String) async throws -> [User] {
        searchQueries.append(query)
        return try searchResults.get()
    }

    func sendRequest(receiverId: String) async throws -> Friendship {
        sentReceiverIds.append(receiverId)
        return try sendRequestResult.get()
    }

    func respond(friendshipId: String, action: FriendRequestAction) async throws -> Friendship? {
        responses.append(RecordedFriendResponse(friendshipId: friendshipId, action: action))
        return try respondResult.get()
    }

    func fetchFriends(currentUser: User) async throws -> [User] {
        try friendsResult.get()
    }

    func fetchPendingRequests(currentUser: User) async throws -> [Friendship] {
        try pendingRequestsResult.get()
    }

    func fetchFriendships(currentUser: User) async throws -> [Friendship] {
        try friendshipsResult.get()
    }

    func fetchUsers(ids: [String]) async throws -> [User] {
        ids.compactMap { usersById[$0] }
    }
}

private final class MockMentalHealthRepository: MentalHealthRepository {
    var fetchedDates: [String] = []
    var fetchCheckinResult: Result<MoodCheckin?, Error> = .success(nil)
    var submittedInputs: [MoodCheckinInput] = []
    var submitResult: Result<MoodCheckin, Error> = .failure(MockSocialError.missingResult)
    var affirmationResult: Result<DailyAffirmation, Error> = .failure(MockSocialError.missingResult)

    func fetchTodayMoodCheckin(date: String) async throws -> MoodCheckin? {
        fetchedDates.append(date)
        return try fetchCheckinResult.get()
    }

    func submitMoodCheckin(input: MoodCheckinInput) async throws -> MoodCheckin {
        submittedInputs.append(input)
        return try submitResult.get()
    }

    func getTodayAffirmation() async throws -> DailyAffirmation {
        try affirmationResult.get()
    }
}

private final class MockNotificationRepository: NotificationRepository {
    var pages: [NotificationPage] = []
    var fetches: [RecordedNotificationFetch] = []
    var markedNotificationIds: [String] = []

    func fetchNotifications(currentUser: User, pageSize: Int, startAfter: Any?) async throws -> NotificationPage {
        fetches.append(RecordedNotificationFetch(
            userId: currentUser.id,
            fruitCommunityId: currentUser.fruitCommunityId,
            pageSize: pageSize,
            startAfter: startAfter as? String
        ))
        guard !pages.isEmpty else { throw MockSocialError.missingResult }
        return pages.removeFirst()
    }

    func markNotificationRead(notificationId: String) async throws {
        markedNotificationIds.append(notificationId)
    }
}

private enum MockSocialError: LocalizedError {
    case missingResult

    var errorDescription: String? {
        "Missing mock result."
    }
}
