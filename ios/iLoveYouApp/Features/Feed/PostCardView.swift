import SwiftUI

public struct PostCardView: View {
    public let post: Post
    public let canPin: Bool
    public let onLike: () -> Void
    public let onPin: (Bool) -> Void
    public let onReport: () -> Void

    public init(
        post: Post,
        canPin: Bool = false,
        onLike: @escaping () -> Void,
        onPin: @escaping (Bool) -> Void = { _ in },
        onReport: @escaping () -> Void
    ) {
        self.post = post
        self.canPin = canPin
        self.onLike = onLike
        self.onPin = onPin
        self.onReport = onReport
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 2 post card.
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
                Circle()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(Text(String(post.authorDisplayUsername.prefix(1))).font(.subheadline.bold()))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.isAnonymous ? "Someone in your fruit" : post.authorDisplayUsername)
                        .font(.subheadline.bold())
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    if canPin {
                        Button {
                            onPin(!post.pinned)
                        } label: {
                            Label(post.pinned ? "Unpin post" : "Pin post", systemImage: post.pinned ? "pin.slash" : "pin")
                        }
                    }

                    Button(role: .destructive, action: onReport) {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Post actions for \(displayAuthorName)")
                .accessibilityHint(canPin ? "Pin, unpin, or report this post." : "Report this post.")
            }

            Text(post.contentText)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if post.pinned {
                Label("Pinned", systemImage: "pin.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                    .accessibilityLabel("Pinned post")
            }

            if !post.imageUrls.isEmpty {
                ImageGrid(urls: post.imageUrls)
            }

            HStack(spacing: DesignTokens.Spacing.lg) {
                Button(action: onLike) {
                    Label("\(post.likeCount)", systemImage: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                }
                .buttonStyle(.plain)
                .foregroundStyle(post.isLikedByCurrentUser ? .red : .primary)
                .accessibilityLabel(post.isLikedByCurrentUser ? "Unlike post" : "Like post")
                .accessibilityValue("\(post.likeCount) \(post.likeCount == 1 ? "like" : "likes")")
                .accessibilityHint("Toggles your like on this post.")

                Label("\(post.commentCount)", systemImage: "bubble.right")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(post.commentCount) \(post.commentCount == 1 ? "comment" : "comments")")
            }
            .font(.subheadline)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    private var displayAuthorName: String {
        post.isAnonymous ? "someone in your fruit" : post.authorDisplayUsername
    }
}

private struct ImageGrid: View {
    let urls: [URL]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: DesignTokens.Spacing.sm)], spacing: DesignTokens.Spacing.sm) {
            ForEach(urls, id: \.self) { url in
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.secondary.opacity(0.14)
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            }
        }
    }
}
