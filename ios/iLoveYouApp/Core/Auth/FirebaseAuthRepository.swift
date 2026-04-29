import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
#endif

public enum AuthRepositoryError: LocalizedError, Equatable {
    case firebaseSDKUnavailable
    case missingAuthenticatedUser
    case notImplemented(String)
    case missingCallableResponse(String)

    public var errorDescription: String? {
        switch self {
        case .firebaseSDKUnavailable:
            return "Firebase SDK is not linked in this build."
        case .missingAuthenticatedUser:
            return "Sign in before continuing."
        case .notImplemented(let feature):
            return "\(feature) needs the Firebase SDK and Xcode capability configuration."
        case .missingCallableResponse(let functionName):
            return "\(functionName) returned an invalid response."
        }
    }
}

public final class FirebaseAuthRepository: AuthRepository {
    public init() {}

    public func signInWithApple() async throws -> FirebaseAuthUser {
        throw AuthRepositoryError.notImplemented("Sign in with Apple")
    }

    public func signInWithApple(token: AppleSignInToken) async throws -> FirebaseAuthUser {
        #if canImport(FirebaseAuth)
        let credential = OAuthProvider.appleCredential(
            withIDToken: token.identityToken,
            rawNonce: token.rawNonce,
            fullName: token.fullName
        )
        let result = try await Auth.auth().signIn(with: credential)
        return FirebaseAuthUser(uid: result.user.uid, email: result.user.email)
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func registerWithEmail(email: String, password: String) async throws -> FirebaseAuthUser {
        try SignupValidators.validateEmail(email)
        try SignupValidators.validatePassword(password)

        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return FirebaseAuthUser(uid: result.user.uid, email: result.user.email)
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func signInWithEmail(email: String, password: String) async throws -> FirebaseAuthUser {
        try SignupValidators.validateEmail(email)

        #if canImport(FirebaseAuth)
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return FirebaseAuthUser(uid: result.user.uid, email: result.user.email)
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func completeSignup(input: CompleteSignupInput) async throws -> User {
        try SignupValidators.validateUsername(input.username)
        try SignupValidators.validateDisplayUsername(input.displayUsername)
        try SignupValidators.validateDateOfBirth(input.dateOfBirth)

        #if canImport(FirebaseFunctions)
        let functions = Functions.functions()
        let payload: [String: Any?] = [
            "username": input.username,
            "displayUsername": input.displayUsername,
            "dateOfBirth": input.dateOfBirth,
            "pronouns": input.pronouns,
            "locationText": input.locationText
        ]
        let result = try await functions.httpsCallable("completeUserSignup").call(payload.compactMapValues { $0 })
        if let user = UserMapper.mapCallableUser(from: result.data) {
            return user
        }
        return try await FirebaseProfileRepository().fetchMe()
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }
}

public final class FirebaseProfileRepository: ProfileRepository {
    public init() {}

    public func fetchMe() async throws -> User {
        #if canImport(FirebaseAuth)
        guard let uid = Auth.auth().currentUser?.uid else {
            throw AuthRepositoryError.missingAuthenticatedUser
        }
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        guard let data = snapshot.data() else {
            throw AuthRepositoryError.missingAuthenticatedUser
        }
        return try UserMapper.map(id: uid, data: data)
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func updateProfile(input: UpdateProfileInput) async throws -> User {
        try ProfileValidators.validate(input: input)

        #if canImport(FirebaseFunctions)
        let payload: [String: Any?] = [
            "displayUsername": input.displayUsername,
            "pronouns": input.pronouns,
            "locationText": input.locationText,
            "bio": input.bio,
            "interests": input.interests,
            "isPrivate": input.isPrivate,
            "avatarUrl": input.avatarUrl?.absoluteString
        ]
        let result = try await Functions.functions().httpsCallable("updateProfile").call(payload.compactMapValues { $0 })
        if let user = UserMapper.mapCallableUser(from: result.data) {
            return user
        }
        return try await fetchMe()
        #else
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }

    public func fetchFruit(id: String) async throws -> FruitCommunity {
        #if canImport(FirebaseFirestore)
        let snapshot = try await Firestore.firestore().collection("fruitCommunities").document(id).getDocument()
        guard let data = snapshot.data() else {
            throw AuthRepositoryError.missingAuthenticatedUser
        }
        return FruitCommunity(
            id: snapshot.documentID,
            code: data["code"] as? String ?? snapshot.documentID,
            name: data["name"] as? String ?? snapshot.documentID.capitalized,
            themeColorHex: data["themeColorHex"] as? String ?? "#D94A38",
            badgeAssetName: data["badgeAssetName"] as? String ?? "fruit_\(snapshot.documentID)",
            wheelIndex: data["wheelIndex"] as? Int ?? 0
        )
        #else
        if let fruit = FruitCommunity.sprintOneSeed.first(where: { $0.id == id }) {
            return fruit
        }
        throw AuthRepositoryError.firebaseSDKUnavailable
        #endif
    }
}

private enum UserMapper {
    static func mapCallableUser(from response: Any) -> User? {
        guard
            let envelope = response as? [String: Any],
            let data = envelope["user"] as? [String: Any],
            let id = data["id"] as? String
        else {
            return nil
        }
        return try? map(id: id, data: data)
    }

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
            memberSince: date(from: data["memberSince"]) ?? Date(),
            profileCompleted: data["profileCompleted"] as? Bool ?? false
        )
    }

    private static func url(from value: Any?) -> URL? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    private static func date(from value: Any?) -> Date? {
        if let date = value as? Date {
            return date
        }
        #if canImport(FirebaseFirestore)
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        #endif
        if let milliseconds = value as? TimeInterval {
            return Date(timeIntervalSince1970: milliseconds / 1_000)
        }
        return nil
    }
}
