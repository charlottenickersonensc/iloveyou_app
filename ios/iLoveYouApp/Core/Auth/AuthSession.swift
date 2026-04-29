import Foundation

public struct FirebaseAuthUser: Equatable {
    public let uid: String
    public let email: String?

    public init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
}

public struct AppleSignInToken: Equatable {
    public let identityToken: String
    public let rawNonce: String
    public let fullName: PersonNameComponents?

    public init(identityToken: String, rawNonce: String, fullName: PersonNameComponents? = nil) {
        self.identityToken = identityToken
        self.rawNonce = rawNonce
        self.fullName = fullName
    }
}

public struct CompleteSignupInput: Equatable {
    public var username: String
    public var displayUsername: String
    public var dateOfBirth: String
    public var pronouns: String?
    public var locationText: String?

    public init(username: String, displayUsername: String, dateOfBirth: String, pronouns: String? = nil, locationText: String? = nil) {
        self.username = username
        self.displayUsername = displayUsername
        self.dateOfBirth = dateOfBirth
        self.pronouns = pronouns
        self.locationText = locationText
    }
}

public struct UpdateProfileInput: Equatable {
    public var displayUsername: String
    public var pronouns: String?
    public var locationText: String?
    public var bio: String?
    public var interests: [String]
    public var isPrivate: Bool
    public var avatarUrl: URL?

    public init(displayUsername: String, pronouns: String?, locationText: String?, bio: String?, interests: [String], isPrivate: Bool, avatarUrl: URL? = nil) {
        self.displayUsername = displayUsername
        self.pronouns = pronouns
        self.locationText = locationText
        self.bio = bio
        self.interests = interests
        self.isPrivate = isPrivate
        self.avatarUrl = avatarUrl
    }
}

public protocol AuthRepository {
    func signInWithApple() async throws -> FirebaseAuthUser
    func signInWithApple(token: AppleSignInToken) async throws -> FirebaseAuthUser
    func registerWithEmail(email: String, password: String) async throws -> FirebaseAuthUser
    func signInWithEmail(email: String, password: String) async throws -> FirebaseAuthUser
    func completeSignup(input: CompleteSignupInput) async throws -> User
    func signOut() throws
}

public protocol ProfileRepository {
    func fetchMe() async throws -> User
    func updateProfile(input: UpdateProfileInput) async throws -> User
    func fetchFruit(id: String) async throws -> FruitCommunity
}
