import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ingredient_item.dart';
import '../models/shopping_item.dart';
import '../models/meal_plan_slot.dart';
import '../models/recipe.dart';

class LocalStorageService {
  static const _keyPantry = 'brainfood_pantry_items';
  static const _keyShopping = 'brainfood_shopping_items';
  static const _keyMealPlan = 'brainfood_meal_plan';
  static const _keyCustomRecipes = 'brainfood_custom_recipes';
  static const _keyApiKey = 'brainfood_ai_api_key';
  static const _keyStaplesActive = 'brainfood_staples_active';

  // --- Despensa ---
  static Future<void> savePantry(List<IngredientItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_keyPantry, jsonEncode(jsonList));
  }

  static Future<List<IngredientItem>> loadPantry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPantry);
    if (raw == null || raw.isEmpty) {
      // New users explicitly choose their stock; never invent pantry contents.
      final defaults = <IngredientItem>[];
      await savePantry(defaults);
      return defaults;
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => IngredientItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Lista de Compras ---
  static Future<void> saveShoppingList(List<ShoppingItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((e) => e.toJson()).toList();
    await prefs.setString(_keyShopping, jsonEncode(jsonList));
  }

  static Future<List<ShoppingItem>> loadShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyShopping);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => ShoppingItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Plan Semanal ---
  static Future<void> saveMealPlan(List<MealPlanSlot> slots) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = slots.map((e) => e.toJson()).toList();
    await prefs.setString(_keyMealPlan, jsonEncode(jsonList));
  }

  static Future<List<MealPlanSlot>> loadMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMealPlan);
    if (raw == null || raw.isEmpty) {
      // Inicializar plantilla semanal vacía (Lunes a Domingo, Desayuno, Almuerzo y Cena)
      final initialSlots = <MealPlanSlot>[];
      for (int day = 1; day <= 7; day++) {
        initialSlots.add(
          MealPlanSlot(
            id: 'slot_${day}_breakfast',
            dayOfWeek: day,
            mealType: 'breakfast',
          ),
        );
        initialSlots.add(
          MealPlanSlot(
            id: 'slot_${day}_lunch',
            dayOfWeek: day,
            mealType: 'lunch',
          ),
        );
        initialSlots.add(
          MealPlanSlot(
            id: 'slot_${day}_dinner',
            dayOfWeek: day,
            mealType: 'dinner',
          ),
        );
      }
      await saveMealPlan(initialSlots);
      return initialSlots;
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => MealPlanSlot.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Recetas Generadas / Personalizadas ---
  static Future<void> saveCustomRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = recipes.map((e) => e.toJson()).toList();
    await prefs.setString(_keyCustomRecipes, jsonEncode(jsonList));
  }

  static Future<List<Recipe>> loadCustomRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCustomRecipes);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Recipe.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Configuración y Clave IA ---
  static Future<void> saveApiKey(String key) async {
    final provider = await loadAiProvider();
    await const FlutterSecureStorage().write(
      key: 'bf_key_$provider',
      value: key,
    );
  }

  static Future<String> loadApiKey() async {
    final provider = await loadAiProvider();
    if (provider == 'local') return '';
    return loadProviderKey(provider);
  }

  static Future<String> loadProviderKey(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    const secure = FlutterSecureStorage();
    // The original app used OpenRouter only. Never send its key to another provider.
    final old = prefs.getString(_keyApiKey);
    if (old != null && old.isNotEmpty) {
      final existing = await secure.read(key: 'bf_key_openrouter');
      if (existing == null) {
        await secure.write(key: 'bf_key_openrouter', value: old);
      }
      await prefs.remove(_keyApiKey);
    }
    return await secure.read(key: 'bf_key_$provider') ?? '';
  }

  static Future<String> loadAiProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('bf_ai_provider') ?? 'local';
  }

  static Future<String> loadAiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('bf_ai_model') ?? '';
  }

  static Future<void> saveAiConfiguration(
    String provider,
    String model,
    String key,
  ) async {
    if (provider != 'local') {
      await const FlutterSecureStorage().write(
        key: 'bf_key_$provider',
        value: key.trim(),
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bf_ai_model', model.trim());
    await prefs.setString('bf_ai_provider', provider);
  }

  static Future<void> saveStaplesActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStaplesActive, active);
  }

  static Future<bool> loadStaplesActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStaplesActive) ?? false;
  }
}
