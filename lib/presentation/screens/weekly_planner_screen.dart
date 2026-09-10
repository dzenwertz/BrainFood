import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meal_plan_slot.dart';
import '../state/meal_plan_state.dart';
import '../state/recipe_state.dart';
import '../state/pantry_state.dart';
import '../widgets/design_system.dart';
import '../widgets/food_art.dart';
import 'recipe_detail_screen.dart';

class WeeklyPlannerScreen extends ConsumerStatefulWidget {
  const WeeklyPlannerScreen({super.key});
  @override
  ConsumerState<WeeklyPlannerScreen> createState() =>
      _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends ConsumerState<WeeklyPlannerScreen> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(mealPlanProvider);
    final notifier = ref.read(mealPlanProvider.notifier);
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final end = plan.weekStart.add(const Duration(days: 6));
    final weekLabel =
        '${plan.weekStart.day} ${months[plan.weekStart.month - 1]} — ${end.day} ${months[end.month - 1]} ${end.year}';
    return PageBody(
      children: [
        const PageHeading(
          eyebrow: 'Un plan que se adapta a ti',
          title: 'Tu semana,\nmás ligera.',
          subtitle:
              'Deja algunas comidas resueltas. Cambia de idea cuando quieras.',
        ),
        Surface(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Semana anterior',
                onPressed: plan.isLoading || _busy
                    ? null
                    : () => notifier.changeWeek(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  weekLabel,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Semana siguiente',
                onPressed: plan.isLoading || _busy
                    ? null
                    : () => notifier.changeWeek(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (i) {
              final date = plan.weekStart.add(Duration(days: i));
              final selected = plan.selectedDayOfWeek == i + 1;
              final hasPlan = plan.slots.any(
                (s) =>
                    s.dayOfWeek == i + 1 && s.recipeId != null && !s.isSkipped,
              );
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  selected: selected,
                  label:
                      '${date.day}, ${['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'][i]}',
                  child: Material(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => notifier.selectDay(i + 1),
                      child: Container(
                        width: 46,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              days[i],
                              style: AppTypography.bodySmall.copyWith(
                                color: selected
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${date.day}',
                              style: AppTypography.titleMedium.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasPlan
                                    ? (selected
                                          ? AppColors.lime
                                          : AppColors.primary)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 22),
        if (plan.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ...['breakfast', 'lunch', 'dinner'].map((type) {
            final slot = plan.getSlot(plan.selectedDayOfWeek, type);
            return slot == null ? const SizedBox.shrink() : _meal(slot);
          }),
        const SectionHeading('El resto, un poco más fácil.'),
        Surface(
          color: AppColors.primaryLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('Dale forma a tu semana.', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Completa los espacios vacíos desde hoy con ideas que aprovechan tu despensa. Tus comidas elegidas y tus días fuera se respetan.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: plan.isLoading || _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            final count = await notifier
                                .generateSmartCascadePlan();
                            if (context.mounted) {
                              notify(
                                context,
                                count == 0
                                    ? 'No hay espacios futuros o recetas que cumplan tus preferencias.'
                                    : '$count ideas añadidas. Puedes cambiar cualquiera.',
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: Text(
                    _busy ? 'Organizando…' : 'Sugerir comidas para la semana',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: plan.plannedCount == 0 || _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  try {
                    final count = await notifier
                        .sendMissingPlanIngredientsToCart();
                    if (context.mounted) {
                      notify(
                        context,
                        count == 0
                            ? 'No hay nuevos faltantes. Revisa las cantidades en Compras.'
                            : '$count alimentos añadidos a Compras. Revisa las cantidades.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Llevar faltantes a Compras'),
        ),
        const SizedBox(height: 14),
        Text(
          'Plan orientativo: se comparan alimentos, no existencias exactas. Comprueba que las cantidades alcancen para todas las comidas.',
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }

  Widget _meal(MealPlanSlot slot) {
    final notifier = ref.read(mealPlanProvider.notifier);
    final recipe = ref
        .watch(recipeProvider)
        .allRecipes
        .where((r) => r.id == slot.recipeId)
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  slot.mealType == 'breakfast'
                      ? Icons.wb_twilight_outlined
                      : slot.mealType == 'lunch'
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slot.mealTypeName.toUpperCase(),
                    style: AppTypography.labelSmall,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opciones de ${slot.mealTypeName}',
                  onSelected: (value) {
                    if (value == 'skip') {
                      notifier.toggleSkip(slot.dayOfWeek, slot.mealType);
                    }
                    if (value == 'clear') {
                      notifier.clearMeal(slot.dayOfWeek, slot.mealType);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'skip',
                      child: Text(
                        slot.isSkipped
                            ? 'Volver a cocinar en casa'
                            : 'Comeré fuera',
                      ),
                    ),
                    if (slot.recipeId != null)
                      const PopupMenuItem(
                        value: 'clear',
                        child: Text('Quitar receta'),
                      ),
                  ],
                ),
              ],
            ),
            if (slot.isSkipped) ...[
              const SizedBox(height: 12),
              Text('Hoy cambian los planes.', style: AppTypography.titleMedium),
              const SizedBox(height: 6),
              const Text('Esta comida queda fuera de la lista de compras.'),
            ] else if (recipe != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(recipe.title, style: AppTypography.titleMedium),
                  ),
                  FoodArt(recipeId: recipe.id, size: 84),
                ],
              ),
              Text(
                '${recipe.prepTimeMinutes} min · ${recipe.servings} porciones',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(
                          match: recipe.calculateMatch(
                            ref.read(pantryProvider).activeIngredientNames,
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Ver receta'),
                  ),
                  TextButton(
                    onPressed: () => _pick(slot),
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                slot.recipeId == null
                    ? 'Un espacio para algo rico.'
                    : 'Esta receta ya no está disponible.',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => _pick(slot),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Elegir receta'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pick(MealPlanSlot slot) async {
    final matches = ref.read(rankedRecipesProvider);
    await openSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.mealTypeName} del ${slot.dayName.toLowerCase()}',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Ordenadas según lo que tienes en casa.'),
          const SizedBox(height: 18),
          if (matches.isEmpty)
            const Text(
              'No hay recetas con tus preferencias actuales. Revísalas en Ajustes.',
            ),
          ...matches.map(
            (m) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: FoodArt(recipeId: m.recipe.id, size: 54),
              title: Text(m.recipe.title, style: AppTypography.labelLarge),
              subtitle: Text(
                '${m.recipe.prepTimeMinutes} min · ${m.missingIngredients.length} faltantes',
              ),
              trailing: const Icon(Icons.add_circle_outline_rounded),
              onTap: () async {
                await ref
                    .read(mealPlanProvider.notifier)
                    .assignRecipe(
                      day: slot.dayOfWeek,
                      mealType: slot.mealType,
                      recipe: m.recipe,
                    );
                if (mounted) Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
