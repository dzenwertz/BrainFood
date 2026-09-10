import 'package:flutter/material.dart';

enum IngredientCategory {
  vegetables,
  proteins,
  dairy,
  grains,
  spices,
  fruits,
  staples;

  String get displayName {
    switch (this) {
      case IngredientCategory.vegetables:
        return 'Verduras';
      case IngredientCategory.proteins:
        return 'Proteínas';
      case IngredientCategory.dairy:
        return 'Lácteos y Huevos';
      case IngredientCategory.grains:
        return 'Granos y Pastas';
      case IngredientCategory.spices:
        return 'Especias';
      case IngredientCategory.fruits:
        return 'Frutas';
      case IngredientCategory.staples:
        return 'Básicos';
    }
  }

  IconData get iconData {
    switch (this) {
      case IngredientCategory.vegetables:
        return Icons.eco_outlined;
      case IngredientCategory.proteins:
        return Icons.set_meal_outlined;
      case IngredientCategory.dairy:
        return Icons.egg_outlined;
      case IngredientCategory.grains:
        return Icons.grain_outlined;
      case IngredientCategory.spices:
        return Icons.scatter_plot_outlined;
      case IngredientCategory.fruits:
        return Icons.apple_outlined;
      case IngredientCategory.staples:
        return Icons.kitchen_outlined;
    }
  }
}

class IngredientItem {
  final String id;
  final String name;
  final IngredientCategory category;
  final String quantityDisplay;
  final bool isStaple;
  final bool isExpiringSoon;
  final DateTime addedDate;

  IngredientItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantityDisplay = '1 porción',
    this.isStaple = false,
    this.isExpiringSoon = false,
    DateTime? addedDate,
  }) : addedDate = addedDate ?? DateTime.now();

  IngredientItem copyWith({
    String? id,
    String? name,
    IngredientCategory? category,
    String? quantityDisplay,
    bool? isStaple,
    bool? isExpiringSoon,
    DateTime? addedDate,
  }) {
    return IngredientItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantityDisplay: quantityDisplay ?? this.quantityDisplay,
      isStaple: isStaple ?? this.isStaple,
      isExpiringSoon: isExpiringSoon ?? this.isExpiringSoon,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'quantityDisplay': quantityDisplay,
      'isStaple': isStaple,
      'isExpiringSoon': isExpiringSoon,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    return IngredientItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: IngredientCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => IngredientCategory.vegetables,
      ),
      quantityDisplay: json['quantityDisplay'] as String? ?? '1 porción',
      isStaple: json['isStaple'] as bool? ?? false,
      isExpiringSoon: json['isExpiringSoon'] as bool? ?? false,
      addedDate: json['addedDate'] != null
          ? DateTime.parse(json['addedDate'] as String)
          : DateTime.now(),
    );
  }
}
