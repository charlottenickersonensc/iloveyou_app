# Apple Sign In and Firebase iOS Setup

Sprint 1 includes nonce generation and Firebase credential exchange in code, but
full Apple Sign In cannot be completed without Apple Developer provisioning and
Firebase console configuration.

## Local emulator development

The shared Xcode scheme sets:

- `USE_FIREBASE_EMULATORS=1`
- `FIREBASE_EMULATOR_HOST=127.0.0.1`

If `GoogleService-Info.plist` is absent, the app configures Firebase with local
placeholder options and routes Auth, Firestore, Functions, and Storage to the
emulators. Keep running the Firebase emulator suite from `firebase/`, and seed
the 12 fruit communities before testing signup.

## Firebase console steps

1. Create or select the Firebase iOS app for bundle ID `com.iloveyou.app`, or
   update the Xcode project bundle ID to the final production bundle ID first.
2. Download `GoogleService-Info.plist`.
3. Place it at `ios/iLoveYouApp/Resources/GoogleService-Info.plist`.
4. Keep the plist out of git; it is intentionally ignored.
5. Enable Email/password and Apple providers in Firebase Auth.
6. Enable Firestore, Cloud Functions, Storage, Messaging, Crashlytics, and
   Analytics for the selected Firebase project.

## Apple Developer and Xcode steps

1. Register the final app bundle identifier in the Apple Developer portal.
2. Enable the Sign in with Apple capability for that identifier.
3. In Xcode, set the development team on the `iLoveYouApp` target.
4. Add the Sign in with Apple capability to the target.
5. For Firebase Messaging, configure APNs auth key or certificate in Firebase
   console and add Push Notifications plus Background Modes as needed in Xcode.
6. For Crashlytics release symbol upload, add Firebase's Crashlytics run script
   build phase once the production Firebase app and build archive workflow are
   finalized.
7. Verify Apple Sign In on a physical device before TestFlight.

The client still never assigns or mutates `fruitCommunityId`; after any Auth
provider signs in, `completeUserSignup` remains the Cloud Function responsible
for creating the user document and assigning fruit.
