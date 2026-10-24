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

  int _compareMatches((Recipe, List<FoodItem>) a, (Recipe, List<FoodItem>) b) {
    final countComparison = b.$2.length.compareTo(a.$2.length);
    if (countComparison != 0) return countComparison;
    final urgentComparison = b.$2
        .where((item) => item.daysLeft <= 3)
        .length
        .compareTo(a.$2.where((item) => item.daysLeft <= 3).length);
    if (urgentComparison != 0) return urgentComparison;
    if (a.$2.isNotEmpty && b.$2.isNotEmpty) {
      for (var i = 0; i < a.$2.length; i++) {
        final expiryComparison = a.$2[i].expiry.compareTo(b.$2[i].expiry);
        if (expiryComparison != 0) return expiryComparison;
      }
    }
    return a.$1.title.compareTo(b.$1.title);
  }

  @override
  Widget build(BuildContext context) {
    final ranked = recipes.map((recipe) => (recipe, _matches(recipe))).toList()
      ..sort(_compareMatches);
    return SafeArea(
        child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('Recipes', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
            'Recipes using the most items from your inventory are shown first. Ties favor more items expiring within 3 days, then the earliest expiry dates.'),
        if (items.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                  'Add inventory items to see ingredient matches. You can still browse every recipe.')),
        const SizedBox(height: 16),
        ...ranked.map((suggestion) {
          final recipe = suggestion.$1;
          final matches = suggestion.$2;
          final urgentCount = matches.where((item) => item.daysLeft <= 3).length;
          final matchLabel = matches.length == 1 ? 'match' : 'matches';
          return Card(
              child: ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: Text(recipe.title),
            subtitle: Text(
                '${recipe.minutes} min • 2 servings\n${matches.isEmpty ? 'No matching inventory items' : '${matches.length} inventory $matchLabel: ${matches.map((i) => i.name).join(', ')}'}${urgentCount > 0 ? '\n$urgentCount expiring within 3 days' : ''}'),
            trailing: const Icon(Icons.chevron_right),
            isThreeLine: urgentCount > 0,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => RecipeDetailPage(
                        recipe: recipe, inventoryItems: matches))),
          ));
        }),
      ],
    ));
  }
}
