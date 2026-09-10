import '../../data/models/ingredient_item.dart';
import '../../data/models/shopping_item.dart';

class ShoppingListFormatter {
  static String pendingText(List<ShoppingItem> items) {
    final pending = items.where((item) => !item.isBought).toList();
    if (pending.isEmpty) return '';

    final buffer = StringBuffer('Lista de BrainFood\n');
    for (final category in IngredientCategory.values) {
      final section =
          pending.where((item) => item.category == category).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
      if (section.isEmpty) continue;
      buffer
        ..writeln()
        ..writeln(category.displayName);
      for (final item in section) {
        buffer.writeln('☐ ${item.name} — ${item.quantity}');
      }
    }
    buffer
      ..writeln()
      ..write(
        '${pending.length} ${pending.length == 1 ? 'producto pendiente' : 'productos pendientes'}',
      );
    return buffer.toString();
  }
}
