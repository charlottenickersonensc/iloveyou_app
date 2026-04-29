import Foundation

public struct NotificationItem: Identifiable, Codable, Equatable {
    public let id: String
    public let userId: String
    public let fruitCommunityId: String
    public let title: String
    public let body: String
    public let isRead: Bool
    public let createdAt: Date
}
