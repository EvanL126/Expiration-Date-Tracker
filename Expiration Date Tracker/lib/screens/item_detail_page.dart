import 'package:flutter/material.dart';
import '../models/food_item.dart';

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.item, required this.onEdit});
  final FoodItem item;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(item.name), actions: [
        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined))
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5F1),
                borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.expiryLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF08756E))),
              const SizedBox(height: 8),
              Text(
                  'Expires ${monthName(item.expiry.month)} ${item.expiry.day} • ${item.location}')
            ])),
        const SizedBox(height: 22),
        Text('Quantity guidance',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(item.quantityGuidance),
        const SizedBox(height: 24),
        Text('Recipe suggestions',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
            'Meal ideas based on this item. Find cooking steps in Recipes.'),
        const SizedBox(height: 10),
        ..._recipesFor(item).map((r) => Card(
            child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
                title: Text(r.$1),
                subtitle: Text(r.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${r.$1} added to your meal ideas'))))))
      ]));
}

List<(String, String)> _recipesFor(FoodItem item) => switch (item.category) {
      'Produce' => [
          (
            'Quick sauté',
            'Pair ${item.name} with garlic, olive oil, and grains.'
          ),
          ('Fresh salad', 'Toss ${item.name} into a bright, low-waste lunch.')
        ],
      'Dairy' => [
          ('Creamy pasta', 'Use ${item.name} in a quick sauce or topping.'),
          ('Breakfast bowl', 'Make a simple breakfast using ${item.name}.')
        ],
      _ => [
          (
            'Use-it-up bowl',
            'Build a flexible meal around ${item.name} and pantry staples.'
          ),
          ('Weekend prep', 'Turn ${item.name} into portions for the week.')
        ]
    };
