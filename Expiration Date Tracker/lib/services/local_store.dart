import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'account_deletion.dart';
import 'tutorial_progress.dart';

class LocalStore {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static bool _cloudAvailable = true;
  static User get _user => _auth.currentUser!;
  static DocumentReference<Map<String, dynamic>> get _profile =>
      _firestore.collection('users').doc(_user.uid);
  static CollectionReference<Map<String, dynamic>> get _inventory =>
      _profile.collection('items');

  static String get _itemsKey => 'inventory_${_user.uid}';
  static String get _profileKey => 'profile_${_user.uid}';

  static bool _isMissingDatabase(Object error) =>
      error is FirebaseException && error.code == 'not-found';

  static Future<void> _saveItemsLocally(List<FoodItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
        _itemsKey,
        items
            .map((item) => jsonEncode(item.toJson(includeLocalPhoto: true)))
            .toList());
  }

  static Future<List<FoodItem>> _loadItemsLocally() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_itemsKey) ?? [])
        .map((item) =>
            FoodItem.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.expiry.compareTo(b.expiry));
  }

  static Future<void> _saveProfileLocally(UserProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
        _profileKey,
        jsonEncode({
          ...profile.toJson(),
          'tutorialCompleted': profile.tutorialCompleted
        }));
  }

  static Future<UserProfile?> _loadProfileLocally() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_profileKey);
    return saved == null
        ? null
        : UserProfile.fromJson(jsonDecode(saved) as Map<String, dynamic>);
  }

  static Future<List<FoodItem>> loadItems() async {
    if (!_cloudAvailable) return _loadItemsLocally();
    try {
      final snapshot = await _inventory.orderBy('expiry').get();
      final items = snapshot.docs
          .map((document) => FoodItem.fromJson(document.data()))
          .toList();
      final cached = {
        for (final item in await _loadItemsLocally()) item.id: item
      };
      final merged = items
          .map((item) => item.copyWith(localPhoto: cached[item.id]?.localPhoto))
          .toList();
      await _saveItemsLocally(merged);
      return merged;
    } catch (error) {
      if (_isMissingDatabase(error)) _cloudAvailable = false;
      return _loadItemsLocally();
    }
  }

  static Future<void> saveItems(List<FoodItem> items) async {
    await _saveItemsLocally(items);
    if (!_cloudAvailable) return;
    try {
      final existing = await _inventory.get();
      final ids = items.map((item) => item.id).toSet();
      final batch = _firestore.batch();
      for (final item in items) {
        batch.set(_inventory.doc(item.id), item.toJson());
      }
      for (final document
          in existing.docs.where((doc) => !ids.contains(doc.id))) {
        batch.delete(document.reference);
      }
      await batch.commit();
    } catch (error) {
      if (_isMissingDatabase(error)) _cloudAvailable = false;
    }
  }

  static Future<UserProfile?> loadProfile() async {
    if (_auth.currentUser == null) return null;
    if (!_cloudAvailable) return _loadProfileLocally();
    try {
      final snapshot = await _profile.get();
      final profile =
          snapshot.exists ? UserProfile.fromJson(snapshot.data()!) : null;
      if (profile != null) await _saveProfileLocally(profile);
      return profile;
    } catch (error) {
      if (_isMissingDatabase(error)) _cloudAvailable = false;
      return _loadProfileLocally();
    }
  }

  static Future<void> register(UserProfile profile, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: profile.email.trim(), password: password);
    await credential.user!.updateDisplayName(profile.name);
    await _saveProfileLocally(profile);
    try {
      await _firestore.collection('users').doc(credential.user!.uid).set({
        ...profile.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (_isMissingDatabase(error)) _cloudAvailable = false;
    }
  }

  static Future<bool> authenticate(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  static Future<void> updateProfile(UserProfile profile) async {
    await _user.updateDisplayName(profile.name);
    await _saveProfileLocally(profile);
    if (!_cloudAvailable) return;
    try {
      await _profile.set({
        ...profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (_isMissingDatabase(error)) _cloudAvailable = false;
    }
  }

  static Future<void> signOut() => _auth.signOut();

  static Future<bool> hasCompletedTutorial() =>
      TutorialProgress.isComplete(_user.uid);

  static Future<void> completeTutorial() {
    final userId = _user.uid;
    final profile = _firestore.collection('users').doc(userId);
    return TutorialProgress.complete(userId, sync: () async {
      if (!_cloudAvailable) return;
      await profile.set({'tutorialCompleted': true}, SetOptions(merge: true));
    });
  }

  static Future<void> deleteAccount(String password) async {
    final user = _user;
    await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password));
    final profile = _firestore.collection('users').doc(user.uid);
    await runAccountDeletion(
      deletePhotos: () => deleteAccountPhotos(
        listPhotos: () async {
          final files = await FirebaseStorage.instance
              .ref('users/${user.uid}/items')
              .listAll();
          return files.items.map((file) => file.fullPath).toList();
        },
        deletePhoto: (path) => FirebaseStorage.instance.ref(path).delete(),
      ),
      deleteInventory: () async {
        while (true) {
          final page = await profile.collection('items').limit(400).get();
          if (page.docs.isEmpty) break;
          final batch = _firestore.batch();
          for (final doc in page.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      },
      cancelReminders: NotificationService.cancelAll,
      deleteProfile: () async {
        await profile.delete();
        final preferences = await SharedPreferences.getInstance();
        for (final key in [
          'inventory_${user.uid}',
          'profile_${user.uid}',
          'tutorial_completed_${user.uid}',
        ]) {
          if (!await preferences.remove(key)) {
            throw StateError('Could not remove cached account data.');
          }
        }
      },
      deleteLogin: user.delete,
    );
  }
}
