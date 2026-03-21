import SwiftUI

// MARK: - Screen 19: Notifications Overlay
struct NotificationsOverlay: View {
    var onDismiss: () -> Void

    var body: some View {
        dimBackground(onDismiss: onDismiss)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "bell.fill").font(.title2).foregroundColor(.appBlue)
                Spacer()
                dismissButton(action: onDismiss)
            }
            .padding(16)

            notifSection("Today", items: [
                "Ellie Chang wants to be your friend!",
                "Leo Oh liked your post"
            ])
            notifSection("Last week", items: [
                "Blueberries in SD invites you to an event",
                "Grace Lee tagged you in a post",
                "There is an update to Movie Night event",
                "Blueberries in SD invites you to join their group!"
            ])
        }
        .background(Color.white).cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(radius: 20)
    }

    private func notifSection(_ header: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(header).font(.custom("Jost-ExtraBold", size: 14)).foregroundColor(.gray)
                .padding(.horizontal, 16).padding(.vertical, 8)
            ForEach(items, id: \.self) { item in
                HStack {
                    Text(item).font(.custom("Jost-Medium", size: 14)).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 13))
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                Divider()
            }
        }
    }
}
