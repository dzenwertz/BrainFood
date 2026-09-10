import 'package:flutter_test/flutter_test.dart';
import 'package:brain_food/core/utils/ingredient_names.dart';
import 'package:brain_food/data/datasources/curated_recipes.dart';

void main() {
  test(
    'El catálogo curado conserva calidad editorial y datos para cocinar',
    () {
      final recipes = CuratedRecipes.baseRecipes;

      expect(recipes.length, greaterThanOrEqualTo(100));

      final ids = <String>{};
      final titles = <String>{};
      const categories = {'Desayuno', 'Almuerzo', 'Cena', 'Snack'};
      for (final r in recipes) {
        expect(ids.add(r.id), isTrue, reason: 'ID duplicado: ${r.id}');
        expect(
          titles.add(ingredientKey(r.title)),
          isTrue,
          reason: 'Título duplicado: ${r.title}',
        );

        expect(r.id.trim(), isNotEmpty);
        expect(r.title.trim(), isNotEmpty);
        expect(r.description.trim().length, greaterThanOrEqualTo(20));
        expect(categories, contains(r.category), reason: r.title);
        expect(r.prepTimeMinutes, inInclusiveRange(1, 240), reason: r.title);
        expect(r.servings, inInclusiveRange(1, 12), reason: r.title);
        expect(r.requiredIngredients, isNotEmpty, reason: r.title);
        expect(r.steps.length, greaterThanOrEqualTo(2), reason: r.title);
        expect(
          r.steps.every((step) => step.trim().length >= 10),
          isTrue,
          reason: 'Paso demasiado breve en ${r.title}',
        );

        final ingredients = <String>{};
        for (final ingredient in r.requiredIngredients) {
          expect(
            ingredients.add(ingredientKey(ingredient)),
            isTrue,
            reason: 'Ingrediente repetido en ${r.title}: $ingredient',
          );
          final hasAmount = r.ingredientAmounts.entries.any(
            (entry) =>
                sameIngredient(entry.key, ingredient) &&
                entry.value.trim().isNotEmpty,
          );
          expect(
            hasAmount,
            isTrue,
            reason: 'Falta cantidad para $ingredient en ${r.title}',
          );
        }
      }
    },
  );
}
