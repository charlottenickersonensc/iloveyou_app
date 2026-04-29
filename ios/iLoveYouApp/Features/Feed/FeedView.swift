import SwiftUI

public struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @State private var isShowingComposer = false
    @State private var reportedPost: Post?

    public init(viewModel: FeedViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 2 feed screen.
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView("No posts yet", systemImage: "text.bubble", description: Text("Start the conversation."))
                } else {
                    List {
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
                    .listStyle(.plain)
                    .refreshable { await viewModel.refresh() }
                }
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
            .task { await viewModel.loadInitial() }
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
