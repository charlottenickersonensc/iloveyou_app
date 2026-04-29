# iLoveYou App

Sprint 1 foundation for the Firebase-backed iLoveYou app.

## Firebase

Install dependencies:

```bash
cd firebase/functions
npm install
```

Run emulators:

```bash
cd firebase/functions
npx firebase emulators:start --config ../firebase.json --project iloveyou-dev
```

Seed fruit communities against the emulator or selected Firebase project:

```bash
cd firebase/functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=iloveyou-dev npm run seed:fruits
```

Seed fruit communities against the selected Firebase project:

```bash
cd firebase/functions
npm run seed:fruits
```

Run backend tests with emulators:

```bash
cd firebase/functions
npm run test:emulators
```

## iOS

The Swift source is under `ios/iLoveYouApp`, with the app target in
`ios/iLoveYouApp.xcodeproj` and a shared `iLoveYouApp` scheme.

Run the pure Swift Sprint 1 tests through Swift Package Manager:

```bash
cd ios
swift test
```

Build the iOS app without code signing:

```bash
xcodebuild -project ios/iLoveYouApp.xcodeproj -scheme iLoveYouApp -destination generic/platform=iOS -derivedDataPath ios/DerivedData CODE_SIGNING_ALLOWED=NO build
```

`GoogleService-Info.plist` is intentionally not committed. Add the dev Firebase
config at `ios/iLoveYouApp/Resources/GoogleService-Info.plist` for device or
staging work.

### Local Firebase + iOS

1. Install function dependencies with `npm install` from `firebase/functions`.
2. Start emulators from `firebase/functions`:

```bash
npx firebase emulators:start --config ../firebase.json --project iloveyou-dev
```

3. Seed the required Sprint 1 fruit communities:

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=iloveyou-dev npm run seed:fruits
```

4. Run the `iLoveYouApp` shared scheme. The scheme sets
`USE_FIREBASE_EMULATORS=1` and `FIREBASE_EMULATOR_HOST=127.0.0.1`, so the app
routes Auth, Firestore, Functions, and Storage to local emulators. If
`GoogleService-Info.plist` is absent, the app uses local placeholder Firebase
options for emulator development only.
