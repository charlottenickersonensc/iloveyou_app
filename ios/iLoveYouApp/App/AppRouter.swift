import Foundation

public enum AppRouter {
    public static func route(for state: AuthState) -> AppRoute {
        switch state {
        case .loading:
            return .launch
        case .signedOut:
            return .onboarding
        case .needsProfileCompletion:
            return .profileCreation
        case .needsFruitReveal:
            return .fruitReveal
        case .signedIn:
            return .profile
        }
    }
}
