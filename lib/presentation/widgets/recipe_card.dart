import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/recipe.dart';
import '../state/preferences_state.dart';
import 'food_art.dart';
import 'design_system.dart';

class RecipeCardWidget extends ConsumerWidget {
  final RecipeMatch match;
  final VoidCallback onTap;
  final VoidCallback? onAddMissingToCart;
  const RecipeCardWidget({
    super.key,
    required this.match,
    required this.onTap,
    this.onAddMissingToCart,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = match.recipe;
    final favorite = ref
        .watch(preferencesProvider)
        .favorites
        .contains(recipe.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: AppColors.surfaceMuted,
                height: 170,
                child: Stack(
                  children: [
                    Center(child: FoodArt(recipeId: recipe.id, size: 185)),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filledTonal(
                        tooltip: favorite
                            ? 'Quitar de favoritas'
                            : 'Guardar receta',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                        ),
                        onPressed: () => ref
                            .read(preferencesProvider.notifier)
                            .toggleFavorite(recipe.id),
                        icon: Icon(
                          favorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 12,
                      child: StatusPill(
                        match.isFullMatch
                            ? 'Ingredientes disponibles'
                            : 'Faltan ${match.missingIngredients.length}',
                        warm: !match.isFullMatch,
                        icon: match.isFullMatch
                            ? Icons.check_rounded
                            : Icons.shopping_bag_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      recipe.description,
                      style: AppTypography.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _meta(
                          Icons.schedule_rounded,
                          '${recipe.prepTimeMinutes} min',
                        ),
                        _meta(
                          Icons.person_outline_rounded,
                          '${recipe.servings} ${recipe.servings == 1 ? 'porción' : 'porciones'}',
                        ),
                        if (recipe.isOnePot)
                          _meta(Icons.soup_kitchen_outlined, 'Una sartén'),
                      ],
                    ),
                    if (onAddMissingToCart != null && !match.isFullMatch) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onAddMissingToCart,
                        icon: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 17,
                        ),
                        label: const Text('Añadir faltantes'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 5),
      Text(text, style: AppTypography.bodySmall),
    ],
  );
}
