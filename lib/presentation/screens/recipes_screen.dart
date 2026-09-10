import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/ingredient_names.dart';
import '../state/recipe_state.dart';
import '../state/shopping_state.dart';
import '../widgets/design_system.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});
  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  String _query = '';
  String? _category;
  bool _peruvianOnly = false;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(recipeProvider).currentFilter;
    final matches = ref.watch(recipeMatchesProvider).where((m) {
      final searchable = ingredientKey(
        '${m.recipe.title} ${m.recipe.description} '
        '${m.recipe.requiredIngredients.join(' ')} '
        '${m.recipe.optionalIngredients.join(' ')}',
      );
      return searchable.contains(ingredientKey(_query)) &&
          (_category == null || m.recipe.category == _category) &&
          (!_peruvianOnly || m.recipe.isPeruvian);
    }).toList();
    const filters = {
      RecipeFilterType.all: 'Para ti',
      RecipeFilterType.fullMatch: 'Con lo que tengo',
      RecipeFilterType.fast: 'Hasta 15 min',
      RecipeFilterType.oneMissing: 'Falta uno',
      RecipeFilterType.onePot: 'Una sartén',
      RecipeFilterType.favorites: 'Guardadas',
    };
    return PageBody(
      children: [
        const PageHeading(
          eyebrow: 'Algo rico, algo sencillo',
          title: 'Tu próxima\nbuena comida.',
          subtitle: 'Ideas ordenadas según tu despensa y preferencias.',
        ),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Busca un plato o ingrediente',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: e.key == filter,
                      onSelected: (_) =>
                          ref.read(recipeProvider.notifier).setFilter(e.key),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: const Icon(Icons.stars_rounded, size: 16),
                  label: const Text('Cocina peruana'),
                  selected: _peruvianOnly,
                  onSelected: (value) => setState(() => _peruvianOnly = value),
                ),
              ),
              ...['Desayuno', 'Almuerzo', 'Cena', 'Snack'].map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (selected) =>
                        setState(() => _category = selected ? category : null),
                  ),
                ),
              ),
            ],
          ),
        ),
        SectionHeading(
          '${matches.length} ${matches.length == 1 ? 'idea para cocinar' : 'ideas para cocinar'}',
        ),
        if (matches.isEmpty)
          EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Probemos otra idea.',
            message: filter == RecipeFilterType.favorites
                ? 'Guarda una receta con el marcador para encontrarla aquí.'
                : 'Cambia la búsqueda o los filtros. También puedes revisar los alimentos que prefieres evitar.',
            action: 'Ver todas las recetas',
            onTap: () {
              _search.clear();
              setState(() {
                _query = '';
                _category = null;
                _peruvianOnly = false;
              });
              ref.read(recipeProvider.notifier).setFilter(RecipeFilterType.all);
            },
          ),
        ...matches.map(
          (match) => RecipeCardWidget(
            match: match,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(match: match),
              ),
            ),
            onAddMissingToCart: () async {
              final count = await ref
                  .read(shoppingProvider.notifier)
                  .addMissingFromRecipe(
                    match.missingIngredients,
                    match.recipe.title,
                  );
              if (context.mounted) {
                notify(
                  context,
                  count == 0
                      ? 'Los faltantes ya están en tu lista.'
                      : '$count ingredientes añadidos a Compras.',
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
