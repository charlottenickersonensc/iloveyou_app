import Foundation

public struct Friendship: Identifiable, Codable, Equatable {
    public let id: String
    public let userLowId: String
    public let userHighId: String
    public let requesterId: String
    public let receiverId: String
    public let participantIds: [String]
    public let fruitCommunityId: String
    public let status: FriendshipStatus
    public let createdAt: Date
    public let updatedAt: Date
    public let acceptedAt: Date?
    public let blockedAt: Date?

    public init(
        id: String,
        userLowId: String,
        userHighId: String,
        requesterId: String,
        receiverId: String,
        participantIds: [String],
        fruitCommunityId: String,
        status: FriendshipStatus,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        acceptedAt: Date? = nil,
        blockedAt: Date? = nil
    ) {
        self.id = id
        self.userLowId = userLowId
        self.userHighId = userHighId
        self.requesterId = requesterId
        self.receiverId = receiverId
        self.participantIds = participantIds
        self.fruitCommunityId = fruitCommunityId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.acceptedAt = acceptedAt
        self.blockedAt = blockedAt
    }
}

public enum FriendshipStatus: String, Codable, Equatable {
    case pending
    case accepted
    case blocked
}
