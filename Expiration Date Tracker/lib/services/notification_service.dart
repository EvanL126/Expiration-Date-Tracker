import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item.dart';

class NotificationService {
  static Future<void> cancelAll() => _plugin.cancelAll();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _details = NotificationDetails(
      android: AndroidNotificationDetails(
          'expiry_reminders', 'Expiry reminders',
          channelDescription: 'Reminders for items that are about to expire',
          importance: Importance.high,
          priority: Priority.high));
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
        settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  }

  static Future<void> requestPermission() async => _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
  static Future<void> schedule(FoodItem item) async {
    await cancel(item);
    if (item.quantity <= 0) return;
    for (final days in item.reminderDays) {
      final date =
          DateUtils.dateOnly(item.expiry).subtract(Duration(days: days));
      final when = tz.TZDateTime(tz.local, date.year, date.month, date.day, 9);
      if (when.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
            id: item.notificationId(days),
            title: 'FreshTrack reminder',
            body:
                '${item.name} expires in $days ${days == 1 ? 'day' : 'days'}.',
            scheduledDate: when,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: item.id);
      }
    }
  }

  static Future<void> cancel(FoodItem item) async {
    for (final days in [1, 3, 7]) {
      await _plugin.cancel(id: item.notificationId(days));
    }
  }
}
