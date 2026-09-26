class Recipe {
  const Recipe(
      this.title, this.minutes, this.keywords, this.ingredients, this.steps);
  final String title;
  final int minutes;
  final List<String> keywords, ingredients, steps;
}
