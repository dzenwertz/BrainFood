import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/ingredient_names.dart';
import '../../core/constants/default_pantry_items.dart';
import '../../core/constants/pantry_packs.dart';
import '../../data/models/ingredient_item.dart';
import '../state/pantry_state.dart';
import '../widgets/design_system.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});
  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  String _query = '';
  bool _urgentOnly = false;
  IngredientCategory? _category;
  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);
    final items =
        pantry.items
            .where(
              (i) =>
                  (_category == null || i.category == _category) &&
                  (!_urgentOnly || i.isExpiringSoon) &&
                  ingredientKey(i.name).contains(ingredientKey(_query)),
            )
            .toList()
          ..sort(
            (a, b) =>
                (b.isExpiringSoon ? 1 : 0).compareTo(a.isExpiringSoon ? 1 : 0),
          );
    return PageBody(
      children: [
        const PageHeading(
          eyebrow: 'El punto de partida',
          title: 'Lo bueno\nempieza en casa.',
          subtitle: 'Ten a mano lo que tienes. Dale uso a lo que queda.',
        ),
        FilledButton.icon(
          onPressed: pantry.isLoading
              ? null
              : () => openSheet(context, const IngredientEditor()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Añadir alimento'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: pantry.isLoading
              ? null
              : () => openSheet(context, const PantryPackPicker()),
          icon: const Icon(Icons.auto_awesome_mosaic_outlined),
          label: const Text('Empezar con una despensa rápida'),
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Buscar en mi despensa',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Usar pronto'),
                  avatar: const Icon(Icons.eco_outlined, size: 16),
                  selected: _urgentOnly,
                  onSelected: (v) => setState(() => _urgentOnly = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Todo'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              ...IngredientCategory.values.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.displayName),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionHeading('${items.length} alimentos'),
        if (pantry.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          EmptyState(
            icon: Icons.kitchen_outlined,
            title: pantry.items.isEmpty
                ? 'Una despensa a tu medida.'
                : 'Nada por aquí todavía.',
            message: pantry.items.isEmpty
                ? 'Empieza con 3 o 4 alimentos. No necesitas registrar toda tu cocina de una vez.'
                : 'Prueba otra categoría o añade un alimento.',
            action: 'Añadir mi primer alimento',
            onTap: () => openSheet(context, const IngredientEditor()),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey('pantry_${item.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(20),
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
                  await ref
                      .read(pantryProvider.notifier)
                      .removeIngredient(item.id);
                  if (context.mounted) {
                    final notifier = ref.read(pantryProvider.notifier);
                    notify(
                      context,
                      '${item.name} eliminado de la despensa.',
                      action: SnackBarAction(
                        label: 'Deshacer',
                        onPressed: () => notifier.addIngredient(
                          name: item.name,
                          category: item.category,
                          quantity: item.quantityDisplay,
                          isExpiringSoon: item.isExpiringSoon,
                        ),
                      ),
                    );
                  }
                },
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: item.isExpiringSoon
                            ? AppColors.accentLight
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        item.category.iconData,
                        color: item.isExpiringSoon
                            ? AppColors.accent
                            : AppColors.primary,
                      ),
                    ),
                    title: Text(item.name, style: AppTypography.labelLarge),
                    subtitle: Text(
                      '${item.quantityDisplay}${item.isExpiringSoon ? ' · Usar pronto' : ''}',
                      style: AppTypography.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () => openSheet(context, IngredientEditor(item: item)),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Surface(
          color: AppColors.surfaceMuted,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textSecondary,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Las cantidades son aproximadas. “Usar pronto” es un recordatorio que tú marcas, no una fecha de caducidad.',
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SectionHeading('Básicos de cocina'),
        Surface(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            title: const Text('Tengo los básicos habituales'),
            subtitle: const Text(
              'Contar con sal, aceite de cocina, pimienta y ajo al buscar recetas.',
            ),
            value: pantry.isStaplesActive,
            onChanged: pantry.isLoading
                ? null
                : (_) => ref.read(pantryProvider.notifier).toggleStaples(),
          ),
        ),
      ],
    );
  }
}

class PantryPackPicker extends ConsumerStatefulWidget {
  const PantryPackPicker({super.key});

  @override
  ConsumerState<PantryPackPicker> createState() => _PantryPackPickerState();
}

class _PantryPackPickerState extends ConsumerState<PantryPackPicker> {
  PantryPack? _pack;
  final Set<String> _selected = {};
  bool _saving = false;

  void _choose(PantryPack pack) {
    setState(() {
      _pack = pack;
      _selected
        ..clear()
        ..addAll(pack.items.map((item) => item.name));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pack == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu despensa, sin empezar de cero.',
            style: AppTypography.displayMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Elige una base. Antes de guardarla podrás desmarcar todo lo que no tengas.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 20),
          ...PantryPacks.all.map(
            (pack) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(pack.title, style: AppTypography.titleMedium),
                  subtitle: Text(
                    '${pack.description}\n${pack.items.length} sugerencias',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _choose(pack),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final pack = _pack!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _saving ? null : () => setState(() => _pack = null),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Ver otros paquetes'),
        ),
        Text(pack.title, style: AppTypography.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Marca únicamente lo que tienes ahora. Las cantidades se pueden editar después.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 14),
        ...pack.items.map(
          (item) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selected.contains(item.name),
            title: Text(item.name),
            subtitle: Text(item.quantity),
            onChanged: _saving
                ? null
                : (selected) => setState(() {
                    selected == true
                        ? _selected.add(item.name)
                        : _selected.remove(item.name);
                  }),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving || _selected.isEmpty
                ? null
                : () async {
                    setState(() => _saving = true);
                    final selected = pack.items
                        .where((item) => _selected.contains(item.name))
                        .toList();
                    final count = await ref
                        .read(pantryProvider.notifier)
                        .addPackItems(selected);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    notify(
                      context,
                      count == 0
                          ? 'Ya tenías todos estos alimentos.'
                          : '$count alimentos añadidos a tu despensa.',
                    );
                  },
            child: Text(
              _saving ? 'Guardando…' : 'Añadir ${_selected.length} alimentos',
            ),
          ),
        ),
      ],
    );
  }
}

class IngredientEditor extends ConsumerStatefulWidget {
  final IngredientItem? item;
  const IngredientEditor({super.key, this.item});
  @override
  ConsumerState<IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends ConsumerState<IngredientEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _quantity;
  late IngredientCategory _category;
  late bool _urgent;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _quantity = TextEditingController(text: widget.item?.quantityDisplay ?? '');
    _category = widget.item?.category ?? IngredientCategory.vegetables;
    _urgent = widget.item?.isExpiringSoon ?? false;
  }

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
          widget.item == null
              ? 'Un alimento más,\nmuchas posibilidades.'
              : 'Tu alimento, al día.',
          style: AppTypography.displayMedium,
        ),
        const SizedBox(height: 12),
        Text(
          widget.item == null
              ? 'Elige un habitual o escribe el tuyo.'
              : 'Actualiza la cantidad que queda o márcalo para usar pronto.',
          style: AppTypography.bodyMedium,
        ),
        if (widget.item == null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: DefaultPantryConstants.quickSuggestions
                .take(8)
                .map(
                  (s) => ActionChip(
                    label: Text(s['name'] as String),
                    onPressed: () => setState(() {
                      _name.text = s['name'] as String;
                      _quantity.text = s['qty'] as String;
                      _category = s['category'] as IngredientCategory;
                    }),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        TextFormField(
          controller: _name,
          readOnly: widget.item != null,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Alimento',
            hintText: 'Por ejemplo, tomate',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Escribe el nombre del alimento.'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _quantity,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Cantidad aproximada',
            hintText: '2 unidades, 200 g, medio paquete…',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Indica cuánto tienes, aunque sea aproximado.'
              : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<IngredientCategory>(
          initialValue: _category,
          key: ValueKey(_category),
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Categoría'),
          items: IngredientCategory.values
              .map(
                (c) => DropdownMenuItem(value: c, child: Text(c.displayName)),
              )
              .toList(),
          onChanged: (c) => setState(() => _category = c!),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Quiero usarlo pronto'),
          subtitle: const Text('Tendrá prioridad en tus sugerencias.'),
          value: _urgent,
          onChanged: (v) => setState(() => _urgent = v),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    setState(() => _saving = true);
                    try {
                      await ref
                          .read(pantryProvider.notifier)
                          .addIngredient(
                            name: _name.text,
                            category: _category,
                            quantity: _quantity.text.trim(),
                            isExpiringSoon: _urgent,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        notify(context, 'Despensa actualizada.');
                      }
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
            child: Text(_saving ? 'Guardando…' : 'Guardar alimento'),
          ),
        ),
        if (widget.item != null)
          TextButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    final item = widget.item!;
                    await ref
                        .read(pantryProvider.notifier)
                        .removeIngredient(item.id);
                    if (!context.mounted) return;
                    final notifier = ref.read(pantryProvider.notifier);
                    Navigator.pop(context);
                    notify(
                      context,
                      '${item.name} eliminado.',
                      action: SnackBarAction(
                        label: 'Deshacer',
                        onPressed: () => notifier.addIngredient(
                          name: item.name,
                          category: item.category,
                          quantity: item.quantityDisplay,
                          isExpiringSoon: item.isExpiringSoon,
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Ya no lo tengo'),
          ),
      ],
    ),
  );
}
