import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';

/// Mon–Sun week strip (current week only — far navigation is S13's
/// calendar). Pills: 44×60 per app.css .day-pill; selected = surfaceHighest
/// tonal fill; today (when unselected) marks its number in primary.
class DayStrip extends StatelessWidget {
  const DayStrip({
    required this.dates,
    required this.selected,
    required this.today,
    required this.onSelect,
    super.key,
  });

  /// Exactly 7 UTC day-labels, Monday first.
  final List<DateTime> dates;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  static const _pillHeight = 60.0; // component size, 4px grid (app.css)
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Row(
      children: [
        for (final (i, date) in dates.indexed)
          Expanded(
            child: _DayPill(
              key: ValueKey(
                'day-pill-${date.toIso8601String().substring(0, 10)}',
              ),
              number: date.day,
              letter: _letters[i],
              selected: date == selected,
              isToday: date == today,
              colors: colors,
              onTap: () => onSelect(date),
            ),
          ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.number,
    required this.letter,
    required this.selected,
    required this.isToday,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final int number;
  final String letter;
  final bool selected;
  final bool isToday;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final numColor = selected
        ? colors.onSurface
        : isToday
        ? colors.primary
        : colors.onSurfaceMut;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: dim.Durations.base,
          height: DayStrip._pillHeight,
          decoration: BoxDecoration(
            color: selected ? colors.surfaceHighest : null,
            borderRadius: dim.Radii.all(dim.Radii.full),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$number',
                style: CrudoText.bodyLg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: numColor,
                ),
              ),
              Text(
                letter,
                style: CrudoText.label.copyWith(
                  color: numColor.withValues(alpha: dim.Opacities.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
