import SwiftUI

// MARK: - Post Card (used in Posts content + post grids)
struct PostCardView: View {
    let post: PostItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
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
            }
            .padding(.horizontal, 16).padding(.top, 12)

            if !post.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("@\(tag)").font(.custom("Jost-Medium", size: 12)).foregroundColor(.appBlue)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.appBluePale).cornerRadius(6)
                    }
                }
                .padding(.horizontal, 16)
            }

            if post.hasPhoto {
                Rectangle().fill(Color(.systemGray5)).frame(maxWidth: .infinity).frame(height: 200)
                    .overlay(Image(systemName: "photo").font(.system(size: 40)).foregroundColor(.gray))
            } else {
                Text(post.caption)
                    .font(.custom("Jost-Medium", size: 14)).foregroundColor(.black)
                    .padding(.horizontal, 16).padding(.vertical, 8)
            }

            HStack(spacing: 16) {
                Label("\(post.likes)",    systemImage: "heart.fill").font(.custom("Jost-Medium", size: 13)).foregroundColor(.appBlue)
                Label("\(post.comments)", systemImage: "bubble.left.fill").font(.custom("Jost-Medium", size: 13)).foregroundColor(.appBlue)
                Spacer()
                Image(systemName: "bookmark").foregroundColor(.appBlue)
            }
            .padding(.horizontal, 16)

            if post.hasPhoto {
                Text(post.caption).font(.custom("Jost-Medium", size: 13)).padding(.horizontal, 16)
            }

            Color.clear.frame(height: 8)
        }
    }
}
