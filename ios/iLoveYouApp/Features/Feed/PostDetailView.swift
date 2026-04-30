import SwiftUI

public struct PostDetailView: View {
    public let post: Post
    @ObservedObject private var viewModel: FeedViewModel
    @State private var comments: [PostComment] = []
    @State private var commentText = ""
    @State private var errorMessage: String?

    public init(post: Post, viewModel: FeedViewModel) {
        self.post = post
        self.viewModel = viewModel
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 2 comments screen.
        VStack(spacing: 0) {
            List {
                PostCardView(post: displayedPost, canPin: viewModel.canPinPosts, onLike: {
                    Task { await viewModel.toggleLike(post: displayedPost) }
                }, onPin: { pinned in
                    Task { await viewModel.setPinned(pinned, for: displayedPost) }
                }, onReport: {})

                Section("Comments") {
                    if comments.isEmpty {
                        Text("No comments yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text(comment.authorDisplayUsername)
                                    .font(.subheadline.bold())
                                Text(comment.contentText)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)

            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField("Add a comment", text: $commentText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Comment text")
                Button {
                    Task { await submitComment() }
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedComment.isEmpty || trimmedComment.count > 1000)
                .accessibilityLabel("Send comment")
                .accessibilityHint("Adds your comment to this post.")
            }
            .padding(DesignTokens.Spacing.md)
        }
        .navigationTitle("Post")
        .alert("Comment error", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var trimmedComment: String {
        commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var displayedPost: Post {
        viewModel.posts.first(where: { $0.id == post.id }) ?? post
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func submitComment() async {
        do {
            let comment = try await viewModel.createComment(postId: post.id, contentText: trimmedComment)
            comments.append(comment)
            commentText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
