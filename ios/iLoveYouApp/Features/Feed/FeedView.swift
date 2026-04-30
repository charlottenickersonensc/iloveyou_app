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
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        viewModel.feedMode.emptyTitle,
                        systemImage: "text.bubble",
                        description: Text(viewModel.feedMode.emptyDescription)
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.posts) { post in
                        NavigationLink {
                            PostDetailView(post: post, viewModel: viewModel)
                        } label: {
                            PostCardView(
                                post: post,
                                onLike: { Task { await viewModel.toggleLike(post: post) } },
                                onReport: { reportedPost = post }
                            )
                        }
                        .buttonStyle(.plain)
                        .task { await viewModel.loadMoreIfNeeded(currentPost: post) }
                    }

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
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
    }

    private var binding: Binding<FeedMode> {
        Binding(
            get: { selectedMode },
            set: { onSelect($0) }
        )
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
