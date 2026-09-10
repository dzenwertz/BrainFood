import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/ingredient_names.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/ingredient_item.dart';
import '../../data/datasources/local_storage.dart';
import 'pantry_state.dart';

class ShoppingState {
  final List<ShoppingItem> items;
  final bool isLoading;
  final bool isTransferring;
  ShoppingState({
    required this.items,
    this.isLoading = false,
    this.isTransferring = false,
  });
  ShoppingState copyWith({
    List<ShoppingItem>? items,
    bool? isLoading,
    bool? isTransferring,
  }) => ShoppingState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isTransferring: isTransferring ?? this.isTransferring,
  );
  int get boughtCount => items.where((e) => e.isBought).length;
  int get pendingCount => items.length - boughtCount;
}

class ShoppingNotifier extends Notifier<ShoppingState> {
  static const _uuid = Uuid();
  late Future<void> _ready;
  @override
  ShoppingState build() {
    _ready = _load();
    return ShoppingState(items: [], isLoading: true);
  }

  Future<void> _load() async {
    final items = await LocalStorageService.loadShoppingList();
    if (ref.mounted) state = state.copyWith(items: items, isLoading: false);
  }

  Future<void> _save(List<ShoppingItem> items) async {
    state = state.copyWith(items: items);
    await LocalStorageService.saveShoppingList(items);
  }

  Future<void> addItem({
    required String name,
    IngredientCategory category = IngredientCategory.vegetables,
    String quantity = 'Revisar cantidad',
    double? estimatedPrice,
    String? recipeOrigin,
  }) async {
    await _ready;
    if (name.trim().isEmpty) return;
    final index = state.items.indexWhere((i) => sameIngredient(i.name, name));
    if (index >= 0) return; // A second tap must not uncheck purchases or overwrite quantities.
    await _save([
      ...state.items,
      ShoppingItem(
        id: _uuid.v4(),
        name: name.trim(),
        category: category,
        quantity: quantity,
        estimatedPrice: estimatedPrice,
        recipeOriginTitle: recipeOrigin,
      ),
    ]);
  }

  Future<int> addMissingFromRecipe(
    List<String> missing,
    String recipeTitle,
  ) async {
    await _ready;
    var count = 0;
    for (final name in missing) {
      if (state.items.any((i) => sameIngredient(i.name, name))) continue;
      await addItem(
        name: name,
        category: guessCategory(name),
        recipeOrigin: recipeTitle,
      );
      count++;
    }
    return count;
  }

  Future<void> toggleBought(String id) async => _save(
    state.items
        .map((i) => i.id == id ? i.copyWith(isBought: !i.isBought) : i)
        .toList(),
  );
  Future<void> removeItem(String id) async =>
      _save(state.items.where((i) => i.id != id).toList());
  Future<void> restoreItem(ShoppingItem item) async {
    if (state.items.any((i) => sameIngredient(i.name, item.name))) return;
    await _save([...state.items, item]);
  }

  Future<int> clearBought() async {
    await _ready;
    final count = state.boughtCount;
    final remaining = state.items.where((i) => !i.isBought).toList();
    await _save(remaining);
    return count;
  }

  Future<void> updateQuantity(String id, String quantity) async => _save(
    state.items
        .map((i) => i.id == id ? i.copyWith(quantity: quantity.trim()) : i)
        .toList(),
  );
  Future<int> transferBoughtToPantry() async {
    if (state.isTransferring) return 0;
    state = state.copyWith(isTransferring: true);
    try {
      final bought = state.items.where((i) => i.isBought).toList();
      final pantry = ref.read(pantryProvider.notifier);
      for (final item in bought) {
        // Preserve existing stock: quantities in the legacy model are approximate text.
        final existing = ref
            .read(pantryProvider)
            .items
            .where((i) => sameIngredient(i.name, item.name))
            .firstOrNull;
        await pantry.addIngredient(
          name: item.name,
          category: existing?.category ?? item.category,
          isExpiringSoon: existing?.isExpiringSoon ?? false,
          quantity: existing == null
              ? item.quantity
              : '${existing.quantityDisplay} + ${item.quantity}',
        );
      }
      final ids = bought.map((i) => i.id).toSet();
      await _save(state.items.where((i) => !ids.contains(i.id)).toList());
      return bought.length;
    } finally {
      state = state.copyWith(isTransferring: false);
    }
  }

  Future<void> clearAll() async => _save([]);
  static IngredientCategory guessCategory(String name) {
    final key = ingredientKey(name);
    if ([
      'pechuga de pollo',
      'pollo',
      'carne',
      'atun en lata',
      'pescado',
    ].contains(key)) {
      return IngredientCategory.proteins;
    }
    if (['huevo', 'queso', 'leche', 'yogur'].contains(key)) {
      return IngredientCategory.dairy;
    }
    if (['arroz', 'pasta', 'lentejas', 'pan', 'avena'].contains(key)) {
      return IngredientCategory.grains;
    }
    if (['limon', 'manzana', 'platano'].contains(key)) {
      return IngredientCategory.fruits;
    }
    if (['sal', 'aceite', 'pimienta', 'ajo'].contains(key)) {
      return IngredientCategory.staples;
    }
    return IngredientCategory.vegetables;
  }
}

final shoppingProvider = NotifierProvider<ShoppingNotifier, ShoppingState>(
  ShoppingNotifier.new,
);
