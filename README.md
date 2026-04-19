# Backpackr

A professional social network for travelers and backpackers.

## 🚀 Getting Started

### 1. Environment Variables
The app uses `flutter_dotenv` for sensitive configuration (AWS, IAP).
1. Copy `.env.example` to `.env`.
2. Fill in your AWS and In-App Purchase product IDs.

### 2. Firebase Setup (Required for Backend)
For security, the native Firebase configuration files are **not** included in this repository. You must provide your own:

#### Android
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Add an Android app with package name `com.backpackr`.
3. Download `google-services.json` and place it in `android/app/`.
   * (Refer to `android/app/google-services.json.example` for the required structure).

#### iOS
1. Add an iOS app with bundle ID `com.backpackr` in the Firebase Console.
2. Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
   * (Refer to `ios/Runner/GoogleService-Info.plist.example` for the required structure).

## 🛡️ Security & Privacy
This project follows strict security guidelines:
*   **No API Keys in Git**: Sensitive keys are managed via `.env`.
*   **Native Privacy**: Firebase configuration files are strictly ignored by `.gitignore`.

---

## Technical Note: Gradle Setup
If you are setting up the Android project from scratch, ensure your Gradle files include the following:

### `android/app/build.gradle.kts`
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

### `android/build.gradle.kts`
```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```