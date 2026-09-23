# Firebase push notifications setup

Use this guide to create the Firebase project and collect the Android / iOS files needed before FCM is implemented in the LMS mobile app.

## App IDs

Register these exact IDs in Firebase. Do not change them if you want this current app to receive notifications.

| Platform | Value |
|---|---|
| Android package name | `com.example.lmssystem` |
| iOS bundle ID | `com.example.lmssystem` |

## 1. Create the Firebase project

1. Open [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** (or **Create a project**)
3. Project name: `School LMS` (or similar)
4. Google Analytics: **Disable** for now (not required for push)
5. Click **Create project** → **Continue**

## 2. Enable Cloud Messaging

1. In the project, open the gear icon → **Project settings**
2. Open the **Cloud Messaging** tab and confirm it is available
3. You do not need the old “Server key”. Laravel will use a **service account** later

## 3. Add the Android app

1. Project overview → **Add app** → **Android**
2. Android package name: `com.example.lmssystem`
3. App nickname: `LMS Android`
4. Debug SHA-1: optional for now (needed later for some Google login features, not for basic FCM)
5. Register the app
6. Download **`google-services.json`**
7. Keep that file. Do not skip this download

## 4. Add the iOS app

1. Project overview → **Add app** → **iOS**
2. iOS bundle ID: `com.example.lmssystem`
3. App nickname: `LMS iOS`
4. App Store ID: leave empty
5. Register the app
6. Download **`GoogleService-Info.plist`**
7. Keep that file

iOS push will not work on a real iPhone until Apple Push (APNs) is connected:

1. You need a paid **Apple Developer** account
2. In [Apple Developer](https://developer.apple.com/account) → **Keys** → create a key with **Apple Push Notifications service (APNs)**
3. Download the `.p8` file **once**
4. Note:
   - **Key ID**
   - **Team ID** (Membership page)
5. In Firebase → Project settings → **Cloud Messaging** → **Apple app configuration**
6. Upload the `.p8` and enter Key ID + Team ID

If you do not have an Apple Developer account yet, Android can still be implemented first.

## 5. Get the server file (Laravel later)

1. Firebase → gear → **Project settings** → **Service accounts**
2. Click **Generate new private key**
3. Download the JSON (name looks like `school-lms-firebase-adminsdk-xxxxx.json`)
4. This file is a secret. Do **not** commit it to git or paste it in chat. Keep it for the Laravel server later

## Files and values to collect

Put these two app files in the project (or keep them ready to add):

| Platform | File | Where it belongs later |
|---|---|---|
| Android | `google-services.json` | `android/app/google-services.json` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

Also note:

- Firebase **project ID** (Project settings → General)
- Whether iOS APNs is uploaded (**yes / not yet**)
- Whether to start with **Android only** or **Android + iOS**

Do **not** send the Firebase Admin SDK private key in chat. Keep that for Laravel when sending is added from the web/API.
