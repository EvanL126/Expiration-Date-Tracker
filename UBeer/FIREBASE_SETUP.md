# Firebase cloud backups

Target project: `beer-b74cb` (Beer). Registered Android application: `com.example.ubeer`, nickname UBeer Wholesale POS.

## Activation

1. In Firebase Project settings > General > UBeer Wholesale POS, download `google-services.json`. Save it in `app/google-services.json`. This file is ignored by Git. The old file in Downloads is for a different project/package and must not be used.
2. A project owner must create a **Cloud Firestore Standard** database. Choose production/locked mode. Do not use open test rules.
3. In Firebase Authentication, enable **Email/Password**. The project/account owner must handle any terms acceptance presented by Firebase.
4. Publish the contents of `firestore.rules` in Firestore > Rules. These rules allow a signed-in user to create and read only their own immutable backups under `users/{uid}/backups`. No public access or other users' backup access is allowed. Rules are prepared locally and have not been published by this task.
5. Build/install the updated APK. In Settings > Cloud backup, create an app cloud account or sign in. This is separate from your Firebase console Google login. Use that same app account to retrieve backups from another Android device.
6. Choose **Back up to cloud**, then wait for the success confirmation. Confirm in Firestore that the backup manifest and chunks exist. Use a separate test device/data set to check restore before relying on it.

## Behavior

This version provides manual backup and restore, not automatic or simultaneous multi-device sync. Device data remains local until the user explicitly uploads a backup. It includes invoices, customer details including Tax IDs, payments, products, categories, draft sale, and settings. Passwords and Firebase session credentials are not included.

Each backup is an immutable snapshot with an atomic manifest/chunk write. Success is reported only after the server accepts it. The SHA-256 checksum is checked before a downloaded snapshot is offered for restore. The latest 20 backups are listed, but older ones remain in Firebase. No cloud backups are deleted automatically. Backup size is limited to 6 MiB; larger data sets must use local export. Firebase usage/quota/billing belongs to the project owner.

Restore requires confirmation, validates the data, stops if local data changed during download, and saves a local recovery copy before replacement. Settings includes a recovery action. Only the most recent pre-restore copy is retained. Uninstalling or clearing app storage can remove that recovery copy.

## Verification state

App registration was verified in the Firebase console. The console showed insufficient Firestore management permissions for the signed-in account, and Authentication could not load its terms acceptance status. Database/provider/rules activation and a real upload/restore round trip remain unverified. The application deliberately shows configuration/setup errors rather than claiming cloud data is saved.
