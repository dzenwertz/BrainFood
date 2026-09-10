import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/recipe.dart';
import '../widgets/design_system.dart';

class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookingModeScreen({super.key, required this.recipe});
  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen>
    with WidgetsBindingObserver {
  late final PageController _pages;
  final Set<int> _completed = {};
  final Map<int, DateTime> _deadlines = {};
  Timer? _ticker;
  int _currentStep = 0;
  bool _loading = true;
  bool _finished = false;

  String get _sessionKey => 'bf_cooking_${widget.recipe.id}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = PageController();
    unawaited(WakelockPlus.enable().catchError((_) {}));
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _currentStep = (data['step'] as int? ?? 0).clamp(
          0,
          widget.recipe.steps.length - 1,
        );
        _completed.addAll(
          (data['completed'] as List<dynamic>? ?? const [])
              .whereType<int>()
              .where((i) => i < widget.recipe.steps.length),
        );
        final timers = data['timers'] as Map<String, dynamic>? ?? const {};
        for (final entry in timers.entries) {
          final index = int.tryParse(entry.key);
          final deadline = DateTime.tryParse(entry.value.toString());
          if (index != null &&
              deadline != null &&
              deadline.isAfter(DateTime.now())) {
            _deadlines[index] = deadline;
          }
        }
      } catch (_) {
        // A corrupt saved session must never prevent cooking.
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pages.hasClients) _pages.jumpToPage(_currentStep);
    });
    _ensureTicker();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'step': _currentStep,
        'completed': _completed.toList(),
        'timers': {
          for (final timer in _deadlines.entries)
            '${timer.key}': timer.value.toIso8601String(),
        },
      }),
    );
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  void _ensureTicker() {
    _removeExpiredTimers();
    if (_deadlines.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final expired = _deadlines.entries
          .where((entry) => !entry.value.isAfter(DateTime.now()))
          .map((entry) => entry.key)
          .toList();
      setState(_removeExpiredTimers);
      _ensureTicker();
      if (expired.isNotEmpty) {
        unawaited(SystemSound.play(SystemSoundType.alert).catchError((_) {}));
        unawaited(HapticFeedback.heavyImpact().catchError((_) {}));
        notify(
          context,
          expired.length == 1
              ? 'Terminó el temporizador del paso ${expired.first + 1}.'
              : 'Terminaron ${expired.length} temporizadores.',
        );
      }
    });
  }

  void _removeExpiredTimers() {
    final now = DateTime.now();
    _deadlines.removeWhere((_, deadline) => !deadline.isAfter(now));
  }

  int? _minutesForStep(int index) {
    final match = RegExp(
      r'(\d+)(?:\s*(?:-|–|a)\s*(\d+))?\s*(?:minutos|minuto|min)\b',
      caseSensitive: false,
    ).firstMatch(widget.recipe.steps[index]);
    return match == null
        ? null
        : int.tryParse(match.group(2) ?? match.group(1)!);
  }

  void _startTimer(int index, int minutes) {
    setState(
      () => _deadlines[index] = DateTime.now().add(Duration(minutes: minutes)),
    );
    _ensureTicker();
    unawaited(_save());
    notify(context, 'Temporizador del paso ${index + 1} iniciado.');
  }

  void _cancelTimer(int index) {
    setState(() => _deadlines.remove(index));
    _ensureTicker();
    unawaited(_save());
  }

  String _remaining(DateTime deadline) {
    final total = deadline
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 359999);
    return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _goTo(int step) async {
    if (step < 0 || step >= widget.recipe.steps.length) return;
    await _pages.animateToPage(
      step,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _completeAndContinue() {
    setState(() => _completed.add(_currentStep));
    unawaited(_save());
    if (_currentStep < widget.recipe.steps.length - 1) _goTo(_currentStep + 1);
  }

  Future<void> _finish() async {
    _finished = true;
    await _clear();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) unawaited(_save());
    if (state == AppLifecycleState.resumed && mounted) {
      setState(_removeExpiredTimers);
      _ensureTicker();
    }
  }

  @override
  void dispose() {
    if (!_finished) unawaited(_save());
    _ticker?.cancel();
    _pages.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(WakelockPlus.disable().catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.recipe.steps;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(_save());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Salir del modo cocina',
            onPressed: () async {
              await _save();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.close_rounded),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MODO COCINA', style: AppTypography.labelSmall),
              Text(
                '${_currentStep + 1} de ${steps.length}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Ver ingredientes',
              onPressed: _showIngredients,
              icon: const Icon(Icons.list_alt_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / steps.length,
                    minHeight: 4,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceHighlight,
                  ),
                  if (_deadlines.isNotEmpty)
                    SizedBox(
                      height: 66,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        scrollDirection: Axis.horizontal,
                        children: _deadlines.entries
                            .map(
                              (timer) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  avatar: const Icon(
                                    Icons.timer_outlined,
                                    size: 17,
                                  ),
                                  label: Text(
                                    'Paso ${timer.key + 1} · ${_remaining(timer.value)}',
                                  ),
                                  onPressed: () => _cancelTimer(timer.key),
                                  tooltip: 'Toca para cancelar',
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: steps.length,
                      onPageChanged: (index) {
                        setState(() => _currentStep = index);
                        unawaited(_save());
                      },
                      itemBuilder: (context, index) {
                        final minutes = _minutesForStep(index);
                        final done = _completed.contains(index);
                        final active = _deadlines[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(26, 32, 26, 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: done
                                            ? AppColors.primary
                                            : AppColors.primaryLight,
                                        child: Icon(
                                          done
                                              ? Icons.check_rounded
                                              : Icons.restaurant_rounded,
                                          color: done
                                              ? Colors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          widget.recipe.title,
                                          style: AppTypography.labelLarge,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 42),
                                  Text(
                                    'PASO ${index + 1}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    steps[index],
                                    style: AppTypography.displayMedium.copyWith(
                                      fontSize: 32,
                                      height: 1.28,
                                    ),
                                  ),
                                  if (minutes != null) ...[
                                    const SizedBox(height: 30),
                                    Surface(
                                      color: AppColors.primaryLight,
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              active == null
                                                  ? 'Este paso menciona $minutes min'
                                                  : 'En marcha · ${_remaining(active)}',
                                              style: AppTypography.titleMedium,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: active == null
                                                ? () => _startTimer(
                                                    index,
                                                    minutes,
                                                  )
                                                : () => _cancelTimer(index),
                                            child: Text(
                                              active == null
                                                  ? 'Iniciar'
                                                  : 'Cancelar',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 28),
                                  Text(
                                    'Desliza hacia los lados para cambiar de paso.',
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Paso anterior',
                  onPressed: _currentStep == 0
                      ? null
                      : () => _goTo(_currentStep - 1),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _currentStep == steps.length - 1
                        ? _finish
                        : _completeAndContinue,
                    icon: Icon(
                      _currentStep == steps.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _currentStep == steps.length - 1
                          ? 'Terminé de cocinar'
                          : _completed.contains(_currentStep)
                          ? 'Siguiente paso'
                          : 'Listo, siguiente',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showIngredients() => openSheet(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredientes a mano', style: AppTypography.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Cantidades para ${widget.recipe.servings} ${widget.recipe.servings == 1 ? 'porción' : 'porciones'}.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 18),
        ...widget.recipe.requiredIngredients.map(
          (name) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.primary,
            ),
            title: Text(name, style: AppTypography.labelLarge),
            subtitle: Text(
              widget.recipe.ingredientAmounts[name] ??
                  'Revisa la cantidad indicada en los pasos',
            ),
          ),
        ),
      ],
    ),
  );
}
