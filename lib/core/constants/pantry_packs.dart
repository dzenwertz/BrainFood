import '../../data/models/ingredient_item.dart';

class PantryPackItem {
  final String name;
  final String quantity;
  final IngredientCategory category;

  const PantryPackItem(this.name, this.quantity, this.category);
}

class PantryPack {
  final String id;
  final String title;
  final String description;
  final List<PantryPackItem> items;

  const PantryPack({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
  });
}

class PantryPacks {
  static const peruvian = PantryPack(
    id: 'peruvian',
    title: 'Básicos peruanos',
    description: 'Una base casera para arroces, guisos y desayunos.',
    items: [
      PantryPackItem('Arroz', '1 kg', IngredientCategory.grains),
      PantryPackItem('Papa', '1 kg', IngredientCategory.vegetables),
      PantryPackItem('Cebolla', '4 unidades', IngredientCategory.vegetables),
      PantryPackItem('Ajo', '1 cabeza', IngredientCategory.staples),
      PantryPackItem('Limón', '6 unidades', IngredientCategory.fruits),
      PantryPackItem('Huevos', '6 unidades', IngredientCategory.dairy),
      PantryPackItem(
        'Ají amarillo',
        '3 unidades',
        IngredientCategory.vegetables,
      ),
      PantryPackItem('Comino', '1 frasco', IngredientCategory.spices),
      PantryPackItem('Sal', '1 bolsa', IngredientCategory.staples),
      PantryPackItem(
        'Aceite de cocina',
        '1 botella',
        IngredientCategory.staples,
      ),
    ],
  );

  static const express = PantryPack(
    id: 'express',
    title: 'Despensa express',
    description: 'Comidas rápidas con pocos utensilios y productos rendidores.',
    items: [
      PantryPackItem('Huevos', '6 unidades', IngredientCategory.dairy),
      PantryPackItem('Atún en lata', '2 latas', IngredientCategory.proteins),
      PantryPackItem('Pasta', '1 paquete', IngredientCategory.grains),
      PantryPackItem('Arroz', '1 kg', IngredientCategory.grains),
      PantryPackItem('Tomate', '4 unidades', IngredientCategory.vegetables),
      PantryPackItem('Cebolla', '3 unidades', IngredientCategory.vegetables),
      PantryPackItem('Pan', '1 bolsa', IngredientCategory.grains),
      PantryPackItem('Queso', '250 g', IngredientCategory.dairy),
    ],
  );

  static const economical = PantryPack(
    id: 'economical',
    title: 'Semana económica',
    description: 'Ingredientes accesibles que se combinan en varias comidas.',
    items: [
      PantryPackItem('Lentejas', '500 g', IngredientCategory.grains),
      PantryPackItem('Arroz', '1 kg', IngredientCategory.grains),
      PantryPackItem('Huevos', '6 unidades', IngredientCategory.dairy),
      PantryPackItem('Papa', '1 kg', IngredientCategory.vegetables),
      PantryPackItem('Zanahoria', '4 unidades', IngredientCategory.vegetables),
      PantryPackItem('Cebolla', '4 unidades', IngredientCategory.vegetables),
      PantryPackItem('Avena', '500 g', IngredientCategory.grains),
      PantryPackItem('Plátano', '5 unidades', IngredientCategory.fruits),
    ],
  );

  static const vegetarian = PantryPack(
    id: 'vegetarian',
    title: 'Base vegetariana',
    description: 'Verduras, menestras y proteínas sencillas para la semana.',
    items: [
      PantryPackItem('Lentejas', '500 g', IngredientCategory.grains),
      PantryPackItem('Huevos', '6 unidades', IngredientCategory.dairy),
      PantryPackItem('Queso', '250 g', IngredientCategory.dairy),
      PantryPackItem('Espinaca', '1 atado', IngredientCategory.vegetables),
      PantryPackItem('Tomate', '4 unidades', IngredientCategory.vegetables),
      PantryPackItem('Zanahoria', '4 unidades', IngredientCategory.vegetables),
      PantryPackItem('Papa', '1 kg', IngredientCategory.vegetables),
      PantryPackItem('Arroz', '1 kg', IngredientCategory.grains),
    ],
  );

  static const all = [peruvian, express, economical, vegetarian];
}
