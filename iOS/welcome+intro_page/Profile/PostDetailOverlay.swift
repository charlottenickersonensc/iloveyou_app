import SwiftUI

// MARK: - Screens 8 & 9: Post Detail Overlay
struct PostDetailOverlay: View {
    let post: PostItem
    var onDismiss: () -> Void

    var body: some View {
        dimBackground(onDismiss: onDismiss)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Circle().fill(Color.appBluePale).frame(width: 40, height: 40)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.appBlue))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.author).font(.custom("Jost-ExtraBold", size: 14))
                        Text(post.group).font(.custom("Jost-Medium", size: 12)).foregroundColor(.gray)
                    }
                    Text(post.date).font(.custom("Jost-Medium", size: 12)).foregroundColor(.gray)
                }
                Spacer()
                dismissButton(action: onDismiss)
            }
            .padding(16)

            if post.hasPhoto {
                Rectangle().fill(Color(.systemGray5)).frame(maxWidth: .infinity).frame(height: 220)
                    .overlay(Image(systemName: "photo").font(.system(size: 40)).foregroundColor(.gray))
            } else {
                Text(post.caption)
                    .font(.custom("Jost-Medium", size: 17)).padding(20)
            }

            HStack(spacing: 16) {
                Label("\(post.likes)",    systemImage: "heart.fill").font(.custom("Jost-Medium", size: 14)).foregroundColor(.appBlue)
                Label("\(post.comments)", systemImage: "bubble.left").font(.custom("Jost-Medium", size: 14)).foregroundColor(.appBlue)
                Spacer()
                Image(systemName: "bookmark").foregroundColor(.appBlue)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            if post.hasPhoto {
                Text(post.caption).font(.custom("Jost-Medium", size: 13)).padding(.horizontal, 16).padding(.bottom, 16)
            }
        }
        .background(Color.white).cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(radius: 20)
        .frame(maxWidth: .infinity)
    }
}
