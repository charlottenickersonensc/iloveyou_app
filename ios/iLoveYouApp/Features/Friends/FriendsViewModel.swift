import Combine
import Foundation

public enum FriendRelationshipState: Equatable {
    case none
    case requested
    case respond(Friendship)
    case friends
}

@MainActor
public final class FriendsViewModel: ObservableObject {
    @Published public var searchText = ""
    @Published public private(set) var discoveredPeople: [User] = []
    @Published public private(set) var friends: [User] = []
    @Published public private(set) var pendingRequests: [Friendship] = []
    @Published public private(set) var pendingRequestUsersById: [String: User] = [:]
    @Published public private(set) var isLoading = false
    @Published public private(set) var isSearching = false
    @Published public private(set) var actionInProgressIds: Set<String> = []
    @Published public var errorMessage: String?

    private let currentUser: User
    private let friendsRepository: FriendsRepository
    private var friendshipsByUserId: [String: Friendship] = [:]

    public init(currentUser: User, friendsRepository: FriendsRepository) {
        self.currentUser = currentUser
        self.friendsRepository = friendsRepository
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        await refreshSocialGraph()
        if discoveredPeople.isEmpty {
            await search()
        }
    }

    public func search() async {
        isSearching = true
        defer { isSearching = false }
        do {
            discoveredPeople = try await friendsRepository.searchPeople(
                currentUser: currentUser,
                query: searchText
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func sendRequest(to user: User) async {
        await performAction(id: user.id) {
            let friendship = try await friendsRepository.sendRequest(receiverId: user.id)
            friendshipsByUserId[user.id] = friendship
        }
    }

    public func respond(to friendship: Friendship, action: FriendRequestAction) async {
        await performAction(id: friendship.id) {
            let updatedFriendship = try await friendsRepository.respond(
                friendshipId: friendship.id,
                action: action
            )
            if let requesterId = otherParticipantId(in: friendship) {
                if let updatedFriendship {
                    friendshipsByUserId[requesterId] = updatedFriendship
                } else {
                    friendshipsByUserId.removeValue(forKey: requesterId)
                }
            }
            await refreshSocialGraph()
        }
    }

    public func relationshipState(for user: User) -> FriendRelationshipState {
        guard let friendship = friendshipsByUserId[user.id] else {
            return .none
        }
        switch friendship.status {
        case .accepted:
            return .friends
        case .pending where friendship.receiverId == currentUser.id:
            return .respond(friendship)
        case .pending:
            return .requested
        case .blocked:
            return .none
        }
    }

    public func requester(for friendship: Friendship) -> User? {
        pendingRequestUsersById[friendship.requesterId]
    }

    private func refreshSocialGraph() async {
        do {
            async let friendsTask = friendsRepository.fetchFriends(currentUser: currentUser)
            async let pendingTask = friendsRepository.fetchPendingRequests(currentUser: currentUser)
            async let friendshipsTask = friendsRepository.fetchFriendships(currentUser: currentUser)

            let (friends, pendingRequests, friendships) = try await (friendsTask, pendingTask, friendshipsTask)
            self.friends = friends
            self.pendingRequests = pendingRequests
            rebuildFriendshipLookup(from: friendships)
            try await loadRequestUsers(for: pendingRequests)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadRequestUsers(for pendingRequests: [Friendship]) async throws {
        let users = try await friendsRepository.fetchUsers(ids: pendingRequests.map(\.requesterId))
        pendingRequestUsersById = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
    }

    private func rebuildFriendshipLookup(from friendships: [Friendship]) {
        friendshipsByUserId = Dictionary(uniqueKeysWithValues: friendships.compactMap { friendship in
            guard let otherUserId = otherParticipantId(in: friendship) else { return nil }
            return (otherUserId, friendship)
        })
    }

    private func performAction(id: String, operation: () async throws -> Void) async {
        actionInProgressIds.insert(id)
        defer { actionInProgressIds.remove(id) }
        do {
            try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func otherParticipantId(in friendship: Friendship) -> String? {
        friendship.participantIds.first { $0 != currentUser.id }
    }
}
