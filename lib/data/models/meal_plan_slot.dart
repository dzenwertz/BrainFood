class MealPlanSlot {
  final String id;
  final int dayOfWeek; // 1: Lunes, 7: Domingo
  final String mealType; // 'breakfast', 'lunch' o 'dinner'
  final String? recipeId;
  final String? recipeTitle;
  final String? prepTime;
  final bool isSkipped; // Si comió fuera o pospuso sin culpa

  MealPlanSlot({
    required this.id,
    required this.dayOfWeek,
    required this.mealType,
    this.recipeId,
    this.recipeTitle,
    this.prepTime,
    this.isSkipped = false,
  });

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Día';
    }
  }

  String get mealTypeName {
    switch (mealType) {
      case 'breakfast':
        return 'Desayuno';
      case 'lunch':
        return 'Almuerzo';
      case 'dinner':
        return 'Cena';
      default:
        return 'Comida';
    }
  }

  MealPlanSlot copyWith({
    String? id,
    int? dayOfWeek,
    String? mealType,
    String? recipeId,
    String? recipeTitle,
    String? prepTime,
    bool? isSkipped,
  }) {
    return MealPlanSlot(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      prepTime: prepTime ?? this.prepTime,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'mealType': mealType,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'prepTime': prepTime,
      'isSkipped': isSkipped,
    };
  }

  factory MealPlanSlot.fromJson(Map<String, dynamic> json) {
    return MealPlanSlot(
      id: json['id'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      mealType: json['mealType'] as String,
      recipeId: json['recipeId'] as String?,
      recipeTitle: json['recipeTitle'] as String?,
      prepTime: json['prepTime'] as String?,
      isSkipped: json['isSkipped'] as bool? ?? false,
    );
  }
}
