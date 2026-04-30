import XCTest
@testable import iLoveYouAppCore

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

private enum TestSocialData {
    static func user(id: String, username: String, fruitCommunityId: String = "apple") -> User {
        User(
            id: id,
            email: "\(username)@example.com",
            username: username,
            displayUsername: username.capitalized,
            dateOfBirth: "2000-01-01",
            fruitCommunityId: fruitCommunityId,
            fruitCode: fruitCommunityId,
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

private struct RecordedFriendResponse: Equatable {
    let friendshipId: String
    let action: FriendRequestAction
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

private enum MockSocialError: LocalizedError {
    case missingResult

    var errorDescription: String? {
        "Missing mock result."
    }
}
