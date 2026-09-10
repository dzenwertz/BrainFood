import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/recipe.dart';
import '../../data/datasources/local_storage.dart';
import '../state/pantry_state.dart';
import '../state/recipe_state.dart';
import '../widgets/design_system.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'settings_screen.dart';

class AiChefScreen extends ConsumerStatefulWidget {
  const AiChefScreen({super.key});
  @override
  ConsumerState<AiChefScreen> createState() => _AiChefScreenState();
}

class _AiChefScreenState extends ConsumerState<AiChefScreen> {
  final _prompt = TextEditingController();
  String _provider = 'local';
  bool _loading = true;
  Recipe? _result;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = await LocalStorageService.loadAiProvider();
    if (mounted) {
      setState(() {
        _provider = provider;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);
    final recipes = ref.watch(recipeProvider);
    final local = _provider == 'local';
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente de cocina')),
      body: PageBody(
        children: [
          const PageHeading(
            eyebrow: 'Un poco de inspiración',
            title: 'Hoy se te\nantoja…',
            subtitle: 'Empieza por lo que tienes y dale tu toque.',
          ),
          Surface(
            color: AppColors.primaryLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  _loading
                      ? 'Cargando configuración'
                      : local
                      ? 'Recetario local · sin conexión'
                      : _provider == 'opencode'
                      ? 'OpenCode Zen'
                      : 'OpenRouter',
                  icon: local
                      ? Icons.offline_bolt_outlined
                      : Icons.auto_awesome_outlined,
                ),
                const SizedBox(height: 12),
                Text(
                  local
                      ? 'Busca entre las recetas incluidas. Las opciones rápidas y de una sartén funcionan como filtros; el texto libre requiere IA.'
                      : 'Se enviarán al proveedor los nombres de tus alimentos y esta petición. Revisa el resultado antes de cocinar.',
                  style: AppTypography.bodyMedium,
                ),
                TextButton(
                  onPressed: recipes.isGeneratingAi
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                          if (mounted) _load();
                        },
                  child: Text(
                    local ? 'Configurar IA opcional' : 'Cambiar configuración',
                  ),
                ),
              ],
            ),
          ),
          const SectionHeading('Con lo que hay en casa'),
          if (pantry.items.isEmpty)
            const Text('Tu despensa está vacía. Añade alimentos para empezar.')
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: pantry.items
                  .map((i) => Chip(label: Text(i.name)))
                  .toList(),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ['Hasta 15 minutos', 'Una sartén', 'Algo sencillo']
                .map(
                  (text) => ActionChip(
                    label: Text(text),
                    onPressed: recipes.isGeneratingAi
                        ? null
                        : () => setState(() => _prompt.text = text),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _prompt,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Por ejemplo: una cena rápida para hoy',
              labelText: 'Tu idea',
            ),
            enabled: !recipes.isGeneratingAi,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                _loading ||
                    pantry.isLoading ||
                    pantry.items.isEmpty ||
                    recipes.isGeneratingAi
                ? null
                : () async {
                    setState(() => _result = null);
                    final result = await ref
                        .read(recipeProvider.notifier)
                        .generateAiRecipe(prompt: _prompt.text.trim());
                    if (mounted) setState(() => _result = result);
                  },
            icon: recipes.isGeneratingAi
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(
              recipes.isGeneratingAi
                  ? 'Buscando una idea…'
                  : local
                  ? 'Buscar en mi recetario'
                  : 'Pedir una idea a la IA',
            ),
          ),
          if (recipes.lastAiError != null) ...[
            const SizedBox(height: 20),
            Surface(
              color: AppColors.accentLight,
              child: Text(
                recipes.lastAiError!,
                style: AppTypography.bodyMedium,
              ),
            ),
          ],
          if (_result != null) ...[
            SectionHeading(
              _result!.isAiGenerated
                  ? 'Una nueva sugerencia'
                  : 'Encontrada en tu recetario',
            ),
            Reveal(
              child: RecipeCardWidget(
                match: _result!.calculateMatch(pantry.activeIngredientNames),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(
                      match: _result!.calculateMatch(
                        pantry.activeIngredientNames,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
