import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadItemPhoto({
    required String itemId,
    required File image,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in before uploading a photo.');
    final reference = _storage.ref('users/${user.uid}/items/$itemId.jpg');
    await reference.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    return reference.getDownloadURL();
  }

  static Future<void> deleteItemPhoto(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _storage.ref('users/${user.uid}/items/$itemId.jpg').delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}
