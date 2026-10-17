import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage(
      {super.key, required this.recipe, this.inventoryItems = const []});
  final Recipe recipe;
  final List<FoodItem> inventoryItems;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(recipe.title)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('${recipe.minutes} minutes • 2 servings'),
          if (inventoryItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
                color: const Color(0xFFE8F5F1),
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From your inventory',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...inventoryItems.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                  '• ${item.name} — ${item.expiryLabel.toLowerCase()}')))
                        ])))
          ],
          const SizedBox(height: 20),
          Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
          ...recipe.ingredients.map((ingredient) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('• $ingredient'))),
          const SizedBox(height: 20),
          Text('Cooking steps', style: Theme.of(context).textTheme.titleLarge),
          ...recipe.steps.indexed.map((step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('${step.$1 + 1}. ${step.$2}'))),
        ]),
      );
}
