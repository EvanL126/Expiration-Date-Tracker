import 'package:firebase_core/firebase_core.dart';

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.stage, this.code);
  final String stage, code;

  String get message {
    final reason = switch (code) {
      'unauthorized' ||
      'permission-denied' =>
        'Firebase denied access. Check the deployed rules for your account.',
      'unauthenticated' ||
      'requires-recent-login' =>
        'Please log out, log in again, and retry.',
      'unavailable' ||
      'network-request-failed' ||
      'retry-limit-exceeded' =>
        'The service could not be reached. Check your connection and retry.',
      _ => 'Please retry. If this continues, share this error code.',
    };
    return 'Could not finish $stage ($code). $reason Your login has not been deleted. Some data may already have been removed.';
  }
}

/// Authenticate before calling this workflow. Keep account deletion last so
/// cleanup failures remain retryable with the user's existing credentials.
Future<void> runAccountDeletion({
  required Future<void> Function() deletePhotos,
  required Future<void> Function() deleteInventory,
  required Future<void> Function() cancelReminders,
  required Future<void> Function() deleteProfile,
  required Future<void> Function() deleteLogin,
}) async {
  final steps = [
    ('photo cleanup', deletePhotos),
    ('inventory cleanup', deleteInventory),
    ('reminder cleanup', cancelReminders),
    ('profile cleanup', deleteProfile),
    ('login deletion', deleteLogin),
  ];
  for (final step in steps) {
    try {
      await step.$2();
    } on FirebaseException catch (error) {
      throw AccountDeletionException(step.$1, error.code);
    } catch (_) {
      throw AccountDeletionException(step.$1, 'unexpected-error');
    }
  }
}

/// A project without a Storage bucket cannot contain uploaded item photos.
/// Missing objects also count as already cleaned up; permission failures do not.
Future<void> deleteAccountPhotos({
  required Future<List<String>> Function() listPhotos,
  required Future<void> Function(String) deletePhoto,
}) async {
  List<String> paths;
  try {
    paths = await listPhotos();
  } on FirebaseException catch (error) {
    if (error.code == 'bucket-not-found' || error.code == 'object-not-found') {
      return;
    }
    rethrow;
  }
  for (final path in paths) {
    try {
      await deletePhoto(path);
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}
