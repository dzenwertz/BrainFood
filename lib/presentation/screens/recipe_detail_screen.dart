import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/ingredient_names.dart';
import '../../data/models/recipe.dart';
import '../state/pantry_state.dart';
import '../state/shopping_state.dart';
import '../state/preferences_state.dart';
import '../state/meal_plan_state.dart';
import '../widgets/design_system.dart';
import '../widgets/food_art.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final RecipeMatch match;
  const RecipeDetailScreen({super.key, required this.match});
  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  final Set<String> _prepared = {};
  late int _servings;

  @override
  void initState() {
    super.initState();
    _servings = widget.match.recipe.servings;
  }

  String _scaleAmount(String? raw) {
    if (raw == null || raw.isEmpty) return 'Al gusto';
    final base = widget.match.recipe.servings;
    if (base <= 0 || _servings == base) return raw;
    final ratio = _servings / base;
    return raw.replaceAllMapped(RegExp(r'(\d+(?:[.,]\d+)?|\d+/\d+)'), (match) {
      final token = match.group(0)!;
      double val;
      if (token.contains('/')) {
        final parts = token.split('/');
        val =
            (double.tryParse(parts[0]) ?? 1) / (double.tryParse(parts[1]) ?? 1);
      } else {
        val = double.tryParse(token.replaceAll(',', '.')) ?? 1;
      }
      final scaled = val * ratio;
      if (scaled == scaled.roundToDouble()) {
        return scaled.toInt().toString();
      } else {
        return scaled.toStringAsFixed(1).replaceAll('.0', '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.match.recipe;
    final match = recipe.calculateMatch(
      ref.watch(pantryProvider).activeIngredientNames,
    );
    final favorite = ref
        .watch(preferencesProvider)
        .favorites
        .contains(recipe.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          recipe.isAiGenerated ? 'Sugerencia de IA' : 'En tu recetario',
        ),
        actions: [
          IconButton(
            tooltip: favorite ? 'Quitar de favoritas' : 'Guardar receta',
            onPressed: () => ref
                .read(preferencesProvider.notifier)
                .toggleFavorite(recipe.id),
            icon: Icon(
              favorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: PageBody(
            children: [
              Container(
                height: 235,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(child: FoodArt(recipeId: recipe.id, size: 245)),
              ),
              const SizedBox(height: 22),
              Text(
                recipe.category.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(recipe.title, style: AppTypography.displayMedium),
              const SizedBox(height: 12),
              Text(recipe.description, style: AppTypography.bodyLarge),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    '${recipe.prepTimeMinutes} min',
                    icon: Icons.schedule_rounded,
                  ),
                  StatusPill(
                    recipe.difficulty,
                    icon: Icons.restaurant_outlined,
                  ),
                  StatusPill(
                    '$_servings ${_servings == 1 ? 'porción' : 'porciones'}',
                    icon: Icons.person_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Surface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people_outline_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Porciones para cocinar',
                            style: AppTypography.labelLarge,
                          ),
                          Text(
                            _servings == 1
                                ? '1 comensal'
                                : '$_servings comensales',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: _servings > 1
                          ? () => setState(() => _servings--)
                          : null,
                      tooltip: 'Menos porciones',
                    ),
                    Text(
                      '$_servings',
                      style: AppTypography.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _servings < 8
                          ? () => setState(() => _servings++)
                          : null,
                      tooltip: 'Más porciones',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _schedule,
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Añadir a mi semana'),
              ),
              const SectionHeading('Antes de empezar'),
              Text(
                _servings != recipe.servings
                    ? 'Cantidades recalculadas para $_servings porciones (receta base: ${recipe.servings}). Comprueba tus existencias.'
                    : 'Comprueba las cantidades en los pasos. La coincidencia con tu despensa indica presencia del alimento, no cantidad suficiente.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 14),
              ...recipe.requiredIngredients.map((name) {
                final owned = match.ownedIngredients.contains(name);
                final amount = _scaleAmount(recipe.ingredientAmounts[name]);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Surface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    color: owned ? AppColors.surface : AppColors.accentLight,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _prepared.contains(name),
                      onChanged: (v) => setState(() {
                        v == true
                            ? _prepared.add(name)
                            : _prepared.remove(name);
                      }),
                      title: Text(name, style: AppTypography.labelLarge),
                      subtitle: Text(
                        '$amount · ${owned ? 'En tu despensa' : 'Por comprar'}',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ),
                );
              }),
              if (match.missingIngredients.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final count = await ref
                        .read(shoppingProvider.notifier)
                        .addMissingFromRecipe(
                          match.missingIngredients,
                          recipe.title,
                        );
                    if (context.mounted) {
                      notify(
                        context,
                        count == 0
                            ? 'Estos ingredientes ya están en Compras.'
                            : '$count ingredientes añadidos a Compras.',
                      );
                    }
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Llevar faltantes a Compras'),
                ),
              if (recipe.optionalIngredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Si tienes: ${recipe.optionalIngredients.join(', ')}.',
                  style: AppTypography.bodySmall,
                ),
              ],
              const SectionHeading('Así se prepara'),
              ...recipe.steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: 'Paso ${entry.key + 1}',
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTypography.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (recipe.tipsForLeftovers.isNotEmpty) ...[
                const SectionHeading('Que nada bueno se pierda.'),
                Surface(
                  color: AppColors.primaryLight,
                  child: Text(
                    recipe.tipsForLeftovers,
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                recipe.isAiGenerated
                    ? 'Sugerencia generada por IA. Revisa ingredientes, cantidades y preparación antes de cocinar.'
                    : 'Ilustración orientativa del plato.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: FilledButton.icon(
            onPressed: () async {
              final finished = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => CookingModeScreen(recipe: recipe),
                ),
              );
              if (finished == true && mounted) await _finish();
            },
            icon: const Icon(Icons.restaurant_rounded),
            label: const Text('Abrir modo cocina'),
          ),
        ),
      ),
    );
  }

  Future<void> _schedule() async {
    final plan = ref.read(mealPlanProvider);
    if (plan.isLoading) {
      notify(context, 'Tu calendario está cargando. Inténtalo en un momento.');
      return;
    }
    var day = plan.selectedDayOfWeek;
    var type = widget.match.recipe.category.toLowerCase().contains('desayuno')
        ? 'breakfast'
        : 'lunch';
    await openSheet(
      context,
      StatefulBuilder(
        builder: (context, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Un espacio en tu semana.', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Semana del ${plan.weekStart.day}/${plan.weekStart.month}/${plan.weekStart.year}.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: day,
              decoration: const InputDecoration(labelText: 'Día'),
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(
                    [
                      'Lunes',
                      'Martes',
                      'Miércoles',
                      'Jueves',
                      'Viernes',
                      'Sábado',
                      'Domingo',
                    ][i],
                  ),
                ),
              ),
              onChanged: (v) => setSheet(() => day = v!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Comida'),
              items: const [
                DropdownMenuItem(value: 'breakfast', child: Text('Desayuno')),
                DropdownMenuItem(value: 'lunch', child: Text('Almuerzo')),
                DropdownMenuItem(value: 'dinner', child: Text('Cena')),
              ],
              onChanged: (v) => setSheet(() => type = v!),
            ),
            const SizedBox(height: 14),
            if (plan.getSlot(day, type)?.recipeId != null)
              Text(
                'Se reemplazará: ${plan.getSlot(day, type)!.recipeTitle}.',
                style: AppTypography.bodySmall,
              ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(mealPlanProvider.notifier)
                    .assignRecipe(
                      day: day,
                      mealType: type,
                      recipe: widget.match.recipe,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  notify(context, 'Receta añadida a tu semana.');
                }
              },
              child: const Text('Guardar en mi plan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final used = ref
        .read(pantryProvider)
        .items
        .where(
          (i) =>
              !i.isStaple &&
              widget.match.recipe.requiredIngredients.any(
                (r) => sameIngredient(r, i.name),
              ),
        )
        .toList();
    final exhausted = <String>{};
    var saving = false;
    await openSheet(
      context,
      StatefulBuilder(
        builder: (sheetContext, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buen provecho.', style: AppTypography.displayMedium),
            const SizedBox(height: 10),
            const Text(
              '¿Se acabó alguno de estos alimentos? Marca solo los que ya no te quedan. El resto seguirá en tu despensa.',
            ),
            const SizedBox(height: 16),
            ...used.map(
              (i) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(i.name),
                subtitle: Text(i.quantityDisplay),
                value: exhausted.contains(i.name),
                onChanged: saving
                    ? null
                    : (v) => setSheet(() {
                        v == true
                            ? exhausted.add(i.name)
                            : exhausted.remove(i.name);
                      }),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setSheet(() => saving = true);
                        final pantry = ref.read(pantryProvider.notifier);
                        await pantry.deductIngredientsForRecipe(
                          exhausted.toList(),
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        if (!mounted) return;
                        Navigator.pop(context);
                        notify(
                          context,
                          exhausted.isEmpty
                              ? '¡Comida resuelta! Tu despensa se conserva.'
                              : 'Despensa actualizada. ¡Buen provecho!',
                          action: exhausted.isEmpty
                              ? null
                              : SnackBarAction(
                                  label: 'Deshacer',
                                  onPressed: pantry.undoDeduction,
                                ),
                        );
                      },
                child: const Text('Listo, a disfrutar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
