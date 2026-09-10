import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/recipe.dart';
import '../datasources/curated_recipes.dart';
import '../datasources/local_storage.dart';
import '../../core/utils/ingredient_names.dart';

class AiRecipeService {
  static Future<Recipe> generateRecipe({
    required List<String> availableIngredients,
    required bool includeStaples,
    String? userPrompt,
    String? apiKey,
    http.Client? client,
  }) async {
    final ingredients = availableIngredients
        .where((i) => i.trim().isNotEmpty)
        .toSet()
        .toList();
    if (ingredients.isEmpty) {
      throw const FormatException(
        'Añade alimentos a tu despensa antes de buscar una idea.',
      );
    }
    final provider = await LocalStorageService.loadAiProvider();
    if (provider == 'local') return suggestLocal(ingredients, userPrompt);
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const FormatException(
        'Guarda una clave del proveedor elegido en Preferencias.',
      );
    }
    final model = await LocalStorageService.loadAiModel();
    if (model.isEmpty) {
      throw const FormatException(
        'Indica el identificador del modelo en Preferencias.',
      );
    }
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .post(
            Uri.parse(
              provider == 'opencode'
                  ? 'https://opencode.ai/zen/v1/chat/completions'
                  : 'https://openrouter.ai/api/v1/chat/completions',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': 1800,
              'temperature': .5,
              'messages': [
                {
                  'role': 'system',
                  'content': 'Propón una receta sencilla para una persona. Devuelve solo JSON. No inventes ingredientes disponibles. Incluye cantidades concretas en los pasos. Distingue alimentos crudos y cocidos. Incluye todos los ingredientes usados en requiredIngredients u optionalIngredients. No afirmes beneficios médicos ni garantías de seguridad. Esquema: title (texto), description (texto), category (texto), prepTimeMinutes (entero), servings (entero), isOnePot (booleano), requiredIngredients (lista de nombres sin cantidades), optionalIngredients (lista), steps (lista de pasos), tipsForLeftovers (texto).',
                },
                {
                  'role': 'user',
                  'content':
                      'Disponibles: ${ingredients.join(', ')}. Petición: ${userPrompt ?? 'Algo sencillo'}.',
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const FormatException(
          'El proveedor rechazó la clave. Revisa tu configuración.',
        );
      }
      if (response.statusCode == 402 || response.statusCode == 429) {
        throw const FormatException(
          'El proveedor alcanzó su límite o requiere saldo. Puedes usar el recetario local.',
        );
      }
      if (response.statusCode != 200) {
        throw const FormatException(
          'El proveedor no respondió correctamente. Inténtalo más tarde.',
        );
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(
        content
            .replaceAll('~~~', '')
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim(),
      );
      return validateRecipe(parsed);
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Recipe validateRecipe(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('La respuesta no tiene formato de receta.');
    }
    bool texts(dynamic v) =>
        v is List &&
        v.isNotEmpty &&
        v.length <= 30 &&
        v.every((e) => e is String && e.trim().isNotEmpty && e.length <= 2000);
    if (value['title'] is! String ||
        (value['title'] as String).trim().isEmpty ||
        (value['title'] as String).length > 180 ||
        !texts(value['requiredIngredients']) ||
        !texts(value['steps']) ||
        value['prepTimeMinutes'] is! int ||
        value['prepTimeMinutes'] < 1 ||
        value['prepTimeMinutes'] > 240 ||
        value['servings'] is! int ||
        value['servings'] < 1 ||
        value['servings'] > 12) {
      throw const FormatException(
        'La IA devolvió una receta incompleta. Prueba otra vez.',
      );
    }
    try {
      return Recipe.fromJson({
        ...value,
        'id': 'ai_${const Uuid().v4()}',
        'isAiGenerated': true,
      });
    } catch (_) {
      throw const FormatException(
        'No pudimos interpretar la receta. Prueba otra vez.',
      );
    }
  }

  static Recipe suggestLocal(List<String> ingredients, String? prompt) {
    final query = ingredientKey(prompt ?? '');
    var candidates = CuratedRecipes.baseRecipes
        .map((r) => r.calculateMatch(ingredients))
        .where((m) => m.isFullMatch)
        .toList();
    if (query.contains('15') || query.contains('rapida')) {
      candidates = candidates
          .where((m) => m.recipe.prepTimeMinutes <= 15)
          .toList();
    }
    if (query.contains('sarten')) {
      candidates = candidates.where((m) => m.recipe.isOnePot).toList();
    }
    if (candidates.isEmpty) {
      throw const FormatException(
        'Todavía no hay una receta local completa con estos alimentos y filtros. Explora Recetas para ver qué te falta.',
      );
    }
    candidates.sort(
      (a, b) => a.recipe.prepTimeMinutes.compareTo(b.recipe.prepTimeMinutes),
    );
    return candidates.first.recipe;
  }
}
