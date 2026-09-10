import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/shopping_list_formatter.dart';
import '../../data/models/ingredient_item.dart';
import '../../data/models/shopping_item.dart';
import '../state/shopping_state.dart';
import '../widgets/design_system.dart';
import 'main_shell.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});
  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  bool _groupByAisle = false;

  @override
  Widget build(BuildContext context) {
    final shopping = ref.watch(shoppingProvider);
    final notifier = ref.read(shoppingProvider.notifier);
    final items = [...shopping.items]
      ..sort((a, b) => (a.isBought ? 1 : 0).compareTo(b.isBought ? 1 : 0));
    return PageBody(
      children: [
        const PageHeading(
          eyebrow: 'Compra con intención',
          title: 'Solo lo que\nhace falta.',
          subtitle: 'Una lista para tu semana. Sin comprar dos veces.',
        ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: shopping.isLoading ? null : _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir producto'),
              ),
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              tooltip: 'Compartir lista',
              enabled: items.isNotEmpty,
              onSelected: (action) async {
                if (action == 'clear_bought') {
                  final count = await notifier.clearBought();
                  if (context.mounted) {
                    notify(context, '$count productos comprados eliminados.');
                  }
                  return;
                }
                final text = ShoppingListFormatter.pendingText(items);
                if (text.isEmpty) return;
                if (action == 'copy') {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    notify(context, 'Lista copiada.');
                  }
                  return;
                }
                final box = context.findRenderObject() as RenderBox?;
                await SharePlus.instance.share(
                  ShareParams(
                    text: text,
                    subject: 'Lista de compras de BrainFood',
                    sharePositionOrigin: box == null
                        ? null
                        : box.localToGlobal(Offset.zero) & box.size,
                  ),
                );
              },
              itemBuilder: (context) => [
                if (shopping.pendingCount > 0) ...[
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.ios_share_rounded),
                      title: Text('Compartir por WhatsApp…'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copy',
                    child: ListTile(
                      leading: Icon(Icons.copy_rounded),
                      title: Text('Copiar pendientes'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                if (shopping.boughtCount > 0)
                  const PopupMenuItem(
                    value: 'clear_bought',
                    child: ListTile(
                      leading: Icon(Icons.cleaning_services_outlined),
                      title: Text('Limpiar comprados'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (items.isNotEmpty)
          Surface(
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${shopping.boughtCount} de ${items.length} en tu bolsa',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: shopping.boughtCount / items.length,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Marca lo que compraste. Al terminar, pásalo a tu despensa.',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFFD5E1D0),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (items.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: !_groupByAisle,
                  onSelected: (sel) => setState(() => _groupByAisle = !sel),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.storefront_outlined, size: 16),
                  label: const Text('Por pasillo de compra'),
                  selected: _groupByAisle,
                  onSelected: (sel) => setState(() => _groupByAisle = sel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (shopping.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Tu lista, sin pendientes.',
            message:
                'Añade productos o lleva aquí los ingredientes que falten en tu plan.',
            action: 'Organizar la semana',
            onTap: () => ref.read(navigationProvider.notifier).select(3),
          )
        else if (_groupByAisle)
          ..._buildGroupedList(items, notifier, shopping.isTransferring)
        else
          ...items.map(
            (item) => _buildItemTile(item, notifier, shopping.isTransferring),
          ),
        if (shopping.boughtCount > 0) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: shopping.isTransferring
                ? null
                : () async {
                    try {
                      final count = await notifier.transferBoughtToPantry();
                      if (context.mounted) {
                        notify(
                          context,
                          '$count productos añadidos a tu despensa.',
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        notify(
                          context,
                          'No pudimos completar el traslado. Revisa tu despensa.',
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.kitchen_outlined),
            label: Text(
              shopping.isTransferring
                  ? 'Guardando…'
                  : 'Guardar comprados en despensa',
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: shopping.isTransferring
                ? null
                : () async {
                    final count = await notifier.clearBought();
                    if (context.mounted) {
                      notify(context, '$count productos comprados eliminados.');
                    }
                  },
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: const Text('Limpiar comprados'),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Toca la cantidad para editarla o desliza para eliminar. Los faltantes de recetas se agrupan por alimento.',
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }

  List<Widget> _buildGroupedList(
    List<ShoppingItem> items,
    ShoppingNotifier notifier,
    bool isTransferring,
  ) {
    final widgets = <Widget>[];
    for (final cat in IngredientCategory.values) {
      final inCat = items.where((i) => i.category == cat).toList();
      if (inCat.isEmpty) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              Icon(cat.iconData, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${cat.displayName.toUpperCase()} (${inCat.length})',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.1,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
      for (final item in inCat) {
        widgets.add(_buildItemTile(item, notifier, isTransferring));
      }
    }
    return widgets;
  }

  Widget _buildItemTile(
    ShoppingItem item,
    ShoppingNotifier notifier,
    bool isTransferring,
  ) {
    return Padding(
      key: ValueKey('tile_${item.id}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('dismiss_shop_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Eliminar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_outline_rounded, color: Colors.white),
            ],
          ),
        ),
        onDismissed: (_) async {
          await notifier.removeItem(item.id);
          if (mounted) {
            notify(
              context,
              '${item.name} eliminado.',
              action: SnackBarAction(
                label: 'Deshacer',
                onPressed: () => notifier.restoreItem(item),
              ),
            );
          }
        },
        child: Material(
          color: item.isBought ? AppColors.surfaceMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              Checkbox(
                value: item.isBought,
                onChanged: isTransferring
                    ? null
                    : (_) => notifier.toggleBought(item.id),
              ),
              Expanded(
                child: InkWell(
                  onTap: isTransferring
                      ? null
                      : () => _editQuantity(item.id, item.quantity),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.labelLarge.copyWith(
                            decoration: item.isBought
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          item.quantity,
                          style: AppTypography.bodySmall,
                        ),
                        if (item.recipeOriginTitle != null)
                          Text(
                            'Para: ${item.recipeOriginTitle}',
                            style: AppTypography.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar ${item.name}',
                onPressed: isTransferring
                    ? null
                    : () async {
                        await notifier.removeItem(item.id);
                        if (mounted) {
                          notify(
                            context,
                            '${item.name} eliminado.',
                            action: SnackBarAction(
                              label: 'Deshacer',
                              onPressed: () => notifier.restoreItem(item),
                            ),
                          );
                        }
                      },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add() => openSheet(context, const _ShoppingEditor());
  Future<void> _editQuantity(String id, String value) =>
      openSheet(context, _ShoppingEditor(itemId: id, initialQuantity: value));
}

class _ShoppingEditor extends ConsumerStatefulWidget {
  final String? itemId;
  final String initialQuantity;
  const _ShoppingEditor({this.itemId, this.initialQuantity = ''});
  @override
  ConsumerState<_ShoppingEditor> createState() => _ShoppingEditorState();
}

class _ShoppingEditorState extends ConsumerState<_ShoppingEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final TextEditingController _quantity = TextEditingController(
    text: widget.initialQuantity,
  );
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.itemId == null ? 'A tu lista.' : '¿Cuánto necesitas?',
          style: AppTypography.displayMedium,
        ),
        const SizedBox(height: 20),
        if (widget.itemId == null) ...[
          TextFormField(
            controller: _name,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Producto'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Escribe un producto.' : null,
          ),
          const SizedBox(height: 14),
        ],
        TextFormField(
          controller: _quantity,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            hintText: 'Por ejemplo, 4 unidades',
          ),
          validator: (v) =>
              widget.itemId != null && (v == null || v.trim().isEmpty)
              ? 'Indica una cantidad.'
              : null,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    setState(() => _saving = true);
                    try {
                      final notifier = ref.read(shoppingProvider.notifier);
                      final before = ref.read(shoppingProvider).items.length;
                      if (widget.itemId == null) {
                        await notifier.addItem(
                          name: _name.text,
                          category: ShoppingNotifier.guessCategory(_name.text),
                          quantity: _quantity.text.trim().isEmpty
                              ? 'Revisar cantidad'
                              : _quantity.text.trim(),
                        );
                      } else {
                        await notifier.updateQuantity(
                          widget.itemId!,
                          _quantity.text.trim(),
                        );
                      }
                      final duplicate =
                          widget.itemId == null &&
                          before == ref.read(shoppingProvider).items.length;
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      notify(
                        context,
                        duplicate
                            ? 'Este alimento ya estaba en tu lista.'
                            : 'Lista actualizada.',
                      );
                    } catch (_) {
                      if (context.mounted) {
                        setState(() => _saving = false);
                        notify(
                          context,
                          'No pudimos guardar. Inténtalo otra vez.',
                        );
                      }
                    }
                  },
            child: Text(
              _saving
                  ? 'Guardando…'
                  : widget.itemId == null
                  ? 'Añadir a mi lista'
                  : 'Guardar cantidad',
            ),
          ),
        ),
      ],
    ),
  );
}
