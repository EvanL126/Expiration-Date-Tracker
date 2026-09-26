import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../data/recipes.dart';
import 'recipe_detail_page.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key, required this.items});
  final List<FoodItem> items;

  List<FoodItem> _matches(Recipe recipe) => items
      .where((item) =>
          item.quantity > 0 &&
          item.daysLeft >= 0 &&
          recipe.keywords.any((word) => item.name.toLowerCase().contains(word)))
      .toList()
    ..sort((a, b) => a.expiry.compareTo(b.expiry));

  @override
  Widget build(BuildContext context) {
    final ranked = [...recipes]..sort((a, b) {
        final aItems = _matches(a), bItems = _matches(b);
        if (aItems.isEmpty && bItems.isEmpty) return a.title.compareTo(b.title);
        if (aItems.isEmpty) return 1;
        if (bItems.isEmpty) return -1;
        return aItems.first.expiry.compareTo(bItems.first.expiry);
      });
    return SafeArea(
        child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('Recipes', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
            'Simple meals, with matches to your soonest-expiring ingredients shown first.'),
        if (items.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  'Add inventory items to see ingredient matches. You can still browse every recipe.')),
        const SizedBox(height: 16),
        ...ranked.map((recipe) {
          final matches = _matches(recipe);
          return Card(
              child: ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: Text(recipe.title),
            subtitle: Text(
                '${recipe.minutes} min • 2 servings\n${matches.isEmpty ? 'Browse recipe' : 'In your inventory: ${matches.map((i) => i.name).join(', ')}'}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => RecipeDetailPage(recipe: recipe))),
          ));
        }),
      ],
    ));
  }
}
