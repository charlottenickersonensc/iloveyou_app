import SwiftUI

// MARK: - Screen 4: Activity → Saved nav
struct ActivitySavedNavView: View {
    var onPosts:  () -> Void
    var onEvents: () -> Void
    var onBack:   () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appBlue)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 8)

            savedNavButton("Saved\nPosts", action: onPosts)
            savedNavButton("Saved\nEvents", action: onEvents)
            Spacer(minLength: 0)
        }
        .background(Color.white)
    }

    private func savedNavButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.custom("Jost-ExtraBold", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24).padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.appBlue).cornerRadius(14)
            .padding(.horizontal, 16)
        }
    }
}
