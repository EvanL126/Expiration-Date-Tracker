import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expiration_date_tracker/services/account_deletion.dart';

void main() {
  test('missing storage bucket does not block cleanup', () async {
    await deleteAccountPhotos(
      listPhotos: () async => throw FirebaseException(
          plugin: 'firebase_storage', code: 'bucket-not-found'),
      deletePhoto: (_) async => fail('No photos should be deleted'),
    );
  });
  test('missing photo does not prevent deleting remaining photos', () async {
    final deleted = <String>[];
    await deleteAccountPhotos(
        listPhotos: () async => ['gone', 'present'],
        deletePhoto: (path) async {
          if (path == 'gone') {
            throw FirebaseException(
                plugin: 'firebase_storage', code: 'object-not-found');
          }
          deleted.add(path);
        });
    expect(deleted, ['present']);
  });
  test('permission errors preserve login and identify photo failure', () async {
    var loginDeleted = false;
    await expectLater(
        runAccountDeletion(
          deletePhotos: () => deleteAccountPhotos(
            listPhotos: () async => throw FirebaseException(
                plugin: 'firebase_storage', code: 'unauthorized'),
            deletePhoto: (_) async {},
          ),
          deleteInventory: () async =>
              fail('Must stop before deleting inventory'),
          cancelReminders: () async {},
          deleteProfile: () async {},
          deleteLogin: () async {
            loginDeleted = true;
          },
        ),
        throwsA(isA<AccountDeletionException>()
            .having((e) => e.stage, 'stage', 'photo cleanup')
            .having((e) => e.code, 'code', 'unauthorized')));
    expect(loginDeleted, isFalse);
  });
  test('account login is deleted only after successful cleanup', () async {
    final steps = <String>[];
    await runAccountDeletion(
      deletePhotos: () async {
        steps.add('photos');
      },
      deleteInventory: () async {
        steps.add('inventory');
      },
      cancelReminders: () async {
        steps.add('reminders');
      },
      deleteProfile: () async {
        steps.add('profile');
      },
      deleteLogin: () async {
        steps.add('login');
      },
    );
    expect(steps, ['photos', 'inventory', 'reminders', 'profile', 'login']);
  });
}
