import XCTest
@testable import iLoveYouAppCore

final class ViewModelRoutingTests: XCTestCase {
    @MainActor
    func testEmailRegistrationCreatesAuthUserThenCompletesSignup() async {
        let expectedUser = TestData.user(fruitCommunityId: "apple")
        let authRepository = MockAuthRepository()
        authRepository.completeSignupResult = .success(expectedUser)
        let profileRepository = MockProfileRepository()
        var authenticatedUser: User?

        let viewModel = EmailAuthViewModel(
            authRepository: authRepository,
            profileRepository: profileRepository,
            onAuthenticated: { authenticatedUser = $0 }
        )
        viewModel.mode = .register
        viewModel.email = "person@example.com"
        viewModel.password = "abc!"
        viewModel.username = "person_1"
        viewModel.displayUsername = "Person"
        viewModel.dateOfBirth = "2000-01-01"

        await viewModel.submit()

        XCTAssertEqual(authRepository.registeredEmail, "person@example.com")
        XCTAssertEqual(authRepository.completedSignupInput, CompleteSignupInput(
            username: "person_1",
            displayUsername: "Person",
            dateOfBirth: "2000-01-01"
        ))
        XCTAssertEqual(authenticatedUser, expectedUser)
        XCTAssertEqual(profileRepository.fetchMeCallCount, 0)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testEmailRegistrationValidationFailureDoesNotCallRepositories() async {
        let authRepository = MockAuthRepository()
        let profileRepository = MockProfileRepository()

        let viewModel = EmailAuthViewModel(
            authRepository: authRepository,
            profileRepository: profileRepository,
            onAuthenticated: { _ in XCTFail("Should not authenticate invalid registration input.") }
        )
        viewModel.mode = .register
        viewModel.email = "person@example.com"
        viewModel.password = "abc!"
        viewModel.username = "Person"
        viewModel.displayUsername = "Person"
        viewModel.dateOfBirth = "2000-01-01"

        await viewModel.submit()

        XCTAssertNil(authRepository.registeredEmail)
        XCTAssertNil(authRepository.completedSignupInput)
        XCTAssertEqual(profileRepository.fetchMeCallCount, 0)
        XCTAssertEqual(viewModel.errorMessage, ValidationError.invalidUsername.localizedDescription)
    }

    @MainActor
    func testEmailLoginSignsInThenFetchesProfile() async {
        let expectedUser = TestData.user(fruitCommunityId: "banana")
        let authRepository = MockAuthRepository()
        let profileRepository = MockProfileRepository()
        profileRepository.fetchMeResult = .success(expectedUser)
        var authenticatedUser: User?

        let viewModel = EmailAuthViewModel(
            authRepository: authRepository,
            profileRepository: profileRepository,
            onAuthenticated: { authenticatedUser = $0 }
        )
        viewModel.mode = .login
        viewModel.email = "person@example.com"
        viewModel.password = "abc!"

        await viewModel.submit()

        XCTAssertEqual(authRepository.signedInEmail, "person@example.com")
        XCTAssertEqual(profileRepository.fetchMeCallCount, 1)
        XCTAssertEqual(authenticatedUser, expectedUser)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testAppleSignInUsesFirebaseCredentialThenFetchesProfile() async {
        let token = AppleSignInToken(identityToken: "identity-token", rawNonce: "raw-nonce")
        let expectedUser = TestData.user(fruitCommunityId: "cherry")
        let authRepository = MockAuthRepository()
        let profileRepository = MockProfileRepository()
        profileRepository.fetchMeResult = .success(expectedUser)
        var authenticatedUser: User?

        let viewModel = EmailAuthViewModel(
            authRepository: authRepository,
            profileRepository: profileRepository,
            onAuthenticated: { authenticatedUser = $0 }
        )

        await viewModel.signInWithApple(token: token)

        XCTAssertEqual(authRepository.appleToken, token)
        XCTAssertEqual(profileRepository.fetchMeCallCount, 1)
        XCTAssertEqual(authenticatedUser, expectedUser)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testProfileCreationSendsOnlyMutableProfileFields() async {
        let originalUser = TestData.user(
            displayUsername: "Person",
            pronouns: "she/her",
            locationText: "Paris",
            bio: "Original bio",
            interests: ["#music"],
            isPrivate: false,
            fruitCommunityId: "grape"
        )
        let updatedUser = TestData.user(
            displayUsername: "New Person",
            pronouns: nil,
            locationText: nil,
            bio: "Updated bio",
            interests: ["#music", "#books"],
            isPrivate: true,
            fruitCommunityId: "grape"
        )
        let profileRepository = MockProfileRepository()
        profileRepository.updateProfileResult = .success(updatedUser)
        var savedUser: User?

        let viewModel = ProfileCreationViewModel(
            user: originalUser,
            profileRepository: profileRepository,
            onSaved: { savedUser = $0 }
        )
        viewModel.displayUsername = "New Person"
        viewModel.pronouns = "  "
        viewModel.locationText = ""
        viewModel.bio = "Updated bio"
        viewModel.interestsText = "#Music #Books"
        viewModel.isPrivate = true

        await viewModel.save()

        XCTAssertEqual(profileRepository.updatedProfileInput, UpdateProfileInput(
            displayUsername: "New Person",
            pronouns: nil,
            locationText: nil,
            bio: "Updated bio",
            interests: ["#music", "#books"],
            isPrivate: true
        ))
        XCTAssertEqual(savedUser, updatedUser)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testProfileLoadFetchesFruitFromServerAssignedFruitCommunityId() async {
        let initialUser = TestData.user(fruitCommunityId: "apple")
        let fetchedUser = TestData.user(fruitCommunityId: "mango")
        let mango = FruitCommunity(
            id: "mango",
            code: "mango",
            name: "Mango",
            themeColorHex: "#EE8F2E",
            badgeAssetName: "fruit_mango",
            wheelIndex: 6
        )
        let profileRepository = MockProfileRepository()
        profileRepository.fetchMeResult = .success(fetchedUser)
        profileRepository.fruitResults["mango"] = mango

        let viewModel = ProfileViewModel(user: initialUser, profileRepository: profileRepository)

        await viewModel.load()

        XCTAssertEqual(profileRepository.fetchedFruitIds, ["mango"])
        XCTAssertEqual(viewModel.user, fetchedUser)
        XCTAssertEqual(viewModel.fruit, mango)
        XCTAssertNil(viewModel.errorMessage)
    }
}

private enum TestData {
    static func user(
        displayUsername: String = "Person",
        pronouns: String? = nil,
        locationText: String? = nil,
        bio: String? = nil,
        interests: [String] = [],
        isPrivate: Bool = false,
        fruitCommunityId: String
    ) -> User {
        User(
            id: "uid-123",
            email: "person@example.com",
            username: "person_1",
            displayUsername: displayUsername,
            dateOfBirth: "2000-01-01",
            pronouns: pronouns,
            locationText: locationText,
            bio: bio,
            interests: interests,
            isPrivate: isPrivate,
            fruitCommunityId: fruitCommunityId,
            fruitCode: fruitCommunityId,
            memberSince: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}

private enum MockError: LocalizedError {
    case missingResult

    var errorDescription: String? {
        "Missing mock result."
    }
}

private final class MockAuthRepository: AuthRepository {
    var registeredEmail: String?
    var registeredPassword: String?
    var signedInEmail: String?
    var signedInPassword: String?
    var completedSignupInput: CompleteSignupInput?
    var appleToken: AppleSignInToken?
    var completeSignupResult: Result<User, Error> = .failure(MockError.missingResult)

    func signInWithApple() async throws -> FirebaseAuthUser {
        FirebaseAuthUser(uid: "uid-123", email: "person@example.com")
    }

    func signInWithApple(token: AppleSignInToken) async throws -> FirebaseAuthUser {
        appleToken = token
        return FirebaseAuthUser(uid: "uid-123", email: "person@example.com")
    }

    func registerWithEmail(email: String, password: String) async throws -> FirebaseAuthUser {
        registeredEmail = email
        registeredPassword = password
        return FirebaseAuthUser(uid: "uid-123", email: email)
    }

    func signInWithEmail(email: String, password: String) async throws -> FirebaseAuthUser {
        signedInEmail = email
        signedInPassword = password
        return FirebaseAuthUser(uid: "uid-123", email: email)
    }

    func completeSignup(input: CompleteSignupInput) async throws -> User {
        completedSignupInput = input
        return try completeSignupResult.get()
    }

    func signOut() throws {}
}

private final class MockProfileRepository: ProfileRepository {
    var fetchMeCallCount = 0
    var fetchMeResult: Result<User, Error> = .failure(MockError.missingResult)
    var updatedProfileInput: UpdateProfileInput?
    var updateProfileResult: Result<User, Error> = .failure(MockError.missingResult)
    var fruitResults: [String: FruitCommunity] = [:]
    var fetchedFruitIds: [String] = []

    func fetchMe() async throws -> User {
        fetchMeCallCount += 1
        return try fetchMeResult.get()
    }

    func updateProfile(input: UpdateProfileInput) async throws -> User {
        updatedProfileInput = input
        return try updateProfileResult.get()
    }

    func fetchFruit(id: String) async throws -> FruitCommunity {
        fetchedFruitIds.append(id)
        guard let fruit = fruitResults[id] else {
            throw MockError.missingResult
        }
        return fruit
    }
}
