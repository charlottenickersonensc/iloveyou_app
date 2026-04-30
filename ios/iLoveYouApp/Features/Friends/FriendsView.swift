import SwiftUI

public struct FriendsView: View {
    @StateObject private var viewModel: FriendsViewModel

    public init(viewModel: FriendsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }

                Section("Requests") {
                    if viewModel.pendingRequests.isEmpty {
                        Text("No pending requests")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.pendingRequests) { friendship in
                            PendingRequestRow(
                                friendship: friendship,
                                requester: viewModel.requester(for: friendship),
                                isLoading: viewModel.actionInProgressIds.contains(friendship.id),
                                onAccept: {
                                    Task { await viewModel.respond(to: friendship, action: .accept) }
                                },
                                onDecline: {
                                    Task { await viewModel.respond(to: friendship, action: .decline) }
                                }
                            )
                        }
                    }
                }

                Section("Friends") {
                    if viewModel.friends.isEmpty {
                        Text("No friends yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.friends) { user in
                            PersonSummaryRow(user: user)
                        }
                    }
                }

                Section("Discover") {
                    ForEach(viewModel.discoveredPeople) { user in
                        DiscoveryPersonRow(
                            user: user,
                            state: viewModel.relationshipState(for: user),
                            isLoading: viewModel.actionInProgressIds.contains(user.id),
                            onSendRequest: {
                                Task { await viewModel.sendRequest(to: user) }
                            },
                            onAccept: { friendship in
                                Task { await viewModel.respond(to: friendship, action: .accept) }
                            },
                            onDecline: { friendship in
                                Task { await viewModel.respond(to: friendship, action: .decline) }
                            }
                        )
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Friends")
            .searchable(text: $viewModel.searchText, prompt: "Search people")
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
            .refreshable { await viewModel.load() }
            .task { await viewModel.load() }
            .overlay {
                if viewModel.isSearching {
                    ProgressView()
                }
            }
            .alert("Friends error", isPresented: errorBinding) {
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

private struct PersonSummaryRow: View {
    let user: User

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            AvatarView(user: user)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayUsername)
                    .font(.subheadline.bold())
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
}

private struct PendingRequestRow: View {
    let friendship: Friendship
    let requester: User?
    let isLoading: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            if let requester {
                PersonSummaryRow(user: requester)
            } else {
                Text("Friend request")
                    .font(.subheadline.bold())
            }

            Spacer()

            if isLoading {
                ProgressView()
            } else {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Accept friend request")

                    Button(role: .destructive, action: onDecline) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Decline friend request")
                }
            }
        }
    }
}

private struct DiscoveryPersonRow: View {
    let user: User
    let state: FriendRelationshipState
    let isLoading: Bool
    let onSendRequest: () -> Void
    let onAccept: (Friendship) -> Void
    let onDecline: (Friendship) -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            PersonSummaryRow(user: user)
            Spacer()
            actionView
        }
    }

    @ViewBuilder
    private var actionView: some View {
        if isLoading {
            ProgressView()
        } else {
            switch state {
            case .none:
                Button(action: onSendRequest) {
                    Image(systemName: "person.badge.plus")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add friend")
            case .requested:
                Label("Requested", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .respond(let friendship):
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button { onAccept(friendship) } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Accept friend request")

                    Button(role: .destructive) { onDecline(friendship) } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Decline friend request")
                }
            case .friends:
                Label("Friends", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct AvatarView: View {
    let user: User

    var body: some View {
        AsyncImage(url: user.avatarUrl) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Circle()
                .fill(Color.secondary.opacity(0.16))
                .overlay(Text(String(user.displayUsername.prefix(1))).font(.subheadline.bold()))
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}
