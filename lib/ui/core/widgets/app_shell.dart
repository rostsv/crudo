import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crudo/config/app_config.dart';
import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Persistent app frame: the active branch + the custom bottom nav.
/// No-line rule: the bar separates from the body by surface tone, not border.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (label: 'Today', icon: Icons.restaurant_outlined, active: Icons.restaurant),
    (label: 'Plans', icon: Icons.event_note_outlined, active: Icons.event_note),
    (label: 'History', icon: Icons.bar_chart_outlined, active: Icons.bar_chart),
    (label: 'Profile', icon: Icons.person_outline, active: Icons.person),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final isDev = ref.watch(appConfigProvider).isDev;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          navigationShell,
          if (isDev)
            Positioned(
              top: MediaQuery.of(context).padding.top + Spacing.sm,
              right: Spacing.md,
              child: Text(
                'Crudo Dev',
                style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
              ),
            ),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: colors.surfaceLowest,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Row(
              children: [
                for (final (index, item) in _items.indexed)
                  Expanded(
                    child: _NavItem(
                      key: ValueKey('nav-${item.label}'),
                      label: item.label,
                      icon: navigationShell.currentIndex == index
                          ? item.active
                          : item.icon,
                      selected: navigationShell.currentIndex == index,
                      onTap: () => navigationShell.goBranch(
                        index,
                        initialLocation: index == navigationShell.currentIndex,
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
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final color = selected ? colors.primary : colors.onSurfaceMut;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.all(Radii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: Spacing.xs),
              Text(label, style: CrudoText.label.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
