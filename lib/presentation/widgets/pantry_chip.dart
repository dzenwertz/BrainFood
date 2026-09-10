import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/ingredient_item.dart';

class PantryChipWidget extends StatelessWidget {
  final IngredientItem item;
  final VoidCallback onToggleExpiring;
  final VoidCallback onDelete;

  const PantryChipWidget({
    super.key,
    required this.item,
    required this.onToggleExpiring,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpiring = item.isExpiringSoon;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpiring ? AppColors.statusWarning : AppColors.border,
          width: isExpiring ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Icono vectorial de categoría con fondo suave
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isExpiring
                  ? AppColors.statusWarningLight
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.category.iconData,
              size: 20,
              color: isExpiring ? AppColors.statusWarning : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),

          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: AppTypography.titleMedium.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isExpiring) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Usar pronto',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.statusWarning,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.isStaple ? 'Básico de cocina' : item.quantityDisplay,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),

          // Menú de opciones sutil
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: AppColors.surface,
            elevation: 4,
            onSelected: (value) {
              if (value == 'expire') {
                onToggleExpiring();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'expire',
                child: Row(
                  children: [
                    Icon(
                      isExpiring
                          ? Icons.check_circle_outline
                          : Icons.access_time_rounded,
                      size: 18,
                      color: AppColors.statusWarning,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isExpiring ? 'Marcar fresco' : 'Consumir pronto',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.statusUrgent,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Retirar de despensa',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.statusUrgent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
