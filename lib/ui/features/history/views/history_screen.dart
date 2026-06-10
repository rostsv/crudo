import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crudo/domain/streak/streak.dart';
import 'package:crudo/ui/features/history/view_models/history_providers.dart';
import 'package:crudo/ui/features/history/views/history_ui.dart';
import 'package:crudo/ui/features/today/views/formatting.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import 'calendar_sheet.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _AppBar(colors: colors),
          const SizedBox(height: Spacing.lg),
          _StreakHero(colors: colors),
          const SizedBox(height: Spacing.lg),
          _StatGrid(colors: colors),
          const SizedBox(height: Spacing.lg),
          _RecentList(colors: colors),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.colors});

  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TRACKING', style: CrudoText.label),
              const SizedBox(height: Spacing.xs),
              Text('History', style: CrudoText.headline),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('history-calendar-btn'),
          icon: Icon(
            Icons.calendar_today_outlined,
            color: colors.onSurface,
            size: IconSizes.lg,
          ),
          onPressed: () => showCalendarSheet(context),
        ),
      ],
    );
  }
}

class _StreakHero extends ConsumerWidget {
  const _StreakHero({required this.colors});

  final CrudoColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final weekAsync = ref.watch(weeklyAdherenceProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: Radii.all(Radii.xl),
        boxShadow: Shadows.cloud,
      ),
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          streakAsync.when(
            loading: () => const SizedBox(height: Spacing.xl),
            error: (e, s) => Text('Error', style: CrudoText.body),
            data: (streak) => _StreakHeader(streak: streak, colors: colors),
          ),
          const SizedBox(height: Spacing.lg),
          weekAsync.when(
            loading: () => const SizedBox(height: 80),
            error: (e, s) => Text('Error', style: CrudoText.body),
            data: (week) => _WeekStrip(week: week, colors: colors),
          ),
        ],
      ),
    );
  }
}

class _StreakHeader extends StatelessWidget {
  const _StreakHeader({required this.streak, required this.colors});

  final Streak streak;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${streak.current}', style: CrudoText.stat),
              const SizedBox(height: Spacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: Radii.all(Radii.full),
                ),
                child: Text(
                  'Personal best: ${streak.personalBest}',
                  style: CrudoText.labelMd.copyWith(
                    color: colors.surfaceLowest,
                  ),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.local_fire_department,
          size: IconSizes.xl,
          color: colors.gold,
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.week, required this.colors});

  final List<WeekCell> week;
  final CrudoColors colors;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('week-strip'),
      child: Row(
        children: [
          for (var i = 0; i < week.length; i++)
            Expanded(
              child: _WeekCell(
                cell: week[i],
                label: _labels[i],
                colors: colors,
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekCell extends StatelessWidget {
  const _WeekCell({
    required this.cell,
    required this.label,
    required this.colors,
  });

  final WeekCell cell;
  final String label;
  final CrudoColors colors;

  static const _trackHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    final fillColor = cell.state != null
        ? dayStateColor(cell.state!, colors)
        : Colors.transparent;
    final fillHeight = cell.state != null
        ? (cell.adherence * _trackHeight).clamp(0.0, _trackHeight)
        : 0.0;

    Widget fill;
    if (cell.kind == DayCellKind.today) {
      fill = _HatchedFill(height: fillHeight, color: fillColor, colors: colors);
    } else {
      fill = Container(
        key: const ValueKey('week-bar'),
        height: fillHeight,
        color: fillColor,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      child: Column(
        children: [
          Container(
            height: _trackHeight,
            decoration: BoxDecoration(
              color: colors.surfaceLow,
              borderRadius: Radii.all(Radii.sm),
            ),
            child: Stack(
              children: [Positioned(left: 0, right: 0, bottom: 0, child: fill)],
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
          ),
        ],
      ),
    );
  }
}

/// Hatched fill for today's cell: stripes on top of the adherence color.
class _HatchedFill extends StatelessWidget {
  const _HatchedFill({
    required this.height,
    required this.color,
    required this.colors,
  });

  final double height;
  final Color color;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week-bar'),
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: Radii.all(Radii.sm),
      ),
      child: ClipRRect(
        borderRadius: Radii.all(Radii.sm),
        child: CustomPaint(
          size: Size.infinite,
          painter: _StripePainter(
            stripeColor: colors.primarySoft,
            stripeWidth: 4,
            gap: 4,
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter({
    required this.stripeColor,
    required this.stripeWidth,
    required this.gap,
  });

  final Color stripeColor;
  final double stripeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = stripeWidth;

    final spacing = stripeWidth + gap;
    // Diagonal stripes from top-left to bottom-right
    for (var i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatGrid extends ConsumerWidget {
  const _StatGrid({required this.colors});

  final CrudoColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(historyStatsProvider);

    return statsAsync.when(
      loading: () => const SizedBox(height: Spacing.xl * 4),
      error: (e, s) => Text('Error', style: CrudoText.body),
      data: (stats) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Adherence',
                  value: '${stats.adherencePct}%',
                  color: colors.success,
                  colors: colors,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _StatCard(
                  label: 'Meals done',
                  value: '${stats.mealsDone}',
                  color: colors.onSurface,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Avg kcal',
                  value: '${stats.avgKcal}',
                  color: colors.onSurface,
                  colors: colors,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _StatCard(
                  label: 'Skipped',
                  value: '${stats.skipped}',
                  color: colors.error,
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.colors,
  });

  final String label;
  final String value;
  final Color color;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: Radii.all(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CrudoText.labelMd.copyWith(color: colors.onSurfaceMut),
          ),
          const SizedBox(height: Spacing.xs),
          Text(value, style: CrudoText.displaySm.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList({required this.colors});

  final CrudoColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentDaysProvider);

    return recentAsync.when(
      loading: () => const SizedBox(height: Spacing.xl * 5),
      error: (e, s) => Text('Error', style: CrudoText.body),
      data: (days) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 5 days', style: CrudoText.headlineSm),
          const SizedBox(height: Spacing.md),
          for (final day in days) _RecentDayRow(day: day, colors: colors),
        ],
      ),
    );
  }
}

class _RecentDayRow extends StatelessWidget {
  const _RecentDayRow({required this.day, required this.colors});

  final RecentDay day;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    final pct = (day.adherence * 100).round();
    final barColor = dayStateColor(day.state, colors);

    return Padding(
      key: const ValueKey('recent-day-row'),
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateHeadline(day.date),
                  style: CrudoText.body.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${day.done}/${day.total} meals',
                  style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: AdherenceBar(value: day.adherence, color: barColor),
          ),
          const SizedBox(width: Spacing.md),
          SizedBox(
            width: 48,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: CrudoText.bodyLg.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
