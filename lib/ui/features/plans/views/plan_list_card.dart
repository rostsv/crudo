import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';
import '../../../core/widgets/macro_chip.dart';
import '../view_models/plan_draft.dart';

/// One row in the plans list. An eyebrow (`GOAL · KCAL · ACTIVE`) sits above
/// the name; below it a meta line (meal count + kcal + P/C/F macro dots) and a
/// full-width weekday strip. A trailing chevron marks the card as navigable.
class PlanListCard extends StatelessWidget {
  const PlanListCard({required this.row, required this.onTap, super.key});

  final PlanRowVm row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final isInactive = !row.active;
    final onSurface = isInactive ? colors.onSurfaceMut : colors.onSurface;

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
              // Eyebrow + trailing chevron.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: CrudoText.label.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                        children: [
                          TextSpan(
                            text: row.active ? 'ACTIVE' : 'PAUSED',
                            style: TextStyle(
                              color: row.active
                                  ? colors.primary
                                  : colors.onSurfaceMut,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' · ${_mealsLabel().toUpperCase()}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: dim.Spacing.sm),
                  Icon(
                    Icons.chevron_right,
                    size: dim.IconSizes.md,
                    color: colors.onSurfaceVar,
                  ),
                ],
              ),
              const SizedBox(height: dim.Spacing.xs),
              Text(row.name, style: CrudoText.title.copyWith(color: onSurface)),
              const SizedBox(height: dim.Spacing.xs),
              // Meta line: kcal · P/C/F dots.
              Wrap(
                spacing: dim.Spacing.sm,
                runSpacing: dim.Spacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${row.kcal} kcal',
                    style: CrudoText.labelMd.copyWith(
                      color: colors.onSurfaceVar,
                    ),
                  ),
                  MacroChip(
                    grams: row.protein.toDouble(),
                    color: colors.proteinColor,
                  ),
                  MacroChip(
                    grams: row.carbs.toDouble(),
                    color: colors.carbsColor,
                  ),
                  MacroChip(
                    grams: row.fats.toDouble(),
                    color: colors.fatsColor,
                  ),
                ],
              ),
              const SizedBox(height: dim.Spacing.sm),
              _WeekdayStrip(row: row),
            ],
          ),
        ),
      ),
    );
  }

  String _mealsLabel() =>
      row.mealCount == 1 ? '1 meal' : '${row.mealCount} meals';
}

/// Full-width weekday strip: seven equal cells sharing the content line.
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
          Expanded(
            child: _DayCell(
              label: _labels[i],
              filled: row.days.contains(i),
              isInactive: isInactive,
            ),
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

    return SizedBox(
      height: 32, // chip height (width > height via Expanded), 4px grid
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: dim.Radii.all(dim.Radii.sm),
        ),
        child: Text(label, style: CrudoText.labelMd.copyWith(color: fgColor)),
      ),
    );
  }
}
