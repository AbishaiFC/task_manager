# Task Manager — Offline-First Flutter App

Android-only Flutter application that manages tasks with local SQLite persistence
and bidirectional synchronization with Firebase (Auth + Cloud Firestore).

## Architecture

Single Source of Truth: SQLite is the only source of truth for the UI. All reads
come from local streams; Firebase is only used by the Sync Service.

```
UI (Flutter) -> streams -> SQLite -> SyncService -> Firebase
```

## Setup

1. Install Flutter 3.47+ and Android SDK.
2. Configure Firebase:
   - Create a Firebase project.
   - Enable Email/Password Authentication.
   - Create a Cloud Firestore database.
   - Register an Android app with package name `com.apren.taskmanager.task_manager`.
   - Download `google-services.json` and replace `android/app/google-services.json`.
3. Run:
   ```bash
   flutter pub get
   flutter run
   ```

## Firestore security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Build

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

## Tests

```bash
flutter analyze
flutter test
```
