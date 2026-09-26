import 'package:flutter/material.dart';
import '../models/food_item.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.items, required this.onDetail});
  final List<FoodItem> items;
  final ValueChanged<FoodItem> onDetail;
  @override
  Widget build(BuildContext context) {
    final alerts = items
        .where((i) => i.quantity > 0 && i.daysLeft <= 7)
        .toList()
      ..sort((a, b) => a.expiry.compareTo(b.expiry));
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Alerts',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Tap an alert for food guidance and recipe ideas.'),
      const SizedBox(height: 20),
      if (alerts.isEmpty)
        const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: Text('You are all caught up.'))),
      ...alerts.map((i) => Card(
          child: ListTile(
              onTap: () => onDetail(i),
              leading: CircleAvatar(
                  backgroundColor: i.daysLeft <= 3
                      ? const Color(0xFFFFE5E2)
                      : const Color(0xFFFFF2D6),
                  child: Icon(
                      i.daysLeft <= 3 ? Icons.priority_high : Icons.schedule)),
              title: Text('${i.name} • ${i.expiryLabel}'),
              subtitle: const Text('Use it soon or plan it into a meal.'),
              trailing: const Icon(Icons.chevron_right))))
    ]));
  }
}
