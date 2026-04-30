import Foundation

#if canImport(FirebaseAuth)
import FirebaseFirestore
import FirebaseFunctions
#endif

public final class FirebaseFriendsRepository: FriendsRepository {
    public init() {}

    public func searchPeople(currentUser: User, query: String) async throws -> [User] {
        #if canImport(FirebaseFirestore)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var firestoreQuery: Query = Firestore.firestore().collection("users")
            .whereField("fruitCommunityId", isEqualTo: currentUser.fruitCommunityId)
            .order(by: "username")
            .limit(to: 25)

        if !trimmedQuery.isEmpty {
            firestoreQuery = firestoreQuery
                .whereField("username", isGreaterThanOrEqualTo: trimmedQuery)
                .whereField("username", isLessThan: "\(trimmedQuery)\u{f8ff}")
        }

        let snapshot = try await firestoreQuery.getDocuments()
        return snapshot.documents.compactMap { document in
            guard document.documentID != currentUser.id else { return nil }
            return try? UserFirestoreMapper.map(id: document.documentID, data: document.data())
        }
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func sendRequest(receiverId: String) async throws -> Friendship {
        #if canImport(FirebaseFunctions)
        let result = try await Functions.functions().httpsCallable("sendFriendRequest").call([
            "receiverId": receiverId
        ])
        guard let friendship = FriendshipMapper.mapCallableFriendship(from: result.data) else {
            throw AuthRepositoryError.missingCallableResponse("sendFriendRequest")
        }
        return friendship
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func respond(friendshipId: String, action: FriendRequestAction) async throws -> Friendship? {
        #if canImport(FirebaseFunctions)
        let result = try await Functions.functions().httpsCallable("respondToFriendRequest").call([
            "friendshipId": friendshipId,
            "action": action.rawValue
        ])
        return FriendshipMapper.mapCallableFriendship(from: result.data)
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func fetchFriends(currentUser: User) async throws -> [User] {
        let friendships = try await fetchFriendships(currentUser: currentUser)
            .filter { $0.status == .accepted }
        let friendIds = friendships.compactMap { friendship in
            otherParticipantId(in: friendship, currentUserId: currentUser.id)
        }
        return try await fetchUsers(ids: friendIds)
            .filter { $0.fruitCommunityId == currentUser.fruitCommunityId }
            .sorted { $0.username < $1.username }
    }

    public func fetchPendingRequests(currentUser: User) async throws -> [Friendship] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await Firestore.firestore().collection("friendships")
            .whereField("receiverId", isEqualTo: currentUser.id)
            .whereField("status", isEqualTo: FriendshipStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            try? FriendshipMapper.map(id: document.documentID, data: document.data())
        }
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func fetchFriendships(currentUser: User) async throws -> [Friendship] {
        #if canImport(FirebaseFirestore)
        let snapshot = try await Firestore.firestore().collection("friendships")
            .whereField("participantIds", arrayContains: currentUser.id)
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            try? FriendshipMapper.map(id: document.documentID, data: document.data())
        }
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func fetchUsers(ids: [String]) async throws -> [User] {
        #if canImport(FirebaseFirestore)
        let uniqueIds = Array(Set(ids)).filter { !$0.isEmpty }
        guard !uniqueIds.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: User?.self) { group in
            for id in uniqueIds {
                group.addTask {
                    let document = try await Firestore.firestore().collection("users").document(id).getDocument()
                    guard let data = document.data() else { return nil }
                    return try UserFirestoreMapper.map(id: document.documentID, data: data)
                }
            }

            var users: [User] = []
            for try await user in group {
                if let user {
                    users.append(user)
                }
            }
            return users
        }
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    private func otherParticipantId(in friendship: Friendship, currentUserId: String) -> String? {
        friendship.participantIds.first { $0 != currentUserId }
    }
}

private enum FriendshipMapper {
    static func mapCallableFriendship(from response: Any) -> Friendship? {
        guard let envelope = response as? [String: Any],
              let data = envelope["friendship"] as? [String: Any],
              let id = data["id"] as? String else {
            return nil
        }
        return try? map(id: id, data: data)
    }

    static func map(id: String, data: [String: Any]) throws -> Friendship {
        Friendship(
            id: id,
            userLowId: data["userLowId"] as? String ?? "",
            userHighId: data["userHighId"] as? String ?? "",
            requesterId: data["requesterId"] as? String ?? "",
            receiverId: data["receiverId"] as? String ?? "",
            participantIds: data["participantIds"] as? [String] ?? [],
            fruitCommunityId: data["fruitCommunityId"] as? String ?? "",
            status: FriendshipStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
            createdAt: FirestoreDateMapper.date(from: data["createdAt"]) ?? Date(),
            updatedAt: FirestoreDateMapper.date(from: data["updatedAt"]) ?? Date(),
            acceptedAt: FirestoreDateMapper.date(from: data["acceptedAt"]),
            blockedAt: FirestoreDateMapper.date(from: data["blockedAt"])
        )
    }
}

private enum UserFirestoreMapper {
    static func map(id: String, data: [String: Any]) throws -> User {
        User(
            id: id,
            email: data["email"] as? String ?? "",
            username: data["username"] as? String ?? "",
            displayUsername: data["displayUsername"] as? String ?? "",
            dateOfBirth: data["dateOfBirth"] as? String ?? "",
            pronouns: data["pronouns"] as? String,
            locationText: data["locationText"] as? String,
            bio: data["bio"] as? String,
            avatarUrl: url(from: data["avatarUrl"]),
            interests: data["interests"] as? [String] ?? [],
            isPrivate: data["isPrivate"] as? Bool ?? false,
            fruitCommunityId: data["fruitCommunityId"] as? String ?? "",
            fruitCode: data["fruitCode"] as? String ?? "",
            role: UserRole(rawValue: data["role"] as? String ?? "user") ?? .user,
            isCaptain: data["isCaptain"] as? Bool ?? false,
            memberSince: FirestoreDateMapper.date(from: data["memberSince"]) ?? Date(),
            profileCompleted: data["profileCompleted"] as? Bool ?? false
        )
    }

    private static func url(from value: Any?) -> URL? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return URL(string: string)
    }
}

private enum FirestoreDateMapper {
    static func date(from value: Any?) -> Date? {
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
