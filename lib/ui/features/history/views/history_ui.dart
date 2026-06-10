import 'package:flutter/material.dart';

import 'package:crudo/domain/shared/enums.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';

/// Fill color for a DayState. green → success (teal), yellow → gold,
/// red → error. The single source of day-color truth for S13.
Color dayStateColor(DayState state, CrudoColors colors) => switch (state) {
  DayState.green => colors.success,
  DayState.yellow => colors.gold,
  DayState.red => colors.error,
};

/// Thin rounded progress bar. [value] 0..1, [color] from dayStateColor.
/// Track = surfaceHigh. Height on 4px grid (default 8).
class AdherenceBar extends StatelessWidget {
  const AdherenceBar({
    required this.value,
    required this.color,
    this.height = Spacing.sm,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>();
    final trackColor = colors?.surfaceHigh ?? CrudoColors.light.surfaceHigh;
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: Radii.all(Radii.full),
      child: Container(
        key: const ValueKey('adherence-bar-track'),
        height: height,
        color: trackColor,
        child: FractionallySizedBox(
          widthFactor: clamped,
          child: Container(color: color),
        ),
      ),
    );
  }
}
