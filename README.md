# Alarm Clock App

A Flutter alarm clock app with Firebase authentication, Cloud Firestore sync, local cache, and scheduled local notifications.

## Features

- Email/password authentication with Firebase Auth
- Per-user alarm storage in Cloud Firestore
- Offline cache using `shared_preferences`
- Real-time alarm sync across devices
- Local alarm scheduling with `flutter_local_notifications`
- Add, edit, delete, and enable/disable alarms

## Setup

1. Install Flutter and ensure `flutter doctor` is green.
2. Add Firebase configuration files to the project:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
3. Enable Firebase Authentication and Cloud Firestore in your Firebase console.
4. Run:

```bash
flutter pub get
```

## Running

```bash
flutter run
```

## Notes

- The app saves alarms locally and syncs them to Firestore when a user is signed in.
- Disabled alarms are automatically canceled.
- Cloud Firestore documents are stored under `users/{uid}/alarms/{alarmId}`.

## Firebase structure

```
users/
  {uid}/
    alarms/
      {alarmId}/
        label: "Wake Up"
        scheduledAt: "2026-06-09T07:00:00.000"
        isEnabled: true
        createdAt: "2026-06-09T07:00:00.000"
```
