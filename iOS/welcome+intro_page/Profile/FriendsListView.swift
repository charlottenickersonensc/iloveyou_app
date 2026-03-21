import SwiftUI

// MARK: - Screen 2: Friends List
struct FriendsListView: View {
    @State private var search = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Profiles")
                .font(.custom("Jost-ExtraBold", size: 20))
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 8)

            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("search", text: $search)
                    .font(.custom("Jost-Medium", size: 15))
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Color(.systemGray6)).cornerRadius(10)
            .padding(.horizontal, 16).padding(.bottom, 8)

            ForEach(sampleFriends) { f in
                HStack(spacing: 12) {
                    Circle().fill(Color.appBluePale).frame(width: 46, height: 46)
                        .overlay(Image(systemName: "person.fill").foregroundColor(.appBlue))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.name).font(.custom("Jost-ExtraBold", size: 15))
                        Text(f.subtitle).font(.custom("Jost-Medium", size: 13)).foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                Divider().padding(.leading, 66)
            }
        }
        .background(Color.white)
    }
}
