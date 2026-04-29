import Foundation

public struct Post: Identifiable, Codable, Equatable {
    public let id: String
    public let authorId: String
    public let fruitCommunityId: String
    public let contentText: String
    public let createdAt: Date
}
