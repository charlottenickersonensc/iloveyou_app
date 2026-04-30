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
                    ), mentalHealthViewModel: MentalHealthViewModel(
                        repository: authStateStore.mentalHealthRepository
                    ))
                    .tabItem {
                        Label("Feed", systemImage: "text.bubble")
                    }

                    FriendsView(viewModel: FriendsViewModel(
                        currentUser: user,
                        friendsRepository: authStateStore.friendsRepository
                    ))
                    .tabItem {
                        Label("Friends", systemImage: "person.2")
                    }

                    NotificationsView(viewModel: NotificationViewModel(
                        currentUser: user,
                        repository: authStateStore.notificationRepository
                    ))
                    .tabItem {
                        Label("Notifications", systemImage: "bell")
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

private struct NotificationsView: View {
    @StateObject private var viewModel: NotificationViewModel

    init(viewModel: NotificationViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "No notifications yet",
                        systemImage: "bell",
                        description: Text("Likes, comments, and friend requests will appear here.")
                    )
                } else {
                    ForEach(viewModel.notifications) { notification in
                        NotificationRow(notification: notification) {
                            Task { await viewModel.markRead(notification) }
                        }
                        .task { await viewModel.loadMoreIfNeeded(currentNotification: notification) }
                    }

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.loadInitial() }
            .alert("Notification error", isPresented: errorBinding) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private struct NotificationRow: View {
    let notification: NotificationItem
    let onMarkRead: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: notification.isRead ? "bell" : "bell.badge.fill")
                .foregroundStyle(notification.isRead ? Color.secondary : Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(.headline)
                    if !notification.isRead {
                        Text("New")
                            .font(.caption.bold())
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Text(notification.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: DesignTokens.Spacing.sm)

            if !notification.isRead {
                Button(action: onMarkRead) {
                    Image(systemName: "checkmark.circle")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Mark notification read")
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}
