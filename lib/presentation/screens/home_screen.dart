import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/meal_plan_slot.dart';
import '../../data/models/recipe.dart';
import '../state/pantry_state.dart';
import '../state/recipe_state.dart';
import '../state/meal_plan_state.dart';
import '../widgets/design_system.dart';
import '../widgets/food_art.dart';
import '../widgets/recipe_card.dart';
import 'main_shell.dart';
import 'recipe_detail_screen.dart';
import 'ai_chef_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pantry = ref.watch(pantryProvider);
    final matches = ref.watch(rankedRecipesProvider);
    final plan = ref.watch(mealPlanProvider);
    final ready = matches.where((m) => m.isFullMatch).length;
    final urgent = pantry.items.where((i) => i.isExpiringSoon).toList();
    final featured = matches.firstOrNull;
    void go(int index) => ref.read(navigationProvider.notifier).select(index);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Buenos días.'
        : now.hour < 19
        ? 'Buenas tardes.'
        : 'Buenas noches.';
    final todayWeekday = now.weekday;
    final allRecipes = ref.watch(recipeProvider).allRecipes;
    final todaySlots = ['breakfast', 'lunch', 'dinner'].map((type) {
      final slot = plan.getSlot(todayWeekday, type);
      if (slot == null || slot.isSkipped || slot.recipeId == null) return null;
      final recipe = allRecipes.where((r) => r.id == slot.recipeId).firstOrNull;
      if (recipe == null) return null;
      return (slot: slot, recipe: recipe);
    }).whereType<({MealPlanSlot slot, Recipe recipe})>().toList();

    return PageBody(
      children: [
        PageHeading(
          eyebrow: 'Tu cocina, en calma',
          title: '$greeting\n¿Qué cocinamos?',
          subtitle: 'Menos vueltas. Más comida hecha en casa.',
        ),
        if (pantry.isLoading)
          const LinearProgressIndicator()
        else
          Reveal(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.lime,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pantry.items.isEmpty
                                ? 'EMPIEZA CON LO QUE TIENES'
                                : 'UNA BUENA IDEA PARA HOY',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.lime,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: FoodArt(
                      recipeId: featured?.recipe.id ?? 'rec_tortilla',
                      size: 176,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pantry.items.isEmpty
                              ? 'Tu próxima comida\nya está más cerca.'
                              : featured?.recipe.title ??
                                    'A tu gusto, a tu ritmo.',
                          style: AppTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          pantry.items.isEmpty
                              ? 'Añade algunos alimentos y descubre cómo aprovecharlos.'
                              : featured == null
                              ? 'Ajusta tus preferencias para descubrir otras ideas.'
                              : '${featured.recipe.prepTimeMinutes} min · ${featured.isFullMatch ? 'Tienes los ingredientes' : 'Te faltan ${featured.missingIngredients.length} ingredientes'}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFFC4D5C2),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.lime,
                              foregroundColor: AppColors.primary,
                            ),
                            onPressed: () {
                              if (pantry.items.isEmpty) {
                                go(1);
                                return;
                              }
                              if (featured == null) {
                                go(2);
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeDetailScreen(match: featured),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                            label: Text(
                              pantry.items.isEmpty
                                  ? 'Preparar mi despensa'
                                  : 'Ver la receta',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Metric(
                value: '${pantry.items.length}',
                label: 'en tu despensa',
                icon: Icons.kitchen_outlined,
                onTap: () => go(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Metric(
                value: '$ready',
                label: 'recetas a mano',
                icon: Icons.restaurant_outlined,
                onTap: () {
                  ref
                      .read(recipeProvider.notifier)
                      .setFilter(RecipeFilterType.fullMatch);
                  go(2);
                },
              ),
            ),
          ],
        ),
        if (urgent.isNotEmpty) ...[
          const SectionHeading('Dales prioridad'),
          Surface(
            color: AppColors.accentLight,
            child: Row(
              children: [
                const Icon(Icons.eco_outlined, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        urgent.map((i) => i.name).take(3).join(', '),
                        style: AppTypography.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Los marcaste para usar pronto. Ya cuentan en tus sugerencias.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ver despensa',
                  onPressed: () => go(1),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
        ],
        if (todaySlots.isNotEmpty) ...[
          SectionHeading(
            'Hoy en tu mesa',
            action: 'Ver semana',
            onTap: () => go(3),
          ),
          ...todaySlots.map((entry) {
            final slot = entry.slot;
            final recipe = entry.recipe;
            final match = recipe.calculateMatch(pantry.activeIngredientNames);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(match: match),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            slot.mealType == 'breakfast'
                                ? Icons.wb_twilight_outlined
                                : slot.mealType == 'lunch'
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.mealTypeName.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                recipe.title,
                                style: AppTypography.labelLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${recipe.prepTimeMinutes} min · ${recipe.servings} porciones',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FoodArt(recipeId: recipe.id, size: 52),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
        SectionHeading(
          'Un poco de orden,\ntoda la semana.',
          action: 'Ver plan',
          onTap: () => go(3),
        ),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.date_range_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      plan.plannedCount == 0
                          ? 'Hazle espacio a cocinar.'
                          : '${plan.plannedCount} comidas organizadas',
                      style: AppTypography.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Elige tus comidas, aprovecha ingredientes en común y lleva los faltantes a una sola lista.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => go(3),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Organizar mi semana'),
              ),
            ],
          ),
        ),
        if (pantry.items.isNotEmpty && matches.length > 1) ...[
          SectionHeading(
            'Más ideas para ti',
            action: 'Ver todas',
            onTap: () => go(2),
          ),
          RecipeCardWidget(
            match: matches[1],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(match: matches[1]),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.primary,
          ),
          title: Text(
            '¿Tienes algo en mente?',
            style: AppTypography.labelLarge,
          ),
          subtitle: const Text('Busca una idea con tu asistente de cocina.'),
          trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiChefScreen()),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'HECHO PARA TU DÍA A DÍA',
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final VoidCallback onTap;
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(value, style: AppTypography.displayMedium),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
      ),
    ),
  );
}
