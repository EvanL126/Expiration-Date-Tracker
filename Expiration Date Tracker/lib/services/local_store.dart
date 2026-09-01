import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';

class LocalStore {
  static const _inventoryKey = 'inventory';
  static const _profileKey = 'profile';
  static const _passwordKey = 'password';

  static Future<List<FoodItem>> loadItems() async {
    final value =
        (await SharedPreferences.getInstance()).getString(_inventoryKey);
    if (value == null) return [];
    return (jsonDecode(value) as List)
        .cast<Map<String, dynamic>>()
        .map(FoodItem.fromJson)
        .toList();
  }

  static Future<void> saveItems(List<FoodItem> items) async =>
      (await SharedPreferences.getInstance()).setString(_inventoryKey,
          jsonEncode(items.map((item) => item.toJson()).toList()));
  static Future<UserProfile?> loadProfile() async {
    final value =
        (await SharedPreferences.getInstance()).getString(_profileKey);
    return value == null
        ? null
        : UserProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  static Future<void> register(UserProfile profile, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await prefs.setString(_passwordKey, password);
  }

  static Future<bool> authenticate(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await loadProfile();
    return profile != null &&
        profile.email.toLowerCase() == email.trim().toLowerCase() &&
        prefs.getString(_passwordKey) == password;
  }

  static Future<void> updateProfile(UserProfile profile) async =>
      (await SharedPreferences.getInstance())
          .setString(_profileKey, jsonEncode(profile.toJson()));
}
