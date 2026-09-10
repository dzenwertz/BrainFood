import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  final Set<String> favorites;
  final Set<String> excluded;
  final int maxMinutes;
  const Preferences({
    this.favorites = const {},
    this.excluded = const {},
    this.maxMinutes = 45,
  });
}

class PreferencesNotifier extends Notifier<Preferences> {
  late Future<void> _ready;
  @override
  Preferences build() {
    _ready = _load();
    return const Preferences();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    state = Preferences(
      favorites: (p.getStringList('bf_favorites') ?? []).toSet(),
      excluded: (p.getStringList('bf_excluded') ?? []).toSet(),
      maxMinutes: p.getInt('bf_max_minutes') ?? 45,
    );
  }

  Future<void> toggleFavorite(String id) async {
    await _ready;
    final values = {...state.favorites};
    values.contains(id) ? values.remove(id) : values.add(id);
    state = Preferences(
      favorites: values,
      excluded: state.excluded,
      maxMinutes: state.maxMinutes,
    );
    final p = await SharedPreferences.getInstance();
    await p.setStringList('bf_favorites', values.toList());
  }

  Future<void> update({Set<String>? excluded, int? maxMinutes}) async {
    await _ready;
    state = Preferences(
      favorites: state.favorites,
      excluded: excluded ?? state.excluded,
      maxMinutes: maxMinutes ?? state.maxMinutes,
    );
    final p = await SharedPreferences.getInstance();
    await p.setStringList('bf_excluded', state.excluded.toList());
    await p.setInt('bf_max_minutes', state.maxMinutes);
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, Preferences>(
  PreferencesNotifier.new,
);
