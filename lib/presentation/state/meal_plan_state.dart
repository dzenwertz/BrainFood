import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/ingredient_names.dart';
import '../../data/models/meal_plan_slot.dart';
import '../../data/models/recipe.dart';
import '../../data/datasources/local_storage.dart';
import 'recipe_state.dart';
import 'shopping_state.dart';
import 'pantry_state.dart';
import 'preferences_state.dart';

DateTime mondayOf(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1);

class MealPlanState {
  final List<MealPlanSlot> slots;
  final int selectedDayOfWeek;
  final DateTime weekStart;
  final bool isLoading;
  MealPlanState({
    required this.slots,
    required this.weekStart,
    this.selectedDayOfWeek = 1,
    this.isLoading = false,
  });
  MealPlanState copyWith({
    List<MealPlanSlot>? slots,
    int? selectedDayOfWeek,
    DateTime? weekStart,
    bool? isLoading,
  }) => MealPlanState(
    slots: slots ?? this.slots,
    selectedDayOfWeek: selectedDayOfWeek ?? this.selectedDayOfWeek,
    weekStart: weekStart ?? this.weekStart,
    isLoading: isLoading ?? this.isLoading,
  );
  MealPlanSlot? getSlot(int day, String type) =>
      slots.where((s) => s.dayOfWeek == day && s.mealType == type).firstOrNull;
  int get plannedCount =>
      slots.where((s) => s.recipeId != null && !s.isSkipped).length;
}

class MealPlanNotifier extends Notifier<MealPlanState> {
  late Future<void> _ready;
  int _loadVersion = 0;
  @override
  MealPlanState build() {
    final now = DateTime.now();
    _ready = _loadWeek(mondayOf(now));
    return MealPlanState(
      slots: [],
      weekStart: mondayOf(now),
      selectedDayOfWeek: now.weekday,
      isLoading: true,
    );
  }

  String _key(DateTime start) =>
      'bf_week_${start.toIso8601String().substring(0, 10)}';
  List<MealPlanSlot> _empty() => [
    for (var day = 1; day <= 7; day++)
      for (final type in ['breakfast', 'lunch', 'dinner'])
        MealPlanSlot(id: 'slot_${day}_$type', dayOfWeek: day, mealType: type),
  ];
  Future<void> _loadWeek(DateTime start) async {
    final version = ++_loadVersion;
    final prefs = await SharedPreferences.getInstance();
    var slots = _empty();
    final raw = prefs.getString(_key(start));
    if (raw != null) {
      try {
        slots = (jsonDecode(raw) as List)
            .map((e) => MealPlanSlot.fromJson(e))
            .toList();
      } catch (_) {
        /* Keep a usable empty week; the stored source is not deleted. */
      }
    } else if (!prefs.containsKey('bf_week_migrated') &&
        start == mondayOf(DateTime.now())) {
      final legacy = await LocalStorageService.loadMealPlan();
      if (legacy.isNotEmpty) slots = legacy;
      await prefs.setString(
        _key(start),
        jsonEncode(slots.map((s) => s.toJson()).toList()),
      );
      await prefs.setBool('bf_week_migrated', true);
    }

    // Asegurar que existan los 3 turnos (Desayuno, Almuerzo, Cena) para cada día
    const mealTypes = ['breakfast', 'lunch', 'dinner'];
    final completeSlots = <MealPlanSlot>[];
    for (var day = 1; day <= 7; day++) {
      for (final type in mealTypes) {
        final existing = slots
            .where((s) => s.dayOfWeek == day && s.mealType == type)
            .firstOrNull;
        if (existing != null) {
          completeSlots.add(existing);
        } else {
          completeSlots.add(
            MealPlanSlot(
              id: 'slot_${day}_$type',
              dayOfWeek: day,
              mealType: type,
            ),
          );
        }
      }
    }
    slots = completeSlots;

    if (ref.mounted && version == _loadVersion) {
      state = state.copyWith(slots: slots, weekStart: start, isLoading: false);
    }
  }

  Future<void> changeWeek(int delta) async {
    if (state.isLoading) return;
    final next = state.weekStart.add(Duration(days: 7 * delta));
    state = state.copyWith(isLoading: true);
    _ready = _loadWeek(next);
    await _ready;
  }

  Future<void> _save(List<MealPlanSlot> slots) async {
    final key = _key(state.weekStart);
    state = state.copyWith(slots: slots);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(slots.map((s) => s.toJson()).toList()),
    );
  }

  void selectDay(int day) => state = state.copyWith(selectedDayOfWeek: day);
  Future<void> assignRecipe({
    required int day,
    required String mealType,
    required Recipe recipe,
  }) async {
    await _ready;
    await _save(
      state.slots
          .map(
            (s) => s.dayOfWeek == day && s.mealType == mealType
                ? s.copyWith(
                    recipeId: recipe.id,
                    recipeTitle: recipe.title,
                    prepTime: '${recipe.prepTimeMinutes} min',
                    isSkipped: false,
                  )
                : s,
          )
          .toList(),
    );
  }

  Future<void> clearMeal(int day, String mealType) async => _save(
    state.slots
        .map(
          (s) => s.dayOfWeek == day && s.mealType == mealType
              ? MealPlanSlot(id: s.id, dayOfWeek: day, mealType: mealType)
              : s,
        )
        .toList(),
  );
  Future<void> toggleSkip(int day, String mealType) async => _save(
    state.slots
        .map(
          (s) => s.dayOfWeek == day && s.mealType == mealType
              ? s.copyWith(isSkipped: !s.isSkipped)
              : s,
        )
        .toList(),
  );

  /// Fill only empty meals. Prefer pantry matches, urgent ingredients, variety,
  /// and reuse of ingredients already needed by the plan.
  Future<int> generateSmartCascadePlan() async {
    await _ready;
    final prefs = ref.read(preferencesProvider);
    final ranked = ref
        .read(rankedRecipesProvider)
        .where((m) => m.recipe.prepTimeMinutes <= prefs.maxMinutes)
        .toList();
    if (ranked.isEmpty) return 0;
    final used = <String, int>{};
    final plannedIngredients = <String>{};
    for (final slot in state.slots) {
      if (slot.isSkipped || slot.recipeId == null) continue;
      used.update(slot.recipeId!, (n) => n + 1, ifAbsent: () => 1);
    }
    var count = 0;
    final slots = [...state.slots];
    final today = DateTime.now();
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final date = state.weekStart.add(Duration(days: slot.dayOfWeek - 1));
      if (date.isBefore(DateTime(today.year, today.month, today.day)) ||
          slot.recipeId != null ||
          slot.isSkipped) {
        continue;
      }
      double score(RecipeMatch m) {
        var baseScore =
            m.percentage * 100 -
            (used[m.recipe.id] ?? 0) * 45 +
            m.missingIngredients
                    .where((n) => plannedIngredients.contains(ingredientKey(n)))
                    .length *
                6;

        if (slot.mealType == 'breakfast') {
          if (m.recipe.category == 'Desayuno') {
            baseScore += 30;
          } else if (m.recipe.prepTimeMinutes <= 12 &&
              (m.recipe.title.toLowerCase().contains('huevo') ||
                  m.recipe.title.toLowerCase().contains('pan') ||
                  m.recipe.title.toLowerCase().contains('tostada') ||
                  m.recipe.title.toLowerCase().contains('tortilla'))) {
            baseScore += 15;
          } else {
            baseScore -= 20;
          }
        } else if (slot.mealType == 'lunch') {
          if (m.recipe.category == 'Almuerzo') {
            baseScore += 15;
          } else if (m.recipe.category == 'Desayuno') {
            baseScore -= 10;
          }
        } else if (slot.mealType == 'dinner') {
          if (m.recipe.category == 'Cena') {
            baseScore += 15;
          } else if (m.recipe.category == 'Desayuno') {
            baseScore -= 10;
          }
        }

        baseScore +=
            m.ownedIngredients
                .where(
                  (n) => ref
                      .read(pantryProvider)
                      .items
                      .any(
                        (p) => p.isExpiringSoon && sameIngredient(p.name, n),
                      ),
                )
                .length *
            12;

        return baseScore;
      }

      final candidates = [...ranked]
        ..sort((a, b) => score(b).compareTo(score(a)));
      final r = candidates.first.recipe;
      used.update(r.id, (n) => n + 1, ifAbsent: () => 1);
      plannedIngredients.addAll(r.requiredIngredients.map(ingredientKey));
      slots[i] = slot.copyWith(
        recipeId: r.id,
        recipeTitle: r.title,
        prepTime: '${r.prepTimeMinutes} min',
      );
      count++;
    }
    await _save(slots);
    return count;
  }

  Future<int> sendMissingPlanIngredientsToCart() async {
    final pantry = ref.read(pantryProvider);
    final recipes = ref.read(recipeProvider).allRecipes;
    final missing = <String, String>{};
    for (final slot in state.slots.where(
      (s) => s.recipeId != null && !s.isSkipped,
    )) {
      final r = recipes.where((r) => r.id == slot.recipeId).firstOrNull;
      if (r == null) continue;
      for (final name
          in r
              .calculateMatch(pantry.activeIngredientNames)
              .missingIngredients) {
        missing[ingredientKey(name)] = name;
      }
    }
    return ref
        .read(shoppingProvider.notifier)
        .addMissingFromRecipe(missing.values.toList(), 'Plan de la semana');
  }
}

final mealPlanProvider = NotifierProvider<MealPlanNotifier, MealPlanState>(
  MealPlanNotifier.new,
);
