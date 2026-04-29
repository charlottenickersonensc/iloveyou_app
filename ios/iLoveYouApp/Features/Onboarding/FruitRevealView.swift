import SwiftUI

public struct FruitRevealView: View {
    @StateObject private var viewModel: FruitRevealViewModel
    @EnvironmentObject private var authStateStore: AuthStateStore

    public init(viewModel: FruitRevealViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        // TODO: Replace placeholder with exact Figma node for the Sprint 1 fruit wheel reveal screen.
        VStack(spacing: DesignTokens.Spacing.lg) {
            FruitWheelView()
                .rotationEffect(.degrees(viewModel.rotationDegrees))
                .animation(.easeOut(duration: 3.0), value: viewModel.rotationDegrees)
                .frame(maxWidth: 320)

            if viewModel.hasFinishedAnimation {
                Text(viewModel.fruit.name)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color(hex: viewModel.fruit.themeColorHex))
                AppButton("Continue") {
                    authStateStore.completeFruitReveal(for: viewModel.user)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .task {
            viewModel.start()
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            viewModel.finishAnimation()
        }
    }
}
