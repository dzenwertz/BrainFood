import '../../core/utils/ingredient_names.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final String category;
  final int prepTimeMinutes;
  final String difficulty;
  final bool isOnePot;
  final List<String> requiredIngredients;
  final List<String> optionalIngredients;
  final List<String> steps;
  final int servings;
  final String tipsForLeftovers;
  final String? suggestedNextMeal;
  final bool isAiGenerated;
  final Map<String, String> ingredientAmounts;

  bool get isPeruvian => id.startsWith('rec_peru_');

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.prepTimeMinutes,
    this.difficulty = 'Fácil',
    this.isOnePot = false,
    required this.requiredIngredients,
    this.optionalIngredients = const [],
    required this.steps,
    this.servings = 1,
    this.tipsForLeftovers = '',
    this.suggestedNextMeal,
    this.isAiGenerated = false,
    this.ingredientAmounts = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'prepTimeMinutes': prepTimeMinutes,
      'difficulty': difficulty,
      'isOnePot': isOnePot,
      'requiredIngredients': requiredIngredients,
      'optionalIngredients': optionalIngredients,
      'steps': steps,
      'servings': servings,
      'tipsForLeftovers': tipsForLeftovers,
      'suggestedNextMeal': suggestedNextMeal,
      'isAiGenerated': isAiGenerated,
      'ingredientAmounts': ingredientAmounts,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      prepTimeMinutes: json['prepTimeMinutes'] as int? ?? 20,
      difficulty: json['difficulty'] as String? ?? 'Fácil',
      isOnePot: json['isOnePot'] as bool? ?? false,
      requiredIngredients: List<String>.from(json['requiredIngredients'] ?? []),
      optionalIngredients: List<String>.from(json['optionalIngredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      servings: json['servings'] as int? ?? 1,
      tipsForLeftovers: json['tipsForLeftovers'] as String? ?? '',
      suggestedNextMeal: json['suggestedNextMeal'] as String?,
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
      ingredientAmounts: Map<String, String>.from(
        json['ingredientAmounts'] ?? {},
      ),
    );
  }

  /// Calcula coincidencia con la despensa actual
  RecipeMatch calculateMatch(List<String> pantryNames) {
    final normalizedPantry = pantryNames.map(ingredientKey).toSet();

    final owned = <String>[];
    final missing = <String>[];

    for (final ing in requiredIngredients) {
      final hasIt = normalizedPantry.contains(ingredientKey(ing));
      if (hasIt) {
        owned.add(ing);
      } else {
        missing.add(ing);
      }
    }

    final double percentage = requiredIngredients.isEmpty
        ? 1.0
        : owned.length / requiredIngredients.length;

    return RecipeMatch(
      recipe: this,
      ownedIngredients: owned,
      missingIngredients: missing,
      percentage: percentage,
    );
  }
}

class RecipeMatch {
  final Recipe recipe;
  final List<String> ownedIngredients;
  final List<String> missingIngredients;
  final double percentage;

  RecipeMatch({
    required this.recipe,
    required this.ownedIngredients,
    required this.missingIngredients,
    required this.percentage,
  });

  bool get isFullMatch => missingIngredients.isEmpty;
  bool get isOneMissing => missingIngredients.length == 1;
}
