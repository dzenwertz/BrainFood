import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/ingredient_names.dart';
import '../../data/models/recipe.dart';
import '../../data/datasources/curated_recipes.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/services/ai_recipe_service.dart';
import 'pantry_state.dart';
import 'preferences_state.dart';

enum RecipeFilterType { all, fullMatch, oneMissing, fast, onePot, favorites }

class RecipeState {
  final List<Recipe> allRecipes;
  final RecipeFilterType currentFilter;
  final bool isGeneratingAi;
  final String? lastAiError;
  RecipeState({
    required this.allRecipes,
    this.currentFilter = RecipeFilterType.all,
    this.isGeneratingAi = false,
    this.lastAiError,
  });
  RecipeState copyWith({
    List<Recipe>? allRecipes,
    RecipeFilterType? currentFilter,
    bool? isGeneratingAi,
    String? lastAiError,
  }) => RecipeState(
    allRecipes: allRecipes ?? this.allRecipes,
    currentFilter: currentFilter ?? this.currentFilter,
    isGeneratingAi: isGeneratingAi ?? this.isGeneratingAi,
    lastAiError: lastAiError,
  );
}

class RecipeNotifier extends Notifier<RecipeState> {
  late Future<void> _ready;
  @override
  RecipeState build() {
    _ready = _loadCustomRecipes();
    return RecipeState(allRecipes: CuratedRecipes.baseRecipes);
  }

  Future<void> _loadCustomRecipes() async {
    final custom = await LocalStorageService.loadCustomRecipes();
    if (ref.mounted) {
      state = state.copyWith(
        allRecipes: [...custom, ...CuratedRecipes.baseRecipes],
      );
    }
  }

  void setFilter(RecipeFilterType filter) =>
      state = state.copyWith(currentFilter: filter);
  Future<Recipe?> generateAiRecipe({String? prompt}) async {
    if (state.isGeneratingAi) return null;
    state = state.copyWith(isGeneratingAi: true);
    try {
      await _ready;
      final pantry = ref.read(pantryProvider);
      final key = await LocalStorageService.loadApiKey();
      final recipe = await AiRecipeService.generateRecipe(
        availableIngredients: pantry.activeIngredientNames,
        includeStaples: false,
        userPrompt: prompt,
        apiKey: key,
      );
      final prefs = ref.read(preferencesProvider);
      if (recipe.requiredIngredients.any(
        (i) => prefs.excluded.any((e) => sameIngredient(e, i)),
      )) {
        throw const FormatException(
          'La sugerencia incluye alimentos que prefieres evitar. Prueba otra petición.',
        );
      }
      if (!ref.mounted) return null;
      final exists = state.allRecipes.any((r) => r.id == recipe.id);
      state = state.copyWith(
        allRecipes: exists ? state.allRecipes : [recipe, ...state.allRecipes],
      );
      await LocalStorageService.saveCustomRecipes(
        state.allRecipes.where((r) => r.isAiGenerated).toList(),
      );
      return recipe;
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isGeneratingAi: false,
          lastAiError: e is FormatException ? e.message : 'No pudimos conectar. Tu despensa y tus recetas siguen disponibles.',
        );
      }
      return null;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          isGeneratingAi: false,
          lastAiError: state.lastAiError,
        );
      }
    }
  }
}

final recipeProvider = NotifierProvider<RecipeNotifier, RecipeState>(
  RecipeNotifier.new,
);

/// A single ranking is shared by Today, recipes and the planner.
final rankedRecipesProvider = Provider<List<RecipeMatch>>((ref) {
  final recipes = ref.watch(recipeProvider).allRecipes;
  final pantry = ref.watch(pantryProvider);
  final prefs = ref.watch(preferencesProvider);
  final urgent = pantry.items
      .where((i) => i.isExpiringSoon)
      .map((i) => ingredientKey(i.name))
      .toSet();
  final matches = recipes
      .where(
        (r) => !r.requiredIngredients.any(
          (i) => prefs.excluded.contains(ingredientKey(i)),
        ),
      )
      .map((r) => r.calculateMatch(pantry.activeIngredientNames))
      .toList();
  double score(RecipeMatch m) =>
      m.percentage * 100 +
      m.recipe.requiredIngredients
              .where((i) => urgent.contains(ingredientKey(i)))
              .length *
          12 -
      (m.recipe.prepTimeMinutes > prefs.maxMinutes ? 25 : 0);
  matches.sort((a, b) {
    final order = score(b).compareTo(score(a));
    return order != 0
        ? order
        : a.recipe.prepTimeMinutes.compareTo(b.recipe.prepTimeMinutes);
  });
  return matches;
});
final recipeMatchesProvider = Provider<List<RecipeMatch>>((ref) {
  final matches = ref.watch(rankedRecipesProvider);
  final filter = ref.watch(recipeProvider).currentFilter;
  final favorites = ref.watch(preferencesProvider).favorites;
  return matches
      .where(
        (m) => switch (filter) {
          RecipeFilterType.all => true,
          RecipeFilterType.fullMatch => m.isFullMatch,
          RecipeFilterType.oneMissing => m.isOneMissing,
          RecipeFilterType.fast => m.recipe.prepTimeMinutes <= 15,
          RecipeFilterType.onePot => m.recipe.isOnePot,
          RecipeFilterType.favorites => favorites.contains(m.recipe.id),
        },
      )
      .toList();
});
