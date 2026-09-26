import 'package:flutter/material.dart';
import '../models/recipe.dart';

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
