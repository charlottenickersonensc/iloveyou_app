import SwiftUI

// MARK: - Screens 5, 7, 10: Activity → Post Grid (Saved Posts / Liked Posts / Comments)
struct ActivityPostGridView: View {
    var title: String
    var posts: [PostItem]
    var onPostTap: (PostItem) -> Void
    var onBack: () -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appBlue)
                }
                Text(title).font(.custom("Jost-ExtraBold", size: 18))
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<9, id: \.self) { i in
                    Button {
                        if i < posts.count { onPostTap(posts[i]) }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(i < posts.count && posts[i].hasPhoto ? Color(.systemGray5) : Color.appBluePale)
                                .frame(height: 100)
                            if i < posts.count {
                                if posts[i].hasPhoto {
                                    Image(systemName: "photo").foregroundColor(.gray).font(.system(size: 22))
                                } else {
                                    Image(systemName: "text.alignleft").foregroundColor(.appBlue).font(.system(size: 18))
                                }
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: title == "Saved Posts" ? "bookmark.circle.fill" :
                                                           title == "Liked Posts" ? "heart.circle.fill" : "bubble.left.circle.fill")
                                            .foregroundColor(.appBlue).font(.system(size: 16))
                                            .padding(6)
                                    }
                                }
                                .frame(height: 100)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color.white)
    }
}
