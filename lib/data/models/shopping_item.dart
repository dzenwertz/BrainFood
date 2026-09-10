import 'ingredient_item.dart';

class ShoppingItem {
  final String id;
  final String name;
  final IngredientCategory category;
  final String quantity;
  final bool isBought;
  final double? estimatedPrice;
  final String? recipeOriginTitle;

  ShoppingItem({
    required this.id,
    required this.name,
    this.category = IngredientCategory.vegetables,
    this.quantity = '1 unidad',
    this.isBought = false,
    this.estimatedPrice,
    this.recipeOriginTitle,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    IngredientCategory? category,
    String? quantity,
    bool? isBought,
    double? estimatedPrice,
    String? recipeOriginTitle,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      isBought: isBought ?? this.isBought,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      recipeOriginTitle: recipeOriginTitle ?? this.recipeOriginTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'quantity': quantity,
      'isBought': isBought,
      'estimatedPrice': estimatedPrice,
      'recipeOriginTitle': recipeOriginTitle,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: IngredientCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => IngredientCategory.vegetables,
      ),
      quantity: json['quantity'] as String? ?? '1 unidad',
      isBought: json['isBought'] as bool? ?? false,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
      recipeOriginTitle: json['recipeOriginTitle'] as String?,
    );
  }
}
