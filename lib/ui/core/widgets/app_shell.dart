import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crudo/config/app_config.dart';
import 'package:crudo/ui/features/history/views/milestone_sheet.dart';
import 'package:crudo/ui/features/today/view_models/notification_scheduler_controller.dart';
import 'package:crudo/ui/features/today/view_models/streak_at_risk_provider.dart';
import 'package:crudo/ui/features/today/view_models/streak_catchup_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/streak_risk_sheet.dart';
import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Persistent app frame: the active branch + the custom bottom nav.
/// No-line rule: the bar separates from the body by surface tone, not border.
/// Mounts the streakCatchUpProvider listener to celebrate milestones.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Context captured below the Navigator (inside Builder) for dialog show.
  BuildContext? _navigatorContext;

  /// Day label the risk sheet was last shown for. streakAtRiskProvider re-emits
  /// the same StreakRisk on every today-Day mutation, so without this guard the
  /// sheet would re-pop each time a meal is marked. Show at most once per day.
  DateTime? _riskShownForDay;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref; // ConsumerState ref property
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final isDev = ref.watch(appConfigProvider).isDev;

    // Activate the notification scheduler and action router so they run while
    // the shell is mounted. These are auto-dispose and need a watch/listen
    // to stay alive.
    ref.watch(notificationSchedulerProvider);
    ref.watch(notificationActionRouterProvider);

    // Listen for streak milestones. The listener activates the auto-dispose
    // provider, which stays alive while this widget is mounted. On each frame
    // where milestones are present (and non-empty), we show the celebration
    // dialog(s) in order, one per crossing.
    ref.listen<AsyncValue<List<int>>>(streakCatchUpProvider, (prev, next) {
      final milestones = next.asData?.value;
      if (milestones == null || milestones.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ctx = _navigatorContext;
        if (ctx == null || !ctx.mounted) return;
        for (final m in milestones) {
          await showMilestoneSheet(ctx, m);
        }
      });
    });

    // Listen for streak-at-risk banners. The provider re-emits the same risk on
    // every today-Day mutation, so guard on the day label to show at most once
    // per calendar day (not once per rebuild).
    ref.listen<AsyncValue<StreakRisk?>>(streakAtRiskProvider, (prev, next) {
      final risk = next.asData?.value;
      if (risk == null) return;
      final today = ref.read(todayProvider);
      if (_riskShownForDay == today) return; // already shown today
      _riskShownForDay = today;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _navigatorContext;
        if (ctx == null || !ctx.mounted) return;
        showStreakRiskSheet(ctx, risk);
      });
    });

    // Wrap the scaffold body in a Builder so the captured context sits under
    // the Navigator (valid for showDialog) and outlives the build scope.
    return Builder(
      builder: (navigatorContext) {
        _navigatorContext = navigatorContext;
        return Scaffold(
          backgroundColor: colors.surface,
          body: Stack(
            children: [
              widget.navigationShell,
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
                          icon: widget.navigationShell.currentIndex == index
                              ? item.active
                              : item.icon,
                          selected:
                              widget.navigationShell.currentIndex == index,
                          onTap: () => widget.navigationShell.goBranch(
                            index,
                            initialLocation:
                                index == widget.navigationShell.currentIndex,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

const _items = [
  (label: 'Today', icon: Icons.restaurant_outlined, active: Icons.restaurant),
  (label: 'Plans', icon: Icons.event_note_outlined, active: Icons.event_note),
  (label: 'History', icon: Icons.bar_chart_outlined, active: Icons.bar_chart),
  (label: 'Profile', icon: Icons.person_outline, active: Icons.person),
];

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
