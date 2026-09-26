import 'package:flutter/material.dart';
import 'models/food_item.dart';

class Recipe {
  const Recipe(
      this.title, this.minutes, this.keywords, this.ingredients, this.steps);
  final String title;
  final int minutes;
  final List<String> keywords, ingredients, steps;
}

const recipes = [
  Recipe('Vegetable rice skillet', 20, [
    'spinach',
    'pepper',
    'carrot',
    'broccoli',
    'rice'
  ], [
    '2 cups chopped vegetables',
    '1 cup cooked rice',
    '1 tablespoon olive oil',
    '1 garlic clove, minced',
    'Salt and pepper'
  ], [
    'Wash and chop the vegetables.',
    'Heat the oil in a skillet. Add garlic and vegetables; cook for 5–8 minutes until tender.',
    'Stir in cooked rice and heat thoroughly. Season and serve.'
  ]),
  Recipe('Yogurt breakfast bowl', 5, [
    'yogurt',
    'berry',
    'berries',
    'banana',
    'apple'
  ], [
    '1 cup plain yogurt',
    '1 cup washed, chopped fruit',
    '¼ cup oats or granola'
  ], [
    'Spoon yogurt into a bowl.',
    'Top with fruit and oats or granola. Serve immediately.'
  ]),
  Recipe('Tomato and spinach pasta', 25, [
    'tomato',
    'spinach',
    'pasta'
  ], [
    '150 g dry pasta',
    '2 chopped tomatoes',
    '2 handfuls spinach',
    '1 tablespoon olive oil',
    '1 garlic clove, minced'
  ], [
    'Cook pasta according to its package directions; reserve a little cooking water.',
    'Heat oil and garlic in a pan. Add tomatoes and simmer for 8–10 minutes.',
    'Add washed spinach and cook until wilted. Toss with pasta and a splash of cooking water.'
  ]),
  Recipe('Banana oat pancakes', 15, [
    'banana',
    'egg',
    'oat'
  ], [
    '1 ripe banana',
    '2 eggs',
    '½ cup rolled oats',
    '1 teaspoon oil'
  ], [
    'Mash the banana and mix with eggs and oats.',
    'Heat oil in a nonstick pan over medium-low heat.',
    'Spoon in small pancakes. Cook for about 3 minutes per side until set throughout.'
  ]),
  Recipe('Chickpea cucumber salad', 10, [
    'chickpea',
    'cucumber',
    'tomato',
    'lemon'
  ], [
    '1 can chickpeas, drained and rinsed',
    '½ cucumber, diced',
    '1 tomato, diced',
    '1 tablespoon lemon juice',
    '1 tablespoon olive oil'
  ], [
    'Wash and dice the cucumber and tomato.',
    'Combine vegetables and chickpeas in a bowl.',
    'Toss with lemon juice and olive oil; season to taste.'
  ]),
];

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

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key, required this.recipe});
  final Recipe recipe;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(recipe.title)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text('${recipe.minutes} minutes • 2 servings'),
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
