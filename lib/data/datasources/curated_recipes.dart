import '../models/recipe.dart';
import 'recipes/pasta_recipes.dart';
import 'recipes/rice_grain_recipes.dart';
import 'recipes/legume_soup_recipes.dart';
import 'recipes/chicken_recipes.dart';
import 'recipes/meat_pork_recipes.dart';
import 'recipes/fish_seafood_recipes.dart';
import 'recipes/eggs_breakfast_recipes.dart';
import 'recipes/salad_bowl_recipes.dart';
import 'recipes/sandwich_toast_wrap_recipes.dart';
import 'recipes/veggie_side_recipes.dart';
import 'recipes/peruvian_comfort_recipes.dart';

class CuratedRecipes {
  /// Catálogo completo de más de 100 recetas curadas de cocina real,
  /// organizadas por módulos temáticos y optimizadas para cero desperdicio.
  static List<Recipe> get baseRecipes => [
    ...PastaRecipes.recipes,
    ...RiceGrainRecipes.recipes,
    ...LegumeSoupRecipes.recipes,
    ...ChickenRecipes.recipes,
    ...MeatPorkRecipes.recipes,
    ...FishSeafoodRecipes.recipes,
    ...EggsBreakfastRecipes.recipes,
    ...SaladBowlRecipes.recipes,
    ...SandwichToastWrapRecipes.recipes,
    ...VeggieSideRecipes.recipes,
    ...PeruvianComfortRecipes.recipes,
  ];
}
