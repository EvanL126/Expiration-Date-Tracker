import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:expiration_date_tracker/models/food_item.dart';
import 'package:expiration_date_tracker/screens/item_detail_page.dart';
import 'package:expiration_date_tracker/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(AndroidFlutterLocalNotificationsPlugin.registerWith);
  test(
      'photo survives local persistence and edits without entering Firestore data',
      () {
    final photo = base64Encode([1, 2, 3]);
    final item = FoodItem(
        name: 'Spinach',
        category: 'Produce',
        expiry: DateTime(2026, 10, 20),
        location: 'Fridge',
        localPhoto: photo);
    final restored = FoodItem.fromJson(
        jsonDecode(jsonEncode(item.toJson(includeLocalPhoto: true)))
            as Map<String, dynamic>);
    expect(restored.localPhoto, photo);
    expect(restored.copyWith(name: 'Baby spinach').localPhoto, photo);
    expect(restored.toJson().containsKey('localPhoto'), isFalse);
    expect(restored.photoImage, isA<MemoryImage>());
  });

  testWidgets('alert recipe suggestion opens a real recipe', (tester) async {
    final item = FoodItem(
        name: 'Spinach',
        category: 'Produce',
        expiry: DateTime.now().add(const Duration(days: 2)),
        location: 'Fridge');
    await tester.pumpWidget(
        MaterialApp(home: ItemDetailPage(item: item, onEdit: () {})));
    await tester.scrollUntilVisible(find.text('Vegetable rice skillet'), 200);
    await tester.tap(find.text('Vegetable rice skillet'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.textContaining('added to your meal ideas'), findsNothing);
  });

  testWidgets('notification setup failures give feedback', (tester) async {
    const notifications =
        MethodChannel('dexterous.com/flutter/local_notifications');
    const timezone = MethodChannel('flutter_timezone');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        timezone, (_) async => throw PlatformException(code: 'unavailable'));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        notifications,
        (_) async => throw PlatformException(code: 'unavailable'));
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(notifications, null);
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(timezone, null);
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => NotificationService.enableAndTest(context),
                    child: const Text('Test'))))));
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(find.text('Could not send a notification. Please try again.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('denied notifications offer working settings shortcut',
      (tester) async {
    const notifications =
        MethodChannel('dexterous.com/flutter/local_notifications');
    const timezone = MethodChannel('flutter_timezone');
    const settings = MethodChannel('freshtrack/settings');
    var openedSettings = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        timezone, (_) async => throw PlatformException(code: 'unavailable'));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        notifications,
        (call) async => call.method == 'initialize' ? true : false);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(settings,
        (call) async {
      openedSettings = call.method == 'notifications';
      return null;
    });
    addTearDown(() {
      for (final channel in [notifications, timezone, settings]) {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => NotificationService.enableAndTest(context),
                    child: const Text('Test'))))));
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Notifications are disabled.'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(openedSettings, isTrue);
  });
}
