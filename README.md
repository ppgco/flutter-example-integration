# flutter-example-integration
Example of integration PPG flutter sdk with Flutter application

## Description
This is a test app that you can test integration with PPG sdk on. To do so, follow instructions provided below.
Note: Test app supports integration on platforms: **iOS / Android**

## Requirements
- PPG project
- Access to Firebase Console
- Access to Apple Developers console

**Approximate time of installation to run test app - 30 min**

## Installation
1. Clone repo
2. Login into your PPG project
3. Collect your project ID and API KEY (to generate API KEY navigate to https://next.pushpushgo.com/organization/yourOrganizationID/access-manager/api-keys)
4. Open repo in Android Studio
5. Open lib/main.dart file and provide project id and api key in code:
    ```dart
        final pushpushgo = PushpushgoSdk({
          "apiToken": "YOUR API KEY",
          "projectId": "YOUR PROJECT ID",
        });
    ```
### Android
1. Install Firebase CLI - open terminal and run command:
    ```bash
    $ curl -sL https://firebase.tools | bash
    ```
2. Install FlutterFire CLI - open terminal and run command:
    ```bash
   $ dart pub global activate flutterfire_cli
    ```
3. In terminal login to firebase:
    ```bash
   $ firebase login
    ```
4. Navigate to root of your Flutter project and run:
    ```bash
   $ flutterfire configure --project=your-firebase-project-id
    ```
   Follow instructions provided in terminal.
   Note: If you cant use flutterfire command, add **export PATH="$PATH":"$HOME/.pub-cache/bin"** to your .zshrc file
5. Open Android folder in your Flutter project and synchronize files
6. Generate FCM v1 credentials and upload it in PPG APP:
   * Go to your Firebase console and navigate to project settings
   * Open Cloud Messaging tab
   * Click Manage Service Accounts
   * Click on your service account email
   * Navigate to KEYS tab
   * Click ADD KEY
   * Click CREATE NEW KEY
   * Pick JSON type and click create
   * Download file and upload it in PushPushGo Application (https://next.pushpushgo.com/projects/YourProjectID/settings/integration/fcm)

### iOS
Generate certificate and upload it - https://docs.pushpushgo.company/application/providers/mobile-push/apns
IMPORTANT - While generating certificate, you should provide the same bundle ID as it is provided in Xcode.
In case of this test app, unless changed your cert should match bundle ID - **com.example.flutterTestApp**

### Common
Navigate to root of your Flutter project and run:
```bash
$ flutter pub get
```

To run ios part - in Xcode open ios/Runner.xcworkspace and press CMD + R (make sure Runner is active scheme)
To run android - in Android studio open android/ then build and run app