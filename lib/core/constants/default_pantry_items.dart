import '../../data/models/ingredient_item.dart';

class DefaultPantryConstants {
  static List<IngredientItem> get defaultStaples => [
    IngredientItem(
      id: 'staple_salt',
      name: 'Sal',
      category: IngredientCategory.staples,
      quantityDisplay: 'En alacena',
      isStaple: true,
    ),
    IngredientItem(
      id: 'staple_oil',
      name: 'Aceite de cocina',
      category: IngredientCategory.staples,
      quantityDisplay: 'En alacena',
      isStaple: true,
    ),
    IngredientItem(
      id: 'staple_pepper',
      name: 'Pimienta negra',
      category: IngredientCategory.staples,
      quantityDisplay: 'En alacena',
      isStaple: true,
    ),
    IngredientItem(
      id: 'staple_garlic',
      name: 'Ajo',
      category: IngredientCategory.staples,
      quantityDisplay: '3 dientes',
      isStaple: true,
    ),
  ];

  /// Sugerencias rápidas para añadir con 1 toque en el selector
  static List<Map<String, dynamic>> get quickSuggestions => [
    {
      'name': 'Tomate',
      'category': IngredientCategory.vegetables,
      'qty': '2 unidades',
    },
    {
      'name': 'Cebolla',
      'category': IngredientCategory.vegetables,
      'qty': '1 unidad',
    },
    {
      'name': 'Limón',
      'category': IngredientCategory.fruits,
      'qty': '3 unidades',
    },
    {
      'name': 'Pechuga de pollo',
      'category': IngredientCategory.proteins,
      'qty': '1 pieza',
    },
    {
      'name': 'Huevos',
      'category': IngredientCategory.dairy,
      'qty': '6 unidades',
    },
    {
      'name': 'Atún en lata',
      'category': IngredientCategory.proteins,
      'qty': '2 latas',
    },
    {
      'name': 'Arroz',
      'category': IngredientCategory.grains,
      'qty': 'Medio kilo',
    },
    {
      'name': 'Pasta',
      'category': IngredientCategory.grains,
      'qty': '1 paquete',
    },
    {
      'name': 'Papa',
      'category': IngredientCategory.vegetables,
      'qty': '3 unidades',
    },
    {
      'name': 'Zanahoria',
      'category': IngredientCategory.vegetables,
      'qty': '2 unidades',
    },
    {
      'name': 'Espinaca',
      'category': IngredientCategory.vegetables,
      'qty': '1 atado',
    },
    {'name': 'Queso', 'category': IngredientCategory.dairy, 'qty': '200 g'},
    {'name': 'Leche', 'category': IngredientCategory.dairy, 'qty': '1 litro'},
    {'name': 'Avena', 'category': IngredientCategory.grains, 'qty': '1 bolsa'},
    {
      'name': 'Lentejas',
      'category': IngredientCategory.grains,
      'qty': 'Medio kilo',
    },
    {'name': 'Pan', 'category': IngredientCategory.grains, 'qty': '3 piezas'},
  ];
}
