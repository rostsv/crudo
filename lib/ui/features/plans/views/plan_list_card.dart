import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';
import '../view_models/plan_draft.dart';

/// One row in the plans list. Displays name, derived subtitle, weekday chips,
/// a "Today" badge, and an "Inactive" tag for paused plans.
class PlanListCard extends StatelessWidget {
  const PlanListCard({required this.row, required this.onTap, super.key});

  final PlanRowVm row;
  final VoidCallback onTap;

  // Weekday labels are defined in _WeekdayStrip._labels

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final isInactive = !row.active;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: dim.Durations.fast,
          padding: const EdgeInsets.all(dim.Spacing.md),
          decoration: BoxDecoration(
            color: isInactive ? colors.surfaceDim : colors.surfaceLowest,
            borderRadius: dim.Radii.all(dim.Radii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.name,
                      style: CrudoText.title.copyWith(
                        color: isInactive
                            ? colors.onSurfaceMut
                            : colors.onSurface,
                      ),
                    ),
                  ),
                  if (row.isToday) ...[
                    const SizedBox(width: dim.Spacing.sm),
                    _Badge(
                      label: 'Today',
                      background: colors.primaryContainer,
                      foreground: colors.primary,
                    ),
                  ],
                  if (isInactive) ...[
                    const SizedBox(width: dim.Spacing.sm),
                    _Badge(
                      label: 'Inactive',
                      background: colors.surfaceHigh,
                      foreground: colors.onSurfaceMut,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: dim.Spacing.xs),
              Text(
                _subtitle(),
                style: CrudoText.body.copyWith(color: colors.onSurfaceVar),
              ),
              const SizedBox(height: dim.Spacing.sm),
              _WeekdayStrip(row: row),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final meals = row.mealCount == 1 ? '1 meal' : '${row.mealCount} meals';
    return '${row.goal.name.toUpperCase()} · ${row.kcal} KCAL · $meals';
  }
}

class _WeekdayStrip extends StatelessWidget {
  const _WeekdayStrip({required this.row});

  final PlanRowVm row;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final isInactive = !row.active;

    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: dim.Spacing.xs),
          _DayCell(
            label: _labels[i],
            filled: row.days.contains(i),
            isInactive: isInactive,
          ),
        ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.filled,
    required this.isInactive,
  });

  final String label;
  final bool filled;
  final bool isInactive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    final bgColor = filled
        ? (isInactive ? colors.surfaceHigh : colors.primary)
        : colors.surfaceHigh;
    final fgColor = filled
        ? (isInactive ? colors.onSurfaceMut : colors.surfaceLowest)
        : colors.onSurfaceMut;

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: dim.Radii.all(dim.Radii.full),
      ),
      child: Text(
        label,
        style: CrudoText.labelMd.copyWith(color: fgColor, fontSize: 10),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: dim.Spacing.sm,
        vertical: dim.Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: dim.Radii.all(dim.Radii.full),
      ),
      child: Text(
        label,
        style: CrudoText.labelMd.copyWith(color: foreground, fontSize: 10),
      ),
    );
  }
}
