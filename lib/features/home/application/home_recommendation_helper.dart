import 'package:flutter_application_1/features/recipes/models/recipe.dart';

class ShoppingListItem {
  final String name;
  final int recipeCount;

  const ShoppingListItem({required this.name, required this.recipeCount});
}

class HomeRecommendationHelper {
  static List<Recipe> recommendedRecipes({
    required List<Recipe> recipes,
    required Set<String> selectedIngredients,
    int limit = 6,
  }) {
    if (selectedIngredients.isEmpty) {
      final fallback = List<Recipe>.from(recipes)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return fallback.take(limit).toList();
    }

    final scores = <String, int>{};

    int scoreFor(Recipe recipe) {
      return scores.putIfAbsent(
        recipe.id,
        () => _matchScore(
          recipe: recipe,
          selectedIngredients: selectedIngredients,
        ),
      );
    }

    final matched = recipes.where((recipe) => scoreFor(recipe) > 0).toList()
      ..sort((a, b) {
        final scoreCompare = scoreFor(b).compareTo(scoreFor(a));
        if (scoreCompare != 0) return scoreCompare;

        final ratingCompare = b.ratingAverage.compareTo(a.ratingAverage);
        if (ratingCompare != 0) return ratingCompare;

        return b.createdAt.compareTo(a.createdAt);
      });

    return matched.take(limit).toList();
  }

  static List<ShoppingListItem> shoppingList({
    required List<Recipe> recipes,
    required Set<String> pantryIngredients,
    int recipeLimit = 3,
  }) {
    if (recipes.isEmpty) return const <ShoppingListItem>[];

    final counts = <String, int>{};
    final labels = <String, String>{};
    final normalizedPantry = pantryIngredients.map(_normalizeText).toSet();

    for (final recipe in recipes.take(recipeLimit)) {
      final seenInRecipe = <String>{};

      for (final ingredient in recipe.ingredientNames) {
        final normalizedIngredient = _normalizeText(ingredient);
        if (normalizedIngredient.isEmpty) continue;
        if (_matchesAny(normalizedIngredient, normalizedPantry)) continue;
        if (!seenInRecipe.add(normalizedIngredient)) continue;

        labels.putIfAbsent(normalizedIngredient, () => ingredient);
        counts.update(
          normalizedIngredient,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final items =
        counts.entries
            .map(
              (entry) => ShoppingListItem(
                name: labels[entry.key] ?? entry.key,
                recipeCount: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) {
            final countCompare = b.recipeCount.compareTo(a.recipeCount);
            if (countCompare != 0) return countCompare;
            return a.name.compareTo(b.name);
          });

    return items;
  }

  static int _matchScore({
    required Recipe recipe,
    required Set<String> selectedIngredients,
  }) {
    final normalizedSelected = selectedIngredients.map(_normalizeText).toSet();
    final ingredients = recipe.ingredientNames
        .map(_normalizeText)
        .where((item) => item.isNotEmpty)
        .toSet();

    var score = 0;
    for (final pantryItem in normalizedSelected) {
      if (_matchesAny(pantryItem, ingredients)) {
        score++;
      }
    }
    return score;
  }

  static bool _matchesAny(String candidate, Set<String> values) {
    for (final value in values) {
      if (candidate == value ||
          candidate.contains(value) ||
          value.contains(candidate)) {
        return true;
      }
    }
    return false;
  }

  static String _normalizeText(String input) {
    final buffer = StringBuffer();
    final lowered = input.toLowerCase();

    for (final rune in lowered.runes) {
      buffer.write(_normalizeChar(String.fromCharCode(rune)));
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeChar(String char) {
    switch (char) {
      case '\u00E7':
        return 'c';
      case '\u011F':
        return 'g';
      case '\u0131':
      case 'i':
        return 'i';
      case '\u00F6':
        return 'o';
      case '\u015F':
        return 's';
      case '\u00FC':
        return 'u';
      default:
        return char;
    }
  }
}
