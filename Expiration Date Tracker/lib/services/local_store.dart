import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';

class LocalStore {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static User get _user => _auth.currentUser!;
  static DocumentReference<Map<String, dynamic>> get _profile =>
      _firestore.collection('users').doc(_user.uid);
  static CollectionReference<Map<String, dynamic>> get _inventory =>
      _profile.collection('items');

  static Future<List<FoodItem>> loadItems() async {
    final snapshot = await _inventory.orderBy('expiry').get();
    return snapshot.docs
        .map((document) => FoodItem.fromJson(document.data()))
        .toList();
  }

  static Future<void> saveItems(List<FoodItem> items) async {
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
  }

  static Future<UserProfile?> loadProfile() async {
    if (_auth.currentUser == null) return null;
    final snapshot = await _profile.get();
    return snapshot.exists ? UserProfile.fromJson(snapshot.data()!) : null;
  }

  static Future<void> register(UserProfile profile, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: profile.email.trim(), password: password);
    try {
      await credential.user!.updateDisplayName(profile.name);
      await _firestore.collection('users').doc(credential.user!.uid).set({
        ...profile.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Authentication has already succeeded; retrying sign-up would create
      // an email-already-in-use error instead of completing profile setup.
      throw FirebaseAuthException(code: 'profile-setup-failed');
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
    await _profile.set({
      ...profile.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> signOut() => _auth.signOut();
}
