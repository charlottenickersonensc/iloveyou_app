import SwiftUI

public struct AppRootView: View {
    @EnvironmentObject private var authStateStore: AuthStateStore

    public init() {}

    public var body: some View {
        Group {
            switch authStateStore.state {
            case .loading:
                ProgressView()
            case .signedOut:
                EmailAuthView(viewModel: EmailAuthViewModel(
                    authRepository: authStateStore.authRepository,
                    profileRepository: authStateStore.profileRepository,
                    onAuthenticated: { user in authStateStore.route(for: user) }
                ))
            case .needsProfileCompletion(let user):
                ProfileCreationView(viewModel: ProfileCreationViewModel(
                    user: user,
                    profileRepository: authStateStore.profileRepository,
                    onSaved: { user in authStateStore.route(for: user) }
                ))
            case .needsFruitReveal(let user):
                FruitRevealView(viewModel: FruitRevealViewModel(user: user))
            case .signedIn(let user):
                TabView {
                    FeedView(viewModel: FeedViewModel(
                        currentUser: user,
                        feedRepository: authStateStore.feedRepository
                    ))
                    .tabItem {
                        Label("Feed", systemImage: "text.bubble")
                    }

                    ProfileView(viewModel: ProfileViewModel(
                        user: user,
                        profileRepository: authStateStore.profileRepository
                    ))
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                }
            }
        }
    }
}
