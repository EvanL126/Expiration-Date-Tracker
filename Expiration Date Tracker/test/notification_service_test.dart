import 'package:expiration_date_tracker/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notification reminder time', () {
    test('uses 9 AM on a future reminder day', () {
      final result = NotificationService.nextReminderTime(
          DateTime(2026, 10, 20), 3, DateTime(2026, 10, 16, 18));

      expect(result, DateTime(2026, 10, 17, 9));
    });

    test('delivers shortly when todays 9 AM reminder was missed', () {
      final now = DateTime(2026, 10, 17, 14, 30);
      final result =
          NotificationService.nextReminderTime(DateTime(2026, 10, 20), 3, now);

      expect(result, now.add(const Duration(seconds: 5)));
    });

    test('delivers shortly when the reminder day is today before 9 AM', () {
      final now = DateTime(2026, 10, 17, 7, 30);
      final result =
          NotificationService.nextReminderTime(DateTime(2026, 10, 18), 1, now);

      expect(result, now.add(const Duration(seconds: 5)));
    });

    test('does not recreate a reminder from an earlier day', () {
      final result = NotificationService.nextReminderTime(
          DateTime(2026, 10, 20), 3, DateTime(2026, 10, 18, 10));

      expect(result, isNull);
    });
  });
}
