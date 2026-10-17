import 'recipes_page.dart';
import '../data/recipes.dart';
import 'recipe_detail_page.dart';
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
        if (item.photoImage != null) ...[
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image(
                  image: item.photoImage!, height: 180, fit: BoxFit.cover)),
          const SizedBox(height: 16),
        ],
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
        const Text('Tap a recipe to see ingredients and cooking steps.'),
        const SizedBox(height: 10),
        ...recipes
            .where((recipe) => recipe.keywords
                .any((word) => item.name.toLowerCase().contains(word)))
            .map((recipe) => Card(
                child: ListTile(
                    leading:
                        const CircleAvatar(child: Icon(Icons.restaurant_menu)),
                    title: Text(recipe.title),
                    subtitle: Text('${recipe.minutes} minutes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => RecipeDetailPage(
                                recipe: recipe,
                                inventoryItems:
                                    item.quantity > 0 && item.daysLeft >= 0
                                        ? [item]
                                        : [])))))),
        TextButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => RecipesPage(items: [item]))),
            child: const Text('Browse all recipes')),
      ]));
}
