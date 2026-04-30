import SwiftUI

public struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @StateObject private var mentalHealthViewModel: MentalHealthViewModel
    @State private var isShowingComposer = false
    @State private var reportedPost: Post?

    public init(viewModel: FeedViewModel, mentalHealthViewModel: MentalHealthViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._mentalHealthViewModel = StateObject(wrappedValue: mentalHealthViewModel)
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 2 feed screen.
        NavigationStack {
            List {
                MentalHealthHeaderView(viewModel: mentalHealthViewModel)
                    .listRowSeparator(.hidden)

                FeedModePicker(
                    selectedMode: viewModel.feedMode,
                    onSelect: { mode in Task { await viewModel.selectFeedMode(mode) } }
                )
                .listRowSeparator(.hidden)

                if viewModel.isLoading {
                    FeedLoadingRow(title: viewModel.feedMode.loadingTitle)
                        .listRowSeparator(.hidden)
                } else if viewModel.posts.isEmpty {
                    FeedEmptyState(
                        title: viewModel.feedMode.emptyTitle,
                        message: viewModel.feedMode.emptyDescription,
                        showsCreateAction: viewModel.feedMode == .fruit,
                        onCreatePost: { isShowingComposer = true }
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.posts) { post in
                        NavigationLink {
                            PostDetailView(post: post, viewModel: viewModel)
                        } label: {
                            PostCardView(
                                post: post,
                                canPin: viewModel.canPinPosts,
                                onLike: { Task { await viewModel.toggleLike(post: post) } },
                                onPin: { pinned in Task { await viewModel.setPinned(pinned, for: post) } },
                                onReport: { reportedPost = post }
                            )
                        }
                        .buttonStyle(.plain)
                        .task { await viewModel.loadMoreIfNeeded(currentPost: post) }
                    }

                    if viewModel.isLoadingMore {
                        FeedLoadingRow(title: "Loading more posts")
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refresh()
                await mentalHealthViewModel.loadToday()
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingComposer = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Create post")
                    .accessibilityHint("Opens the post composer.")
                }
            }
            .task {
                await viewModel.loadInitial()
                await mentalHealthViewModel.loadToday()
            }
            .alert("Feed error", isPresented: errorBinding) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $isShowingComposer) {
                CreatePostView { text in
                    await viewModel.createPost(contentText: text)
                }
            }
            .sheet(item: $reportedPost) { post in
                ReportContentView(post: post) { reason, details in
                    await viewModel.reportPost(postId: post.id, reason: reason, details: details)
                }
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

private struct FeedModePicker: View {
    let selectedMode: FeedMode
    let onSelect: (FeedMode) -> Void

    var body: some View {
        Picker("Feed mode", selection: binding) {
            ForEach(FeedMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .accessibilityLabel("Feed mode")
        .accessibilityValue(selectedMode.accessibilityValue)
        .accessibilityHint("Switches between fruit community posts and trending posts.")
    }

    private var binding: Binding<FeedMode> {
        Binding(
            get: { selectedMode },
            set: { onSelect($0) }
        )
    }
}

private struct FeedLoadingRow: View {
    let title: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ProgressView()
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

private struct FeedEmptyState: View {
    let title: String
    let message: String
    let showsCreateAction: Bool
    let onCreatePost: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "text.bubble")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(message)")

            if showsCreateAction {
                Button {
                    onCreatePost()
                } label: {
                    Label("Create post", systemImage: "square.and.pencil")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Opens the post composer.")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xl)
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}

private struct MentalHealthHeaderView: View {
    @ObservedObject var viewModel: MentalHealthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            DailyAffirmationCard(affirmation: viewModel.affirmation, isLoading: viewModel.isLoading)
            MoodCheckinCard(viewModel: viewModel)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

private struct DailyAffirmationCard: View {
    let affirmation: DailyAffirmation?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Label("Today", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            if isLoading && affirmation == nil {
                ProgressView()
            } else {
                Text(affirmation?.text ?? "You are allowed to take up space.")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(Color.accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}

private struct MoodCheckinCard: View {
    @ObservedObject var viewModel: MentalHealthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Label("Mood", systemImage: "heart.text.square")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if let todayCheckin = viewModel.todayCheckin {
                    Label(todayCheckin.mood.displayTitle, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Mood", selection: $viewModel.selectedMood) {
                ForEach(Mood.allCases) { mood in
                    Label(mood.displayTitle, systemImage: mood.systemImageName)
                        .tag(Optional(mood))
                }
            }
            .pickerStyle(.segmented)

            TextField("Optional note", text: $viewModel.noteText, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.roundedBorder)

            HStack {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    Task { await viewModel.submitMood() }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Label("Save", systemImage: "checkmark")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedMood == nil || viewModel.isSaving)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.md)
        .background(Color.secondary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}
