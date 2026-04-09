# flutter-example-integration
Example of integration PPG Flutter SDK with a Flutter application

## Description
This is a test app for validating the integration of the PushPushGo Flutter SDK (`pushpushgo_sdk ^1.3.3`).
It provides two dedicated tabs for testing all SDK features:

- **Push tab** — Push Notification subscription, unsubscription, subscriber ID, and Beacon
- **In-App tab** — In-App Message custom triggers, route change simulation, and cache management

Note: Test app supports integration on platforms: **iOS / Android**

## Requirements
- PPG project with API KEY and Project ID
- Access to Firebase Console (Android)
- Access to Apple Developers console (iOS)

**Approximate time of installation to run test app - 30 min**

## Installation

### 1. Clone & configure credentials
1. Clone repo
2. Login into your PPG project
3. Collect your Project ID and API KEY (https://next.pushpushgo.com/organization/yourOrganizationID/access-manager/api-keys)
4. Open `flutter_test_app/lib/main.dart` and fill in your credentials in **two places** — once for Push SDK and once for In-App Messages SDK:
    ```dart
    _pushpushgo = PushpushgoSdk({
      "apiToken": "YOUR API KEY",
      "projectId": "YOUR PROJECT ID",
      "appGroupId": "YOUR APP GROUP ID",  // e.g. group.com.example.flutterTestApp
    });
    ```
    ```dart
    await PPGInAppMessages.instance.initialize(
      apiKey: "YOUR API KEY",
      projectId: "YOUR PROJECT ID",
    );
    ```
5. Open `flutter_test_app/ios/NSE/NotificationService.swift` and set the same App Group ID:
    ```swift
    SharedData.shared.appGroupId = "YOUR APP GROUP ID"
    ```
6. Open `flutter_test_app/ios/Runner/Runner.entitlements` and set the same App Group ID in the `com.apple.security.application-groups` array.

### Android
1. Install Firebase CLI:
    ```bash
    curl -sL https://firebase.tools | bash
    ```
2. Install FlutterFire CLI:
    ```bash
    dart pub global activate flutterfire_cli
    ```
3. Login to Firebase:
    ```bash
    firebase login
    ```
4. Configure Firebase for the project:
    ```bash
    flutterfire configure --project=your-firebase-project-id
    ```
   Note: If `flutterfire` is not found, add `export PATH="$PATH":"$HOME/.pub-cache/bin"` to your `.zshrc`.

5. Open the `android/` folder in Android Studio and synchronize files.
6. Generate FCM v1 credentials and upload to PPG:
   - Firebase Console → Project Settings → Cloud Messaging → Manage Service Accounts
   - Navigate to KEYS → ADD KEY → CREATE NEW KEY → JSON → Download
   - Upload at: https://next.pushpushgo.com/projects/YourProjectID/settings/integration/fcm

#### Android — In-App Messages additional setup
Add the following inside the `<application>` tag in `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data android:name="com.pushpushgo.inapp.projectId" android:value="YOUR_PROJECT_ID" />
<meta-data android:name="com.pushpushgo.inapp.apiKey" android:value="YOUR_API_KEY" />
<meta-data android:name="com.pushpushgo.inapp.isDebug" android:value="false" />
```
Also ensure `minSdk` is at least `26` in `android/app/build.gradle`.

### iOS
Generate an APNS certificate and upload it — https://docs.pushpushgo.company/application/providers/mobile-push/apns

**Important:** The bundle ID in your certificate must match the one in Xcode.
Default bundle ID for this test app: `com.example.flutterTestApp`

#### iOS — App Groups (required from SDK v1.0.0+)
1. In Xcode open the **Runner** target → **Signing & Capabilities**.
2. Click **+ Capability** → add **App Groups**.
3. Add your App Group identifier (e.g. `group.com.example.flutterTestApp`).
4. Repeat for the **NSE** target — add the same App Group.
5. Make sure the identifier you created matches the placeholder `YOUR APP GROUP ID` in:
   - `lib/main.dart` (`appGroupId` field)
   - `ios/NSE/NotificationService.swift` (`SharedData.shared.appGroupId`)
   - `ios/Runner/Runner.entitlements` (`com.apple.security.application-groups`)

### Common
Install Flutter dependencies:
```bash
flutter pub get
```

- **iOS**: Open `ios/Runner.xcworkspace` in Xcode and press `CMD + R` (ensure Runner is the active scheme).
- **Android**: Open `android/` in Android Studio, then build and run.

## Application structure

```
flutter_test_app/lib/
├── main.dart              # App entry point, SDK initialization, tab layout
├── buttons_view_model.dart  # ViewModel for Push Notifications tab
└── inapp_view_model.dart    # ViewModel for In-App Messages tab
```

## Functionalities

### Push tab (`buttons_view_model.dart`)
- **Subscribe** — Register device for push notifications
- **Unsubscribe** — Unregister from push notifications
- **Get Subscriber ID** — Display current PPG subscriber ID
- **Send Beacon** — Send subscriber tags and selectors to PPG

### In-App tab (`inapp_view_model.dart`)
- **Show Messages on Trigger** — Fire a custom trigger (`key` / `value`) to display a matching In-App Message from the PPG dashboard
- **Simulate Route Change** — Manually notify the SDK about a route change (e.g. `/home`) to trigger route-based messages
- **Clear Message Cache** — Force a fresh fetch of In-App Messages on the next route change

### Custom Code Actions
When an In-App Message button uses a custom code action, the handler defined in `main.dart` fires a `SnackBar` with the received code. You can extend `_initialize()` in `_MyAppState` to handle any custom codes your campaign uses.

### Route auto-tracking
`InAppMessagesNavigatorObserver` is registered in `MaterialApp.navigatorObservers`, so any named-route navigation automatically notifies the In-App SDK. Routes must include a `RouteSettings(name: '...')` to be tracked.