import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/ingredient_names.dart';
import '../../data/datasources/local_storage.dart';
import '../../data/datasources/curated_recipes.dart';
import '../state/preferences_state.dart';
import '../widgets/design_system.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _key = TextEditingController(), _model = TextEditingController();
  String _provider = 'local';
  bool _loading = true, _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _provider = await LocalStorageService.loadAiProvider();
      _model.text = await LocalStorageService.loadAiModel();
      if (_provider != 'local') {
        _key.text = await LocalStorageService.loadProviderKey(_provider);
      }
    } catch (_) {
      if (mounted) notify(context, 'No pudimos leer la configuración de IA.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final ingredients =
        CuratedRecipes.baseRecipes
            .expand((r) => r.requiredIngredients)
            .toSet()
            .toList()
          ..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias')),
      body: PageBody(
        children: [
          const PageHeading(
            eyebrow: 'A tu manera',
            title: 'Tu cocina.\nTus reglas.',
            subtitle: 'Pequeños ajustes para que las ideas encajen contigo.',
          ),
          const SectionHeading('¿Cuánto tiempo tienes?'),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo habitual para cocinar',
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [15, 30, 45, 60]
                      .map(
                        (minutes) => ChoiceChip(
                          label: Text('$minutes min'),
                          selected: prefs.maxMinutes == minutes,
                          onSelected: (_) => ref
                              .read(preferencesProvider.notifier)
                              .update(maxMinutes: minutes),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                const Text('El plan automático respetará este límite.'),
              ],
            ),
          ),
          const SectionHeading('Alimentos que prefieres evitar'),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se ocultarán recetas que los requieren. Estas preferencias no certifican que un plato sea apto para alergias.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: ingredients.map((name) {
                    final key = ingredientKey(name);
                    return FilterChip(
                      label: Text(name),
                      selected: prefs.excluded.contains(key),
                      onSelected: (selected) {
                        final next = {...prefs.excluded};
                        selected ? next.add(key) : next.remove(key);
                        ref
                            .read(preferencesProvider.notifier)
                            .update(excluded: next);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SectionHeading('Asistente de cocina'),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elige cómo encontrar nuevas ideas.',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    initialValue: _provider,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Proveedor'),
                    items: const [
                      DropdownMenuItem(
                        value: 'local',
                        child: Text('Recetario local · sin IA'),
                      ),
                      DropdownMenuItem(
                        value: 'opencode',
                        child: Text('OpenCode Zen'),
                      ),
                      DropdownMenuItem(
                        value: 'openrouter',
                        child: Text('OpenRouter'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (provider) async {
                            if (provider == null) return;
                            setState(() {
                              _provider = provider;
                              _saving = true;
                              _key.clear();
                              _model.text = provider == 'opencode'
                                  ? 'big-pickle'
                                  : '';
                            });
                            try {
                              if (provider != 'local') {
                                _key.text =
                                    await LocalStorageService.loadProviderKey(
                                      provider,
                                    );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                notify(
                                  context,
                                  'Introduce de nuevo la clave del proveedor.',
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                  ),
                const SizedBox(height: 14),
                if (_provider != 'local') ...[
                  TextField(
                    controller: _model,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Identificador del modelo',
                      hintText: 'Modelo compatible con Chat Completions',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _key,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Clave de API del proveedor',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'La clave se guarda cifrada en este dispositivo. Los modelos, precios y límites dependen del proveedor; algunos modelos gratuitos pueden usar las peticiones para mejorar sus servicios.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ] else
                  Text(
                    'Las recetas, tu despensa, el calendario y las compras funcionan sin cuenta ni conexión.',
                    style: AppTypography.bodyMedium,
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading || _saving
                        ? null
                        : () async {
                            if (_provider != 'local' &&
                                (_key.text.trim().isEmpty ||
                                    _model.text.trim().isEmpty)) {
                              notify(
                                context,
                                'Completa el modelo y la clave del proveedor.',
                              );
                              return;
                            }
                            setState(() => _saving = true);
                            try {
                              await LocalStorageService.saveAiConfiguration(
                                _provider,
                                _model.text,
                                _key.text,
                              );
                              if (context.mounted) {
                                notify(context, 'Configuración guardada.');
                              }
                            } catch (_) {
                              if (context.mounted) {
                                notify(
                                  context,
                                  'No pudimos guardar la configuración. Inténtalo otra vez.',
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: Text(
                      _saving ? 'Guardando…' : 'Guardar configuración',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Surface(
            color: AppColors.primaryLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(),
                const SizedBox(height: 14),
                Text(
                  'Menos vueltas.\nMás cocina en casa.',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Tus datos se guardan en este teléfono. Todavía no hay sincronización entre dispositivos. Desinstalar la app puede borrar tu despensa y tus planes.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
