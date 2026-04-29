import SwiftUI

public struct PostCardView: View {
    public let post: Post
    public let onLike: () -> Void
    public let onReport: () -> Void

    public init(post: Post, onLike: @escaping () -> Void, onReport: @escaping () -> Void) {
        self.post = post
        self.onLike = onLike
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.isAnonymous ? "Someone in your fruit" : post.authorDisplayUsername)
                        .font(.subheadline.bold())
                    Text(post.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button(role: .destructive, action: onReport) {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Post actions")
            }

            Text(post.contentText)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if !post.imageUrls.isEmpty {
                ImageGrid(urls: post.imageUrls)
            }

            HStack(spacing: DesignTokens.Spacing.lg) {
                Button(action: onLike) {
                    Label("\(post.likeCount)", systemImage: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                }
                .buttonStyle(.plain)
                .foregroundStyle(post.isLikedByCurrentUser ? .red : .primary)

                Label("\(post.commentCount)", systemImage: "bubble.right")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
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
