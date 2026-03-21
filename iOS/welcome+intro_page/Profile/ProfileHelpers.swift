import SwiftUI

// MARK: - Shared helpers (used across multiple overlays)

func dimBackground(onDismiss: @escaping () -> Void) -> some View {
    Color.black.opacity(0.35).ignoresSafeArea().onTapGesture { onDismiss() }
}

func dismissButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: "xmark.circle.fill")
            .font(.title2).foregroundColor(Color(.systemGray3))
    }
}

// MARK: - Bottom Nav Bar
struct BottomNavBar: View {
    enum Tab { case home, events, groups, messages, profile }
    var selectedTab: Tab

    private let items: [(icon: String, label: String, tab: Tab)] = [
        ("house.fill",              "Home",     .home),
        ("calendar",                "Events",   .events),
        ("person.3.fill",           "Groups",   .groups),
        ("message.fill",            "Messages", .messages),
        ("person.crop.circle.fill", "Profile",  .profile)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab) { item in
                VStack(spacing: 3) {
                    Image(systemName: item.icon).font(.system(size: 22))
                    Text(item.label).font(.custom("Jost-Medium", size: 10))
                }
                .foregroundColor(selectedTab == item.tab ? .appBlue : Color(.systemGray3))
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 83)
        .background(Color.white)
        .overlay(alignment: .top) { Divider() }
    }
}
