import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

void notify(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

Future<T?> openSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: child,
          ),
        ),
      ),
    );

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width > 700 ? 48 : 24,
      12,
      MediaQuery.sizeOf(context).width > 700 ? 48 : 24,
      28,
    ),
    children: children,
  );
}

class PageHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final Widget? trailing;
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(title, style: AppTypography.displayLarge)),
            ?trailing,
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTypography.bodyMedium),
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionHeading(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.titleMedium)),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  const Surface({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? AppColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(
        color: color == null ? AppColors.border : Colors.transparent,
      ),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class StatusPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool warm;
  const StatusPill(this.text, {super.key, this.icon, this.warm = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: warm ? AppColors.accentLight : AppColors.primaryLight,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 14,
            color: warm ? AppColors.accent : AppColors.primary,
          ),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: warm ? AppColors.accent : AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, message, action;
  final VoidCallback onTap;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: AppTypography.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: onTap, child: Text(action)),
        const SizedBox(height: 8),
      ],
    ),
  );
}

class Reveal extends StatelessWidget {
  final Widget child;
  const Reveal({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 34});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    child: Icon(Icons.spa_rounded, size: size * .63, color: AppColors.lime),
  );
}

/// Animates a tab entering while keeping every tab's scroll and form state.
class TabEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  const TabEntrance({super.key, required this.index, required this.child});
  @override
  State<TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<TabEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  @override
  void didUpdateWidget(TabEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? widget.child
      : FadeTransition(
          opacity: Tween<double>(begin: .55, end: 1).animate(_curve),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .015),
              end: Offset.zero,
            ).animate(_curve),
            child: widget.child,
          ),
        );
}
