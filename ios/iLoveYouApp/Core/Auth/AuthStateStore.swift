import Combine
import Foundation

public enum AuthState: Equatable {
    case loading
    case signedOut
    case needsProfileCompletion(User)
    case needsFruitReveal(User)
    case signedIn(User)
}

@MainActor
public final class AuthStateStore: ObservableObject {
    @Published public private(set) var state: AuthState = .loading

    public let authRepository: AuthRepository
    public let profileRepository: ProfileRepository
    public let feedRepository: FeedRepository
    private let fruitRevealStore: FruitRevealStore

    public init(
        authRepository: AuthRepository = FirebaseAuthRepository(),
        profileRepository: ProfileRepository = FirebaseProfileRepository(),
        feedRepository: FeedRepository = FirebaseFeedRepository(),
        fruitRevealStore: FruitRevealStore = UserDefaultsFruitRevealStore()
    ) {
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.feedRepository = feedRepository
        self.fruitRevealStore = fruitRevealStore
    }

    public func start() async {
        do {
            let user = try await profileRepository.fetchMe()
            route(for: user)
        } catch {
            state = .signedOut
        }
    }

    public func route(for user: User) {
        if !user.profileCompleted {
            state = .needsProfileCompletion(user)
        } else if !fruitRevealStore.hasShownReveal(for: user.id) {
            state = .needsFruitReveal(user)
        } else {
            state = .signedIn(user)
        }
    }

    public func completeFruitReveal(for user: User) {
        fruitRevealStore.setRevealShown(for: user.id)
        state = .signedIn(user)
    }

    public func signOut() {
        do {
            try authRepository.signOut()
        } catch {
            // Sign out errors are non-fatal for routing; Firebase will surface actionable failures in repository tests.
        }
        state = .signedOut
    }
}

public protocol FruitRevealStore {
    func hasShownReveal(for uid: String) -> Bool
    func setRevealShown(for uid: String)
}

public final class UserDefaultsFruitRevealStore: FruitRevealStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func hasShownReveal(for uid: String) -> Bool {
        defaults.bool(forKey: key(for: uid))
    }

    public func setRevealShown(for uid: String) {
        defaults.set(true, forKey: key(for: uid))
    }

    private func key(for uid: String) -> String {
        "fruitRevealShown_\(uid)"
    }
}
