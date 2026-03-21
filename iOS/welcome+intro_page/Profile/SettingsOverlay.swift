import SwiftUI

// MARK: - Screen 13: Settings Overlay
struct SettingsOverlay: View {
    var onDismiss:       () -> Void
    var onSignOut:       () -> Void
    var onDeleteAccount: () -> Void

    @State private var privateAccount = true
    @State private var friendRequests = true
    @State private var eventInvites   = true

    var body: some View {
        dimBackground(onDismiss: onDismiss)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "gearshape").font(.title2).foregroundColor(.appBlue)
                    Spacer()
                    dismissButton(action: onDismiss)
                }
                .padding(16)

                sectionHeader("Profile")
                toggleRow("Private Account", value: $privateAccount)
                Divider()
                sectionHeader("Notifications")
                toggleRow("Friend Requests", value: $friendRequests)
                toggleRow("Event Invitations", value: $eventInvites)
                Divider()
                sectionHeader("Storage")
                HStack {
                    Text("Storage").font(.custom("Jost-Medium", size: 15))
                    Spacer()
                    Text("0 bytes / 25mb used").font(.custom("Jost-Medium", size: 13)).foregroundColor(.gray)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                Divider()
                ForEach(["Deleted Items", "Privacy and Data", "Blocked Accounts",
                         "Support", "Password and Safety"], id: \.self) { item in
                    navRow(item, isDestructive: false, action: {})
                    Divider()
                }
                navRow("Sign Out", isDestructive: false, action: onSignOut)
                Divider()
                navRow("Delete My Account", isDestructive: true, action: onDeleteAccount)
                Divider()
            }
        }
        .background(Color.white).cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(radius: 20)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
    }

    private func sectionHeader(_ t: String) -> some View {
        Text(t).font(.custom("Jost-ExtraBold", size: 15))
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 2)
    }

    private func toggleRow(_ label: String, value: Binding<Bool>) -> some View {
        HStack {
            Text(label).font(.custom("Jost-Medium", size: 15))
            Spacer()
            Toggle("", isOn: value).labelsHidden().tint(.appBlue)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    private func navRow(_ label: String, isDestructive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).font(.custom("Jost-Medium", size: 15))
                    .foregroundColor(isDestructive ? .red : .black)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.system(size: 13))
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
    }
}
