import SwiftUI

// MARK: - Screen 14: Profile Picture Overlay
struct ProfilePicOverlay: View {
    var onDismiss: () -> Void

    var body: some View {
        dimBackground(onDismiss: onDismiss)
        VStack(spacing: 20) {
            HStack {
                Spacer()
                dismissButton(action: onDismiss)
            }
            .padding([.top, .trailing], 16)

            Circle().fill(Color.appBluePale).frame(width: 140, height: 140)
                .overlay(Image(systemName: "person.fill").resizable().scaledToFit()
                    .frame(width: 70).foregroundColor(.appBlue))
                .overlay(Circle().stroke(Color.appBlue, lineWidth: 2))

            VStack(spacing: 12) {
                outlinedButton("Adjust Image", action: {})
                outlinedButton("Change Image", action: {})
            }
            .padding(.horizontal, 24).padding(.bottom, 24)
        }
        .background(Color.white).cornerRadius(20)
        .padding(.horizontal, 40)
        .shadow(radius: 20)
    }

    private func outlinedButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.custom("Jost-Medium", size: 16)).foregroundColor(.appBlue)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.appBlue, lineWidth: 1.5))
        }
    }
}
