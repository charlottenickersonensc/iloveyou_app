import Foundation

public struct User: Identifiable, Codable, Equatable {
    public let id: String
    public let email: String
    public let username: String
    public let displayUsername: String
    public let dateOfBirth: String
    public let pronouns: String?
    public let locationText: String?
    public let bio: String?
    public let avatarUrl: URL?
    public let interests: [String]
    public let isPrivate: Bool
    public let fruitCommunityId: String
    public let fruitCode: String
    public let role: UserRole
    public let isCaptain: Bool
    public let memberSince: Date
    public let profileCompleted: Bool

    public init(
        id: String,
        email: String,
        username: String,
        displayUsername: String,
        dateOfBirth: String,
        pronouns: String? = nil,
        locationText: String? = nil,
        bio: String? = nil,
        avatarUrl: URL? = nil,
        interests: [String] = [],
        isPrivate: Bool = false,
        fruitCommunityId: String,
        fruitCode: String,
        role: UserRole = .user,
        isCaptain: Bool = false,
        memberSince: Date = Date(),
        profileCompleted: Bool = false
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.displayUsername = displayUsername
        self.dateOfBirth = dateOfBirth
        self.pronouns = pronouns
        self.locationText = locationText
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.interests = interests
        self.isPrivate = isPrivate
        self.fruitCommunityId = fruitCommunityId
        self.fruitCode = fruitCode
        self.role = role
        self.isCaptain = isCaptain
        self.memberSince = memberSince
        self.profileCompleted = profileCompleted
    }
}

public enum UserRole: String, Codable, Equatable {
    case user
    case platformAdmin
    case fruitModerator
}
