# FreshTrack

FreshTrack is a Flutter app for tracking food expiration dates, planning how to use items before they spoil, and reducing household food waste.

## Features

- Create a secure email/password account with Firebase Authentication.
- Keep each account's profile and inventory in Cloud Firestore.
- Add optional item photos, stored privately in Firebase Storage.
- Add, edit, search, filter, and adjust quantities of inventory items.
- Scan a barcode with the device camera to start adding an item.
- Receive configurable expiry reminders.
- Open expiring items from the Home screen, Alerts, or Calendar for details.
- Get quantity guidance and recipe suggestions for food that needs using soon.

## Run the app

1. Install Flutter and connect an Android device or start an emulator.
2. From this project directory, run `flutter pub get`.
3. Run `flutter run`.

The barcode scanner requires camera permission on a physical Android device.

## Firebase setup

This app is configured for the Firebase project `expiration-date-tracker-574f3`
and Android package `com.expirationdatetracker.app`.

Before the first run, register that Android package in Firebase Console and
download its `google-services.json` file into `android/app/`. In the Firebase
Console, enable **Email/Password** under Authentication, create a **Cloud
Firestore** database, and create the default **Storage** bucket. Deploy the
included `firestore.rules` and `storage.rules` after signing in with the Firebase
CLI:

```text
firebase deploy --only firestore:rules,storage
```

The rules restrict profiles, inventory documents, and item photos to their
authenticated owner. Item photos must be images smaller than 10 MB.
