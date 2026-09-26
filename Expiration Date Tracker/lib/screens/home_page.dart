import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../widgets/food_card.dart';
import '../widgets/quick_action.dart';

class HomePage extends StatelessWidget {
  const HomePage(
      {super.key,
      required this.name,
      required this.items,
      required this.onInventory,
      required this.onAdd,
      required this.onDetail,
      required this.onSettings});
  final String name;
  final List<FoodItem> items;
  final VoidCallback onInventory, onAdd, onSettings;
  final ValueChanged<FoodItem> onDetail;
  @override
  Widget build(BuildContext context) {
    final stocked = items.where((i) => i.quantity > 0).toList();
    final urgent = stocked.where((i) => i.daysLeft <= 3).toList()
      ..sort((a, b) => a.expiry.compareTo(b.expiry));
    final score = stocked.isEmpty
        ? null
        : (100 * stocked.where((i) => i.daysLeft > 3).length / stocked.length)
            .round();
    return SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
          Row(children: [
            const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFDDF4EF),
                child: Icon(Icons.person_outline, color: Color(0xFF08756E))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Good morning, $name',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Text('Let’s keep things fresh.')
                ])),
            IconButton(
                onPressed: onSettings,
                tooltip: 'Profile and settings',
                icon: const Icon(Icons.settings_outlined))
          ]),
          const SizedBox(height: 24),
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF08756E),
                  borderRadius: BorderRadius.circular(24)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your freshness score',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(score == null ? '—' : '$score%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                        'Share of stocked items fresh for more than 3 days',
                        style: TextStyle(color: Colors.white70)),
                    Text('${urgent.length} items need attention within 3 days',
                        style: const TextStyle(color: Colors.white))
                  ])),
          const SizedBox(height: 26),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Expiring soon',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: onInventory, child: const Text('View all'))
          ]),
          if (urgent.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nothing needs attention right now.')),
          ...urgent.map((i) => FoodCard(item: i, onTap: () => onDetail(i))),
          const SizedBox(height: 16),
          Text('Quick actions',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: QuickAction(
                    icon: Icons.add_box_outlined,
                    label: 'Add item',
                    onTap: onAdd)),
            const SizedBox(width: 12),
            Expanded(
                child: QuickAction(
                    icon: Icons.kitchen_outlined,
                    label: 'Inventory',
                    onTap: onInventory))
          ])
        ]));
  }
}
