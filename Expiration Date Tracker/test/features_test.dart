import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expiration_date_tracker/screens/home_page.dart';
import 'package:expiration_date_tracker/screens/inventory_page.dart';
import 'package:expiration_date_tracker/screens/calendar_page.dart';
import 'package:expiration_date_tracker/models/food_item.dart';
import 'package:expiration_date_tracker/screens/recipes_page.dart';
import 'package:expiration_date_tracker/widgets/add_item_sheet.dart';

FoodItem food(String name, String category, int days) => FoodItem(
    name: name,
    category: category,
    expiry: DateUtils.dateOnly(DateTime.now()).add(Duration(days: days)),
    location: 'Fridge');

void main() {
  testWidgets('add item form separates barcode scanning from item details',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => FilledButton(
                    onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const AddItemSheet()),
                    child: const Text('Add'))))));

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(find.text('Item details'), findsOneWidget);
    expect(find.textContaining('match its barcode'), findsOneWidget);
  });

  testWidgets('unknown barcode is not copied into the item name',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AddItemSheet(scanBarcode: (_) async => '999999999999'))));

    await tester.tap(find.text('Scan barcode'));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    expect(nameField.controller?.text, isEmpty);
    expect(find.text('Barcode: 999999999999'), findsOneWidget);
    expect(find.textContaining('Scanned item'), findsNothing);
    expect(find.textContaining('Enter the product name'), findsOneWidget);
  });

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

  testWidgets('scanned items have a separate barcode section', (tester) async {
    final scanned = FoodItem(
        name: 'Greek yogurt',
        category: 'Dairy',
        expiry: DateTime.now().add(const Duration(days: 5)),
        location: 'Fridge',
        barcode: '041383090011');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InventoryPage(
                items: [scanned, food('Spinach', 'Produce', 2)],
                onAdd: () {},
                onEdit: (_) {},
                onDelete: (_) {},
                onQuantity: (_, __) {}))));

    expect(find.text('Scanned barcodes'), findsOneWidget);
    expect(find.text('Other inventory'), findsOneWidget);
    expect(find.text('Barcode: 041383090011'), findsOneWidget);
  });

  testWidgets('asks whether to remove an item when quantity reaches zero',
      (tester) async {
    final item = food('Yogurt', 'Dairy', 5);
    FoodItem? deleted;
    var quantityChange = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InventoryPage(
                items: [item],
                onAdd: () {},
                onEdit: (_) {},
                onDelete: (value) => deleted = value,
                onQuantity: (_, amount) => quantityChange = amount))));

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Yogurt?'), findsOneWidget);
    expect(find.textContaining('quantity of 0'), findsOneWidget);

    await tester.tap(find.text('Keep item'));
    await tester.pumpAndSettle();
    expect(deleted, isNull);
    expect(quantityChange, -1);
  });

  testWidgets('removes an item when zero-quantity removal is confirmed',
      (tester) async {
    final item = food('Yogurt', 'Dairy', 5);
    FoodItem? deleted;
    var quantityChanged = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InventoryPage(
                items: [item],
                onAdd: () {},
                onEdit: (_) {},
                onDelete: (value) => deleted = value,
                onQuantity: (_, __) => quantityChanged = true))));

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove item'));
    await tester.pumpAndSettle();

    expect(deleted, same(item));
    expect(quantityChanged, isFalse);
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
    expect(find.textContaining('1 inventory match: Yogurt'), findsWidgets);
    await tester.tap(find.text('Yogurt breakfast bowl'));
    await tester.pumpAndSettle();
    expect(find.text('From your inventory'), findsOneWidget);
    expect(find.textContaining('Yogurt — expires in 1 day'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('Cooking steps'), findsOneWidget);
    expect(find.textContaining('Spoon yogurt into a bowl.'), findsOneWidget);
  });

  testWidgets('recipes using more inventory items are ranked first',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: RecipesPage(items: [
      food('Spinach', 'Produce', 2),
      food('Tomato', 'Produce', 4),
      food('Pasta', 'Pantry', 30),
    ]))));

    final strongestMatch =
        tester.getTopLeft(find.text('Tomato and spinach pasta'));
    final oneItemMatch = tester.getTopLeft(find.text('Vegetable rice skillet'));
    expect(strongestMatch.dy, lessThan(oneItemMatch.dy));
    expect(find.textContaining('3 inventory matches: Spinach, Tomato, Pasta'),
        findsOneWidget);
  });

  test('inventory serialization preserves edited values', () {
    final original = food('Spinach', 'Produce', 2)
        .copyWith(quantity: 4, barcode: '123456789012');
    final restored = FoodItem.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.quantity, 4);
    expect(restored.expiry, original.expiry);
    expect(restored.reminderDays, original.reminderDays);
    expect(restored.barcode, '123456789012');
  });
}
