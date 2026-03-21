import SwiftUI

// MARK: - Screen 15: Sign Out Overlay
struct SignOutOverlay: View {
    var onBack:    () -> Void
    var onDismiss: () -> Void

    @State private var saveLogin = true

    var body: some View {
        dimBackground(onDismiss: onDismiss)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.appBlue)
                }
                Spacer()
                dismissButton(action: onDismiss)
            }
            .padding(16)

            Text("Save log-in info")
                .font(.custom("Jost-ExtraBold", size: 18)).padding(.horizontal, 16).padding(.bottom, 16)

            HStack(spacing: 12) {
                Circle().fill(Color.appBluePale).frame(width: 40, height: 40)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.appBlue))
                Text("Grace Lee").font(.custom("Jost-Medium", size: 16))
                Spacer()
                Toggle("", isOn: $saveLogin).labelsHidden().tint(.appBlue)
            }
            .padding(.horizontal, 16).padding(.bottom, 24)

            Button {} label: {
                Text("Sign Out").font(.custom("Jost-ExtraBold", size: 17)).foregroundColor(.appBlue)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.appBluePale).cornerRadius(30)
            }
            .padding(.horizontal, 16).padding(.bottom, 24)
        }
        .background(Color.white).cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(radius: 20)
    }
}
