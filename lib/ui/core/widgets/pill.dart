import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;
import '../themes/typography.dart';

/// Compact selectable chip (weekdays, tags, filters).
class Pill extends StatelessWidget {
  const Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: dim.Durations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: dim.Spacing.md,
            vertical: dim.Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceHigh,
            borderRadius: dim.Radii.all(dim.Radii.full),
          ),
          child: Text(
            label,
            style: CrudoText.labelMd.copyWith(
              color: selected ? colors.surfaceLowest : colors.onSurfaceVar,
            ),
          ),
        ),
      ),
    );
  }
}
