import '../../core/utils/ingredient_names.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ingredient_item.dart';
import '../../data/datasources/local_storage.dart';
import '../../core/constants/default_pantry_items.dart';
import '../../core/constants/pantry_packs.dart';

class PantryState {
  final List<IngredientItem> items;
  final bool isStaplesActive;
  final bool isLoading;
  final List<IngredientItem>? lastDeductedItems; // Para el botón 'Deshacer'

  PantryState({
    required this.items,
    this.isStaplesActive = false,
    this.isLoading = false,
    this.lastDeductedItems,
  });

  PantryState copyWith({
    List<IngredientItem>? items,
    bool? isStaplesActive,
    bool? isLoading,
    List<IngredientItem>? lastDeductedItems,
    bool clearLastDeducted = false,
  }) {
    return PantryState(
      items: items ?? this.items,
      isStaplesActive: isStaplesActive ?? this.isStaplesActive,
      isLoading: isLoading ?? this.isLoading,
      lastDeductedItems: clearLastDeducted
          ? null
          : (lastDeductedItems ?? this.lastDeductedItems),
    );
  }

  /// Lista de nombres para el comparador de recetas
  List<String> get activeIngredientNames {
    final list = items.map((e) => e.name).toList();
    if (isStaplesActive) {
      for (final staple in DefaultPantryConstants.defaultStaples) {
        if (!list.any(
          (name) => name.toLowerCase() == staple.name.toLowerCase(),
        )) {
          list.add(staple.name);
        }
      }
    }
    return list;
  }
}

class PantryNotifier extends Notifier<PantryState> {
  static const _uuid = Uuid();
  late Future<void> _ready;

  @override
  PantryState build() {
    _ready = _loadInitial();
    return PantryState(items: [], isLoading: true);
  }

  Future<void> _loadInitial() async {
    final loaded = await LocalStorageService.loadPantry();
    final staplesActive = await LocalStorageService.loadStaplesActive();
    if (!ref.mounted) return;
    state = state.copyWith(
      items: loaded,
      isStaplesActive: staplesActive,
      isLoading: false,
    );
  }

  Future<void> addIngredient({
    required String name,
    required IngredientCategory category,
    String quantity = '1 porción',
    bool isExpiringSoon = false,
  }) async {
    await _ready;
    if (name.trim().isEmpty) return;
    final existingIndex = state.items.indexWhere(
      (item) => sameIngredient(item.name, name),
    );

    List<IngredientItem> updated;
    if (existingIndex >= 0) {
      final current = state.items[existingIndex];
      final modified = current.copyWith(
        quantityDisplay: quantity,
        category: category,
        isExpiringSoon: isExpiringSoon,
      );
      updated = List.from(state.items)..[existingIndex] = modified;
    } else {
      final newItem = IngredientItem(
        id: 'ing_${_uuid.v4().substring(0, 8)}',
        name: name.trim(),
        category: category,
        quantityDisplay: quantity,
        isExpiringSoon: isExpiringSoon,
      );
      updated = [newItem, ...state.items];
    }

    state = state.copyWith(items: updated);
    await LocalStorageService.savePantry(updated);
  }

  /// Adds only foods the user does not already have. Existing quantities and
  /// priority flags are never overwritten by a starter pack.
  Future<int> addPackItems(List<PantryPackItem> selected) async {
    await _ready;
    final updated = [...state.items];
    var added = 0;
    for (final item in selected) {
      if (updated.any((current) => sameIngredient(current.name, item.name))) {
        continue;
      }
      updated.add(
        IngredientItem(
          id: 'ing_${_uuid.v4().substring(0, 8)}',
          name: item.name,
          category: item.category,
          quantityDisplay: item.quantity,
        ),
      );
      added++;
    }
    if (added == 0) return 0;
    state = state.copyWith(items: updated);
    await LocalStorageService.savePantry(updated);
    return added;
  }

  Future<void> removeIngredient(String id) async {
    final updated = state.items.where((e) => e.id != id).toList();
    state = state.copyWith(items: updated);
    await LocalStorageService.savePantry(updated);
  }

  Future<void> toggleExpiringSoon(String id) async {
    final updated = state.items.map((e) {
      if (e.id == id) {
        return e.copyWith(isExpiringSoon: !e.isExpiringSoon);
      }
      return e;
    }).toList();
    state = state.copyWith(items: updated);
    await LocalStorageService.savePantry(updated);
  }

  Future<void> toggleStaples() async {
    final next = !state.isStaplesActive;
    state = state.copyWith(isStaplesActive: next);
    await LocalStorageService.saveStaplesActive(next);
  }

  /// Descuenta ingredientes tras cocinar una receta
  Future<List<IngredientItem>> deductIngredientsForRecipe(
    List<String> requiredNames,
  ) async {
    final deducted = <IngredientItem>[];
    final remaining = <IngredientItem>[];

    for (final item in state.items) {
      final wasUsed = requiredNames.any((r) => sameIngredient(r, item.name));
      if (wasUsed && !item.isStaple) {
        deducted.add(item);
      } else {
        remaining.add(item);
      }
    }

    state = state.copyWith(items: remaining, lastDeductedItems: deducted);
    await LocalStorageService.savePantry(remaining);
    return deducted;
  }

  /// Deshacer deducción
  Future<void> undoDeduction() async {
    if (state.lastDeductedItems == null) return;
    final restored = [
      ...state.lastDeductedItems!.where(
        (old) => !state.items.any(
          (current) => sameIngredient(old.name, current.name),
        ),
      ),
      ...state.items,
    ];
    state = state.copyWith(items: restored, clearLastDeducted: true);
    await LocalStorageService.savePantry(restored);
  }
}

final pantryProvider = NotifierProvider<PantryNotifier, PantryState>(
  PantryNotifier.new,
);
