import SwiftUI

// MARK: - App Entry Point
// Hands off immediately to OnboardingCoordinator which owns
// the NavigationStack and all route definitions.
struct ContentView: View {
    var body: some View {
        OnboardingCoordinator()
    }
}

#Preview {
    ContentView()
}











