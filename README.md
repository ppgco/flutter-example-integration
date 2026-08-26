# flutter-example-integration
Example of integration PPG Flutter SDK with a Flutter application

## Description
This is a test app for validating the integration of the PushPushGo Flutter SDK (`pushpushgo_sdk ^1.4.0`).
It provides three dedicated tabs for testing all SDK features:

- **Push tab** — Push Notification subscription, unsubscription, subscriber ID, and Beacon
- **In-App tab** — In-App Message custom triggers, route change simulation, and cache management
- **Live tab** — Live Activities: device support check, campaign subscribe/unsubscribe, tracked activities and a local simulation (Android only)

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
    Live Activities reuse the push credentials, so only the App Group needs filling in:
    ```dart
    await PPGLiveActivities.instance.initialize(
      appGroupId: "YOUR APP GROUP ID",
    );
    ```
5. Open `flutter_test_app/ios/NSE/NotificationService.swift` and set the same App Group ID:
    ```swift
    SharedData.shared.appGroupId = "YOUR APP GROUP ID"
    ```
6. Open `flutter_test_app/ios/Runner/Runner.entitlements` and set the same App Group ID in the `com.apple.security.application-groups` array.
7. Open `flutter_test_app/ios/LiveActivityWidget/MatchLiveActivityWidget.swift` and `flutter_test_app/ios/LiveActivityWidget/LiveActivityWidget.entitlements` and set the same App Group ID there — the widget runs in its own process and reads team badges from that shared container.

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
`minSdk` is already set to `26` in `android/app/build.gradle` — the PPG plugin requires it.

#### Android — toolchain
The project builds with **AGP 8.7.3 / Kotlin 2.1.0 / Gradle 8.9**, which is what the current
`pushpushgo_sdk` dependency chain needs (its AndroidX transitive dependencies refuse AGP older
than 8.6).

Those Gradle and AGP versions run on **JDK 17–21**. Flutter uses the JDK bundled with Android
Studio by default, and recent Android Studio releases ship JDK 23/25, which Gradle 8.9 cannot
run on (`Unsupported class file major version …`). If you hit that, point Flutter at a
supported JDK once:
```bash
flutter config --jdk-dir=/path/to/jdk-21
```

Live Activities themselves need **Android 16 (API 36)** at runtime; below that `isSupported()`
returns `false` and every other call is a safe no-op.

### iOS
Generate an APNS certificate and upload it — https://docs.pushpushgo.company/application/providers/mobile-push/apns

**Important:** The bundle ID in your certificate must match the one in Xcode.
Default bundle ID for this test app: `com.example.flutterTestApp`

#### iOS — App Groups (required from SDK v1.0.0+)
1. In Xcode open the **Runner** target → **Signing & Capabilities**.
2. Click **+ Capability** → add **App Groups**.
3. Add your App Group identifier (e.g. `group.com.example.flutterTestApp`).
4. Repeat for the **NSE** and **LiveActivityWidget** targets — add the same App Group.
5. Make sure the identifier you created matches the placeholder `YOUR APP GROUP ID` in:
   - `lib/main.dart` (`appGroupId` field, twice — push SDK config and `PPGLiveActivities.initialize`)
   - `ios/NSE/NotificationService.swift` (`SharedData.shared.appGroupId`)
   - `ios/Runner/Runner.entitlements` (`com.apple.security.application-groups`)
   - `ios/LiveActivityWidget/LiveActivityWidget.entitlements`
   - `ios/LiveActivityWidget/MatchLiveActivityWidget.swift` (`configureWidgetExtension`)

#### iOS — Live Activities
Everything is already wired in this repo; this is what it consists of, in case you replicate it in your own app:

- **LiveActivityWidget** target (Widget Extension, deployment target **iOS 17.2**, bundle id `com.example.flutterTestApp.LiveActivityWidget`). Its whole source is `MatchLiveActivityWidget.swift` — the Lock Screen and Dynamic Island views ship inside `PPG_LiveActivities`.
- `ios/Runner/Info.plist` carries `NSSupportsLiveActivities` and the `ppg-la` URL scheme (how `CLOSE` action buttons reach the SDK).
- The native `PPG_LiveActivities` module reaches both Runner and the widget through **Swift Package Manager**: the `pushpushgo_sdk` plugin declares it in its `Package.swift`, and the Xcode project attaches the `PPG_LiveActivities` product to the widget target (`PPG_framework` to NSE the same way).

> **Do not mix SPM and CocoaPods for the PPG modules.** CocoaPods links an app extension's pods into the host app as well, so declaring the same module on both paths makes the app load two copies of every class (`Class … is implemented in both …` at launch). If you run with Swift Package Manager disabled (`flutter config --no-enable-swift-package-manager`), the plugin arrives as a pod instead — `ios/Podfile` contains the ready, commented-out CocoaPods variant for that case.

Push-to-start does not work in the iOS Simulator: to see a real activity you need a physical device on iOS 17.2+ and a campaign created in the PPG dashboard.

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
├── main.dart                       # App entry point, SDK initialization, tab layout
├── buttons_view_model.dart         # ViewModel for Push Notifications tab
├── inapp_view_model.dart           # ViewModel for In-App Messages tab
└── live_activities_view_model.dart # ViewModel for Live Activities tab

flutter_test_app/ios/
└── LiveActivityWidget/             # Widget Extension rendering the Live Activity
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

### Live tab (`live_activities_view_model.dart`)
- **Check Support** — `isSupported()`; `true` on Android 16 (API 36)+ and iOS 17.2+ with the feature enabled for the app. Always gate your UI on it: on unsupported devices every other method is safe to call but does nothing.
- **Subscribe / Unsubscribe** — follow a live notification created in the PPG dashboard. After subscribing the backend starts, updates and ends the activity over push; the app does not drive the content. A device that subscribes to an already running campaign renders the current state immediately.
- **Is Active?** — `isActive(liveNotificationId)`, whether that campaign is rendered right now
- **Refresh** — `getActiveActivities()`; note that score / team / phase fields are Android only, iOS reports identifiers
- **Local Simulation** — **Android only.** `simulatePush(envelope)` feeds the SDK the exact envelope an FCM data message carries, so the whole parse → render pipeline runs without a backend campaign. iOS has no equivalent: there the activity is created by the OS from an APNs push-to-start and the app never sees the payload, so those buttons are disabled.

Lifecycle events arrive on `PPGLiveActivities.instance.statusStream` and are shown in the status box. Taps are handled by `setClickHandler` in `main.dart`, which reports the campaign id, the tapped element (`actionIndex`: `-1` body, `0`/`1` buttons) and its deep link.

### Custom Code Actions
When an In-App Message button uses a custom code action, the handler defined in `main.dart` fires a `SnackBar` with the received code. You can extend `_initialize()` in `_MyAppState` to handle any custom codes your campaign uses.

### Route auto-tracking
`InAppMessagesNavigatorObserver` is registered in `MaterialApp.navigatorObservers`, so any named-route navigation automatically notifies the In-App SDK. Routes must include a `RouteSettings(name: '...')` to be tracked.