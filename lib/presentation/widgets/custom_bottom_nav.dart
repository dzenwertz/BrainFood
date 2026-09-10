import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex, shoppingBadgeCount;
  final ValueChanged<int> onTap;
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.shoppingBadgeCount = 0,
  });
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: (index) {
      HapticFeedback.selectionClick();
      onTap(index);
    },
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: AppColors.primaryLight,
    elevation: 0,
    height: 74,
    animationDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    destinations: [
      const NavigationDestination(
        icon: Icon(Icons.wb_sunny_outlined),
        selectedIcon: Icon(Icons.wb_sunny_rounded),
        label: 'Hoy',
      ),
      const NavigationDestination(
        icon: Icon(Icons.kitchen_outlined),
        selectedIcon: Icon(Icons.kitchen_rounded),
        label: 'Despensa',
      ),
      const NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_rounded),
        label: 'Recetas',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Semana',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: shoppingBadgeCount > 0,
          label: Text('$shoppingBadgeCount'),
          child: const Icon(Icons.shopping_bag_outlined),
        ),
        selectedIcon: const Icon(Icons.shopping_bag_rounded),
        label: 'Compras',
      ),
    ],
  );
}
