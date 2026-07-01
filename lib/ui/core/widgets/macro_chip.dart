import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// A colored dot + rounded-grams label — the shared macro glyph used on the
/// meal card, ingredient rows, and intake card.
class MacroChip extends StatelessWidget {
  const MacroChip({required this.grams, required this.color, super.key});

  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: Spacing.xs,
          height: Spacing.xs,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          '${grams.round()}g',
          style: CrudoText.labelMd.copyWith(color: colors.onSurfaceMut),
        ),
      ],
    );
  }
}
