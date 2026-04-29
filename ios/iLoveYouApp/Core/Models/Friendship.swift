import Foundation

public struct Friendship: Identifiable, Codable, Equatable {
    public let id: String
    public let requesterId: String
    public let receiverId: String
    public let fruitCommunityId: String
    public let status: FriendshipStatus
}

public enum FriendshipStatus: String, Codable, Equatable {
    case pending
    case accepted
    case blocked
}
