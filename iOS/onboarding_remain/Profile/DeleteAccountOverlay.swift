import SwiftUI

// MARK: - Screens 16, 17, 18: Delete Account Overlay
struct DeleteAccountOverlay: View {
    var step: Int
    var onBack:    () -> Void
    var onNext:    () -> Void
    var onDismiss: () -> Void

    @State private var selectedReason = ""

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

            switch step {
            case 1:  deleteStep1
            case 2:  deleteStep2
            default: deleteStep3
            }
        }
        .background(Color.white).cornerRadius(20)
        .padding(.horizontal, 16)
        .shadow(radius: 20)
    }

    private var deleteStep1: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Delete Account").font(.custom("Jost-ExtraBold", size: 20)).padding(.horizontal, 16)
            Text("Deleting your account is permanent. When you delete your iloveyou account, your profile, photos, videos, comments, likes, and followers will be permanently removed.")
                .font(.custom("Jost-Medium", size: 14)).foregroundColor(.gray)
                .padding(.horizontal, 16)
            actionButton("Delete Account", action: onNext)
                .padding(.horizontal, 16).padding(.bottom, 24)
        }
    }

    private var deleteStep2: some View {
        VStack(spacing: 20) {
            Text("Confirm that you want to permanently delete your account")
                .font(.custom("Jost-ExtraBold", size: 18))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            actionButton("Delete Account", action: onNext)
                .padding(.horizontal, 16).padding(.bottom, 24)
        }
        .padding(.top, 16)
    }

    private var deleteStep3: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("We're sad to see you go!")
                .font(.custom("Jost-ExtraBold", size: 20)).padding(.horizontal, 16)
            Text("tell us why you're leaving")
                .font(.custom("Jost-Medium", size: 14)).foregroundColor(.gray).padding(.horizontal, 16)

            ForEach(["No longer needed",
                     "I found a better alternative",
                     "Too complex/Hard to use",
                     "Privacy concerns",
                     "Technical issues"], id: \.self) { reason in
                HStack(spacing: 10) {
                    Image(systemName: selectedReason == reason ? "largecircle.fill.circle" : "circle")
                        .foregroundColor(.appBlue)
                    Text(reason).font(.custom("Jost-Medium", size: 14))
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
                .onTapGesture { selectedReason = reason }
            }

            actionButton("We hope to see you again!", action: onNext)
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
        }
    }

    private func actionButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.custom("Jost-ExtraBold", size: 16)).foregroundColor(.appBlue)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.appBluePale).cornerRadius(30)
        }
    }
}
