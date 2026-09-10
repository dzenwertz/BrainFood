import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:brain_food/core/utils/ingredient_names.dart';
import 'package:brain_food/core/constants/pantry_packs.dart';
import 'package:brain_food/core/utils/shopping_list_formatter.dart';
import 'package:brain_food/data/models/ingredient_item.dart';
import 'package:brain_food/data/models/recipe.dart';
import 'package:brain_food/data/models/shopping_item.dart';
import 'package:brain_food/data/datasources/curated_recipes.dart';
import 'package:brain_food/data/services/ai_recipe_service.dart';
import 'package:brain_food/presentation/state/pantry_state.dart';
import 'package:brain_food/presentation/state/shopping_state.dart';
import 'package:brain_food/presentation/state/meal_plan_state.dart';
import 'package:brain_food/presentation/state/preferences_state.dart';
import 'package:brain_food/presentation/state/recipe_state.dart';

Future<void> load(ProviderContainer c) async {
  c.read(pantryProvider);
  c.read(shoppingProvider);
  c.read(mealPlanProvider);
  c.read(recipeProvider);
  c.read(preferencesProvider);
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Ingredient aliases match accents and plurals without substring false positives', () {
    expect(sameIngredient('Limones', 'limón'), isTrue);
    expect(sameIngredient('SAL', 'salmón'), isFalse);
    expect(sameIngredient('pan', 'panceta'), isFalse);
    expect(sameIngredient('arroz', 'arroz cocido'), isFalse);
    final recipe = Recipe(
      id: 'r',
      title: 'r',
      description: '',
      category: '',
      prepTimeMinutes: 10,
      requiredIngredients: ['Sal', 'Pan'],
      steps: ['Paso'],
    );
    expect(
      recipe.calculateMatch(['Salmón', 'Panceta']).ownedIngredients,
      isEmpty,
    );
  });
  test(
    'New pantry is empty and never assumes staples without opting in',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await load(c);
      expect(c.read(pantryProvider).items, isEmpty);
      expect(c.read(pantryProvider).activeIngredientNames, isEmpty);
    },
  );
  test('Editing pantry updates priority; confirming depletion removes only selected foods and undo preserves new edits', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await load(c);
    final p = c.read(pantryProvider.notifier);
    await p.addIngredient(
      name: 'Sal',
      category: IngredientCategory.staples,
      quantity: '1 bolsa',
    );
    await p.addIngredient(
      name: 'Salmón',
      category: IngredientCategory.proteins,
      quantity: '2 piezas',
    );
    await p.addIngredient(
      name: 'Sal',
      category: IngredientCategory.staples,
      quantity: 'Media bolsa',
      isExpiringSoon: true,
    );
    expect(
      c
          .read(pantryProvider)
          .items
          .firstWhere((i) => i.name == 'Sal')
          .isExpiringSoon,
      isTrue,
    );
    await p.deductIngredientsForRecipe(['Sal']);
    expect(c.read(pantryProvider).items.single.name, 'Salmón');
    await p.addIngredient(
      name: 'Sal',
      category: IngredientCategory.staples,
      quantity: 'Nueva bolsa',
    );
    await p.undoDeduction();
    expect(c.read(pantryProvider).items.length, 2);
    expect(
      c
          .read(pantryProvider)
          .items
          .firstWhere((i) => i.name == 'Sal')
          .quantityDisplay,
      'Nueva bolsa',
    );
  });
  test('Adding recipe missing items is idempotent and never unchecks a bought item', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await load(c);
    final s = c.read(shoppingProvider.notifier);
    expect(await s.addMissingFromRecipe(['Limón', 'Sal'], 'Cena'), 2);
    final id = c.read(shoppingProvider).items.first.id;
    await s.toggleBought(id);
    expect(await s.addMissingFromRecipe(['Limones', 'Sal'], 'Almuerzo'), 0);
    expect(c.read(shoppingProvider).boughtCount, 1);
    expect(c.read(shoppingProvider).items.length, 2);
  });
  test(
    'Pantry packs add only missing foods and preserve existing quantities',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await load(c);
      final pantry = c.read(pantryProvider.notifier);
      await pantry.addIngredient(
        name: 'Arroz',
        category: IngredientCategory.grains,
        quantity: 'Medio kilo',
      );
      expect(await pantry.addPackItems(PantryPacks.peruvian.items), 9);
      expect(c.read(pantryProvider).items.length, 10);
      expect(
        c
            .read(pantryProvider)
            .items
            .firstWhere((i) => i.name == 'Arroz')
            .quantityDisplay,
        'Medio kilo',
      );
    },
  );
  test('Shared shopping text groups only pending products by category', () {
    final text = ShoppingListFormatter.pendingText([
      ShoppingItem(
        id: '1',
        name: 'Tomate',
        category: IngredientCategory.vegetables,
        quantity: '3 unidades',
      ),
      ShoppingItem(
        id: '2',
        name: 'Pollo',
        category: IngredientCategory.proteins,
        quantity: '500 g',
      ),
      ShoppingItem(id: '3', name: 'Arroz', isBought: true),
    ]);
    expect(text, contains('Verduras\n☐ Tomate — 3 unidades'));
    expect(text, contains('Proteínas\n☐ Pollo — 500 g'));
    expect(text, isNot(contains('Arroz')));
    expect(text, endsWith('2 productos pendientes'));
  });
  test(
    'Bought items transfer once and preserve stock already in the pantry',
    () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await load(c);
      await c
          .read(pantryProvider.notifier)
          .addIngredient(
            name: 'Tomate',
            category: IngredientCategory.vegetables,
            quantity: '2 unidades',
          );
      final s = c.read(shoppingProvider.notifier);
      await s.addItem(name: 'Tomate', quantity: '3 unidades');
      await s.toggleBought(c.read(shoppingProvider).items.single.id);
      final results = await Future.wait([
        s.transferBoughtToPantry(),
        s.transferBoughtToPantry(),
      ]);
      expect(results.reduce((a, b) => a + b), 1);
      expect(c.read(shoppingProvider).items, isEmpty);
      expect(
        c.read(pantryProvider).items.single.quantityDisplay,
        '2 unidades + 3 unidades',
      );
    },
  );
  test('Weekly generation preserves chosen recipes and skipped meals across breakfast, lunch, and dinner', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await load(c);
    final p = c.read(mealPlanProvider.notifier);
    await p.changeWeek(1);
    final chosen = CuratedRecipes.baseRecipes.first;
    await p.assignRecipe(day: 1, mealType: 'lunch', recipe: chosen);
    await p.toggleSkip(1, 'dinner');
    final count = await p.generateSmartCascadePlan();
    // 7 días * 3 turnos (desayuno, almuerzo, cena) = 21 turnos. Día 1 tiene almuerzo asignado y cena saltada -> 19 turnos completados
    expect(count, 19);
    expect(c.read(mealPlanProvider).getSlot(1, 'lunch')!.recipeId, chosen.id);
    expect(c.read(mealPlanProvider).getSlot(1, 'dinner')!.isSkipped, isTrue);
    expect(
      c.read(mealPlanProvider).getSlot(1, 'breakfast')!.recipeId,
      isNotNull,
    );
    expect(await p.generateSmartCascadePlan(), 0);
    await p.changeWeek(1);
    expect(c.read(mealPlanProvider).plannedCount, 0);
    await p.changeWeek(-1);
    expect(c.read(mealPlanProvider).plannedCount, 20);
  });
  test('Preferences filter ingredients and enforce preparation limit in generated plan', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await load(c);
    await c
        .read(preferencesProvider.notifier)
        .update(excluded: {'huevo'}, maxMinutes: 15);
    final plan = c.read(mealPlanProvider.notifier);
    await plan.changeWeek(1);
    await plan.generateSmartCascadePlan();
    for (final slot
        in c.read(mealPlanProvider).slots.where((s) => s.recipeId != null)) {
      final r = c
          .read(recipeProvider)
          .allRecipes
          .firstWhere((r) => r.id == slot.recipeId);
      expect(r.prepTimeMinutes, lessThanOrEqualTo(15));
      expect(
        r.requiredIngredients.any((i) => ingredientKey(i) == 'huevo'),
        isFalse,
      );
    }
  });
  test('Local suggestions are real catalogue recipes, and never invent a dish from salt alone', () {
    expect(
      () => AiRecipeService.suggestLocal(['Sal'], 'Algo sencillo'),
      throwsFormatException,
    );
    final r = AiRecipeService.suggestLocal([
      'Huevos',
      'Espinaca',
      'Aceite',
      'Sal',
    ], 'Hasta 15 minutos');
    expect(r.isAiGenerated, isFalse);
    expect(
      r.calculateMatch(['Huevos', 'Espinaca', 'Aceite', 'Sal']).isFullMatch,
      isTrue,
    );
  });
  test('Malformed AI output is rejected before it is saved', () {
    expect(
      () => AiRecipeService.validateRecipe({
        'title': 'Dish',
        'requiredIngredients': [],
      }),
      throwsFormatException,
    );
    expect(
      () => AiRecipeService.validateRecipe({
        'title': 'Dish',
        'requiredIngredients': ['Salt'],
        'steps': ['Step'],
        'prepTimeMinutes': -1,
        'servings': 1,
      }),
      throwsFormatException,
    );
  });
  test('Provider errors remain visible instead of falling back to invented recipes', () async {
    SharedPreferences.setMockInitialValues({
      'bf_ai_provider': 'opencode',
      'bf_ai_model': 'test-model',
    });
    final client = MockClient((request) async {
      expect(request.url.host, 'opencode.ai');
      return http.Response('rate limited', 429);
    });
    await expectLater(
      AiRecipeService.generateRecipe(
        availableIngredients: ['Tomate'],
        includeStaples: false,
        apiKey: 'test-key',
        client: client,
      ),
      throwsFormatException,
    );
    client.close();
  });
  test('Remote recipe schema is parsed and labelled AI', () async {
    SharedPreferences.setMockInitialValues({
      'bf_ai_provider': 'opencode',
      'bf_ai_model': 'test-model',
    });
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'title': 'Tomate sencillo',
                  'requiredIngredients': ['Tomate'],
                  'steps': ['Lava y corta el tomate.'],
                  'prepTimeMinutes': 5,
                  'servings': 1,
                }),
              },
            },
          ],
        }),
        200,
      ),
    );
    final r = await AiRecipeService.generateRecipe(
      availableIngredients: ['Tomate'],
      includeStaples: false,
      apiKey: 'test',
      client: client,
    );
    expect(r.isAiGenerated, isTrue);
    expect(r.title, 'Tomate sencillo');
    client.close();
  });

  test('Clearing bought items removes only purchased items from shopping list', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final shop = c.read(shoppingProvider.notifier);
    await shop.addItem(name: 'Tomate');
    await shop.addItem(name: 'Cebolla');
    final firstId = c.read(shoppingProvider).items.first.id;
    await shop.toggleBought(firstId);
    expect(c.read(shoppingProvider).boughtCount, 1);
    expect(c.read(shoppingProvider).pendingCount, 1);
    final removed = await shop.clearBought();
    expect(removed, 1);
    expect(c.read(shoppingProvider).items.length, 1);
    expect(c.read(shoppingProvider).items.first.name, 'Cebolla');
  });
}
