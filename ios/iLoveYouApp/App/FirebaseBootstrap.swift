import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage
#endif

enum FirebaseBootstrap {
    static func configure() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else { return }

        let hasGoogleServiceInfo = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        if hasGoogleServiceInfo {
            FirebaseApp.configure()
        } else {
            let options = FirebaseOptions(
                googleAppID: "1:000000000000:ios:0000000000000000000000",
                gcmSenderID: "000000000000"
            )
            options.apiKey = "local-emulator-placeholder"
            options.projectID = "iloveyou-dev"
            options.storageBucket = "iloveyou-dev.appspot.com"
            options.bundleID = Bundle.main.bundleIdentifier ?? "com.iloveyou.app"
            FirebaseApp.configure(options: options)
        }

        configureEmulatorsIfNeeded(force: !hasGoogleServiceInfo)
        #endif
    }

    #if canImport(FirebaseAuth)
    private static func configureEmulatorsIfNeeded(force: Bool) {
        let environment = ProcessInfo.processInfo.environment
        let shouldUseEmulators = force || environment["USE_FIREBASE_EMULATORS"] == "1"
        guard shouldUseEmulators else { return }

        let host = environment["FIREBASE_EMULATOR_HOST"] ?? "127.0.0.1"
        Auth.auth().useEmulator(withHost: host, port: 9099)
        Firestore.firestore().useEmulator(withHost: host, port: 8080)
        Functions.functions().useEmulator(withHost: host, port: 5001)
        Storage.storage().useEmulator(withHost: host, port: 9199)
    }
    #endif
}
