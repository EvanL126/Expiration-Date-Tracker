# FreshTrack

FreshTrack is a Flutter app for tracking food expiration dates, planning how to use items before they spoil, and reducing household food waste.

## Features

- Create a secure email/password account with Firebase Authentication.
- Keep each account's profile and inventory in Cloud Firestore.
- Add optional item photos, stored privately in Firebase Storage.
- Add, edit, search, filter, and adjust quantities of inventory items.
- Scan a barcode with the device camera to start adding an item.
- Receive configurab  le expiry reminders.
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

## Inventory and meal planning

- Inventory is stored per signed-in user in Cloud Firestore and loaded on restart. An empty inventory stays empty; sample entries are not automatically inserted.
- Home calculates freshness as the percentage of stocked entries expiring in more than three days. Its attention list includes overdue entries and those due within three days.
- Inventory supports names, categories, dates, storage locations, quantities, editing, deletion, search, and category/location filters.
- Alerts lists stocked entries due within seven days, including overdue entries. Local notifications use the item's selected reminder days and require notification permission.
- Calendar supports month navigation, marked expiration dates, and selecting a day to inspect its items.
- Recipes includes five built-in recipes with ingredients and cooking steps. Available ingredient names are matched to recipes, with the earliest expiration matches first. No recipe API key is required.
- Bottom navigation provides Home, Alerts, Calendar, Inventory, and Recipes.

Firebase Authentication and Firestore must be configured and accessible for account-backed inventory. Widget tests cover layout, filters, dashboard calculations, calendar interaction, recipe navigation, and sign-up; they do not verify the live Firebase project or Android notification delivery.

## Dart source layout

- `lib/main.dart`: initializes Firebase and notifications, then starts the app.
- `lib/app.dart`: app theme and authentication entry point.
- `lib/screens/`: individual screens, authentication, and the bottom-navigation shell.
- `lib/widgets/`: reusable food cards, quick actions, and the add/edit item sheet.
- `lib/models/`: food items, user profiles, and recipes.
- `lib/services/`: Firebase inventory/account storage, photo storage, and notifications.
- `lib/data/`: built-in recipes and sample barcode mappings.

Each screen imports its dependencies directly. Run `flutter test` and `flutter analyze` from the Flutter project directory after making changes.

## Tutorial and account deletion

The first time an account without a saved tutorial-completion flag opens the app, FreshTrack shows a five-step tour. Both Skip and Get started save completion on the device for that account, then attempt to sync to Firestore in the background. A pending or failed cloud save does not block dismissal or show the intro again on that device. Until cloud sync succeeds, another device may still show the tour. Existing accounts without this flag also see the tour once. Settings includes an App tutorial option to replay it.

Settings > Delete account requires the current password and explicit confirmation. It reauthenticates before removing photos, inventory, and profile data, cancels reminders on this device, then deletes the Firebase Authentication account. Cleanup errors leave the login available for retry; deletion across Firebase services is not atomic, so some data may already be removed after a failure. Live deletion requires working Firestore and Storage access. Automated widget tests do not delete real accounts.
