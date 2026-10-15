import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the tour dismissible even while the account's cloud save is pending.
class TutorialProgress {
  static String _key(String userId) => 'tutorial_completed_$userId';

  static Future<bool> isComplete(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key(userId)) ?? false;
  }

  static Future<void> complete(String userId,
      {required Future<void> Function() sync}) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(_key(userId), true)) {
      throw StateError('Could not save tutorial progress on this device.');
    }
    unawaited(_sync(sync));
  }

  static Future<void> _sync(Future<void> Function() sync) async {
    try {
      await sync();
    } catch (_) {
      // The account-scoped local flag remains authoritative on this device.
    }
  }
}
