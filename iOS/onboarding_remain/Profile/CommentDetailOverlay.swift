import SwiftUI

// MARK: - Screens 11 & 12: Comment Detail Overlay
struct CommentDetailOverlay: View {
    let post: PostItem
    var showReplies: Bool
    var onExpandReplies: () -> Void
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
                Rectangle().fill(Color(.systemGray5)).frame(maxWidth: .infinity).frame(height: 160)
                    .overlay(Image(systemName: "photo").font(.system(size: 30)).foregroundColor(.gray))
            } else {
                Text(post.caption)
                    .font(.custom("Jost-Medium", size: 16)).padding(.horizontal, 16).padding(.bottom, 12)
            }

            Text("Replies")
                .font(.custom("Jost-ExtraBold", size: 16)).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.appBlueMid)

            if showReplies {
                commentRow(name: "Grace Lee (you)", text: "It was so good!")
                Divider()
                commentRow(name: "Jimmy Patrick", text: "Loved it")
                Divider()
            } else {
                commentRow(name: "Grace Lee (you)", text: post.hasPhoto ? "STRAWBERRIES!" : "It was so good!")
                Button(action: onExpandReplies) {
                    Text("View 2 replies")
                        .font(.custom("Jost-Medium", size: 13)).foregroundColor(.appBlue)
                        .padding(.leading, 56).padding(.top, 4).padding(.bottom, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(Color.white).cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(radius: 20)
    }

    private func commentRow(name: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(Color.appBluePale).frame(width: 36, height: 36)
                .overlay(Image(systemName: "person.fill").font(.system(size: 16)).foregroundColor(.appBlue))
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.custom("Jost-ExtraBold", size: 13))
                Text(text).font(.custom("Jost-Medium", size: 14))
                HStack(spacing: 12) {
                    Button("Reply") {}.font(.custom("Jost-Medium", size: 12)).foregroundColor(.gray)
                    Text("——  View 2 replies").font(.custom("Jost-Medium", size: 12)).foregroundColor(.gray)
                }
                .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "heart").foregroundColor(.gray)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}
