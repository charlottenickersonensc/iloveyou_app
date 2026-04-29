import SwiftUI

public struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @EnvironmentObject private var authStateStore: AuthStateStore

    public init(viewModel: ProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 1 basic profile screen.
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Circle()
                            .fill((viewModel.fruit.map { Color(hex: $0.themeColorHex) }) ?? .secondary)
                            .frame(width: 72, height: 72)
                            .overlay(Text(String(viewModel.user.displayUsername.prefix(1))).font(.title.bold()))
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text(viewModel.user.displayUsername)
                                .font(.title2.bold())
                            Text("@\(viewModel.user.username)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let fruit = viewModel.fruit {
                        Label(fruit.name, systemImage: "seal.fill")
                            .foregroundStyle(Color(hex: fruit.themeColorHex))
                    }

                    if let bio = viewModel.user.bio, !bio.isEmpty {
                        Text(bio)
                    }

                    if let location = viewModel.user.locationText, !location.isEmpty {
                        Label(location, systemImage: "mappin.and.ellipse")
                    }

                    if !viewModel.user.interests.isEmpty {
                        FlowLayout(items: viewModel.user.interests)
                    }

                    #if DEBUG
                    Button("Sign out", role: .destructive) {
                        authStateStore.signOut()
                    }
                    #endif
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("Profile")
        }
        .task { await viewModel.load() }
    }
}

private struct FlowLayout: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: DesignTokens.Spacing.sm)], alignment: .leading) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.footnote)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
        }
    }
}
