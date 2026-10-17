import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item.dart';

class NotificationService {
  static Future<void> cancelAll() => _plugin.cancelAll();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const _details = NotificationDetails(
      android: AndroidNotificationDetails(
          'expiry_reminders', 'Expiry reminders',
          channelDescription: 'Reminders for items that are about to expire',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_expiry'));
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Notification initialization should still succeed on devices that do
      // not return a recognized IANA timezone.
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
        settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_stat_expiry')));
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (!_initialized) await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    if (await android.areNotificationsEnabled() ?? false) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  static Future<bool> showTestNotification() async {
    if (!await requestPermission()) return false;
    await _plugin.show(
        id: 2147483000,
        title: 'FreshTrack notifications are working',
        body: 'You will receive reminders for the days selected on each item.',
        notificationDetails: _details);
    return true;
  }

  static Future<void> enableAndTest(BuildContext context) async {
    try {
      final enabled = await showTestNotification();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(enabled
              ? 'Test notification sent.'
              : 'Notifications are disabled. Enable expiry reminders in Android settings.'),
          action: enabled
              ? null
              : SnackBarAction(
                  label: 'Settings',
                  onPressed: () async {
                    try {
                      await const MethodChannel('freshtrack/settings')
                          .invokeMethod<void>('notifications');
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Open Android Settings > Apps > Expiration Date Tracker > Notifications.')));
                      }
                    }
                  })));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not send a notification. Please try again.')));
      }
    }
  }

  /// Returns the next useful reminder time. A reminder whose trigger date is
  /// today is delivered shortly; future reminder dates are delivered at 9 AM.
  @visibleForTesting
  static DateTime? nextReminderTime(
      DateTime expiry, int daysBefore, DateTime now) {
    final reminderDate =
        DateUtils.dateOnly(expiry).subtract(Duration(days: daysBefore));
    if (DateUtils.isSameDay(reminderDate, now)) {
      return now.add(const Duration(seconds: 5));
    }
    final scheduled =
        DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 9);
    if (scheduled.isAfter(now)) return scheduled;
    return null;
  }

  static Future<void> schedule(FoodItem item) async {
    if (!_initialized) await initialize();
    await cancel(item);
    if (item.quantity <= 0) return;
    for (final days in item.reminderDays) {
      final localWhen = nextReminderTime(item.expiry, days, DateTime.now());
      if (localWhen != null) {
        final when = tz.TZDateTime(tz.local, localWhen.year, localWhen.month,
            localWhen.day, localWhen.hour, localWhen.minute, localWhen.second);
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
