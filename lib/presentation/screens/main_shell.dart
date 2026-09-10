import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../state/shopping_state.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/design_system.dart';
import 'home_screen.dart';
import 'pantry_screen.dart';
import 'recipes_screen.dart';
import 'weekly_planner_screen.dart';
import 'shopping_screen.dart';
import 'settings_screen.dart';

final navigationProvider = NotifierProvider<NavigationNotifier, int>(
  NavigationNotifier.new,
);

class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void select(int index) => state = index;
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(),
            const SizedBox(width: 9),
            Text(
              'brainfood',
              style: AppTypography.titleLarge.copyWith(letterSpacing: -1),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Preferencias',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: TabEntrance(
              index: index,
              child: IndexedStack(
                index: index,
                children: [
                  TickerMode(enabled: index == 0, child: const HomeScreen()),
                  TickerMode(enabled: index == 1, child: const PantryScreen()),
                  TickerMode(enabled: index == 2, child: const RecipesScreen()),
                  TickerMode(
                    enabled: index == 3,
                    child: const WeeklyPlannerScreen(),
                  ),
                  TickerMode(
                    enabled: index == 4,
                    child: const ShoppingScreen(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: CustomBottomNav(
            currentIndex: index,
            shoppingBadgeCount: ref.watch(shoppingProvider).pendingCount,
            onTap: ref.read(navigationProvider.notifier).select,
          ),
        ),
      ),
    );
  }
}
