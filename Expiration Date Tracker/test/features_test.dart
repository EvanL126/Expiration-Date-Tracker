import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expiration_date_tracker/screens/home_page.dart';
import 'package:expiration_date_tracker/screens/inventory_page.dart';
import 'package:expiration_date_tracker/screens/calendar_page.dart';
import 'package:expiration_date_tracker/models/food_item.dart';
import 'package:expiration_date_tracker/screens/recipes_page.dart';

FoodItem food(String name, String category, int days) => FoodItem(
    name: name,
    category: category,
    expiry: DateUtils.dateOnly(DateTime.now()).add(Duration(days: days)),
    location: 'Fridge');

void main() {
  testWidgets('inventory controls fit a narrow screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
                body: InventoryPage(
                    items: [
                  food('Very long vegetable ingredient name', 'Produce', 2)
                ],
                    onAdd: () {},
                    onEdit: (_) {},
                    onDelete: (_) {},
                    onQuantity: (_, amount) {})))));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Quantity: '));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.byType(TextField), -200,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();
    expect(find.textContaining('No matching items'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'vegetable');
    await tester.pump();
    expect(find.text('Very long vegetable ingredient name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category filter narrows inventory', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InventoryPage(
                items: [
          food('Spinach', 'Produce', 2),
          food('Yogurt', 'Dairy', 5)
        ],
                onAdd: () {},
                onEdit: (_) {},
                onDelete: (_) {},
                onQuantity: (_, amount) {}))));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dairy'));
    await tester.pump();
    expect(find.text('Yogurt'), findsOneWidget);
    expect(find.text('Spinach'), findsNothing);
  });

  testWidgets('dashboard score uses inventory freshness', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: HomePage(
                name: 'Tester',
                items: [
                  food('Spinach', 'Produce', 1),
                  food('Rice', 'Pantry', 20)
                ],
                onInventory: () {},
                onAdd: () {},
                onDetail: (_) {},
                onSettings: () {}))));
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Spinach'), findsOneWidget);
    expect(find.text('Rice'), findsNothing);
  });

  testWidgets('calendar changes month and selects expiration date',
      (tester) async {
    final now = DateTime.now();
    final item = FoodItem(
        name: 'Calendar item',
        category: 'Produce',
        expiry: DateTime(now.year, now.month, 15),
        location: 'Fridge');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CalendarPage(items: [item], onDetail: (_) {}))));
    await tester.tap(find.text('15'));
    await tester.pump();
    expect(
        find.text('Expirations on ${monthName(now.month)} 15'), findsOneWidget);
    expect(find.text('Calendar item'), findsOneWidget);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();
    expect(find.text('Calendar item'), findsNothing);
    expect(find.text('No expirations for this period.'), findsOneWidget);
  });

  testWidgets('recipes open ingredients and cooking steps', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home:
            Scaffold(body: RecipesPage(items: [food('Yogurt', 'Dairy', 1)]))));
    expect(find.textContaining('In your inventory: Yogurt'), findsOneWidget);
    await tester.tap(find.text('Yogurt breakfast bowl'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('Cooking steps'), findsOneWidget);
    expect(find.textContaining('Spoon yogurt into a bowl.'), findsOneWidget);
  });

  test('inventory serialization preserves edited values', () {
    final original = food('Spinach', 'Produce', 2).copyWith(quantity: 4);
    final restored = FoodItem.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.quantity, 4);
    expect(restored.expiry, original.expiry);
    expect(restored.reminderDays, original.reminderDays);
  });
}
