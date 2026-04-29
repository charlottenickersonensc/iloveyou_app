import SwiftUI

@main
struct iLoveYouApp: App {
    @StateObject private var authStateStore = AuthStateStore()

    init() {
        FirebaseBootstrap.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(authStateStore)
                .task {
                    await authStateStore.start()
                }
        }
    }
}
