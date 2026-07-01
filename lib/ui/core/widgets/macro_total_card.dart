import 'package:flutter/material.dart';

import 'package:crudo/domain/shared/macros.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// A static kcal-total + P/C/F breakdown hero card. Two tones:
/// - [gradient] == false → tonal `surfaceLow`, macro values accent-colored.
/// - [gradient] == true  → `primary → primarySoft` gradient, white text.
///
/// Shared by the meal-detail TOTAL INTAKE card and the plan DAILY TARGET hero.
/// [footer] is an optional slot below the macros (meal detail passes its tag
/// pills; the plan passes nothing).
class MacroTotalCard extends StatelessWidget {
  const MacroTotalCard({
    required this.macros,
    required this.label,
    this.gradient = false,
    this.footer,
    this.footerBelow,
    super.key,
  });

  final Macros macros;
  final String label;
  final bool gradient;

  /// Slot inside the left column, under the kcal hero (meal-detail tags).
  final Widget? footer;

  /// Full-width slot below the kcal+macros row (plan editor weekday strip).
  final Widget? footerBelow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final onCard = gradient ? colors.surfaceLowest : colors.onSurface;
    final mutedOnCard = gradient
        ? colors.surfaceLowest.withValues(alpha: 0.7)
        : colors.onSurfaceMut;
    // The macro tile is always white with tonal text — identical on both the
    // tonal meal card and the gradient plan hero.
    final tileColor = colors.surfaceLowest;

    final rows = <(String, double, Color)>[
      ('Protein', macros.protein, colors.proteinColor),
      ('Carbs', macros.carbs, colors.carbsColor),
      ('Fats', macros.fats, colors.fatsColor),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: gradient ? null : colors.surfaceLow,
        gradient: gradient
            ? const LinearGradient(
                colors: [CrudoPalette.primary, CrudoPalette.primarySoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: Radii.all(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            // No left footer (plan target) → center the kcal hero against the
            // taller macro tile. With a footer (meal tags) keep top-aligned.
            crossAxisAlignment: footer == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              // Left: label + kcal hero + footer (tags) filling the space below.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: CrudoText.label.copyWith(color: mutedOnCard),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${macros.kcal.round()}',
                          key: const ValueKey('detail-kcal'),
                          style: CrudoText.display.copyWith(color: onCard),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          'kcal',
                          style: CrudoText.body.copyWith(color: mutedOnCard),
                        ),
                      ],
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: Spacing.md),
                      footer!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              // Right: one tile with a color-barred strip per macro.
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: Radii.all(Radii.md),
                  ),
                  child: Column(
                    children: [
                      for (final (i, (name, value, accent))
                          in rows.indexed) ...[
                        if (i > 0) const SizedBox(height: Spacing.sm),
                        _MacroStrip(
                          label: name,
                          grams: value,
                          barColor: accent,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (footerBelow != null) ...[
            const SizedBox(height: Spacing.lg),
            footerBelow!,
          ],
        ],
      ),
    );
  }
}

/// One macro strip inside the (always-white) tile: `Label — Ng` on a line,
/// a full-width color bar under. Text is tonal regardless of card variant.
class _MacroStrip extends StatelessWidget {
  const _MacroStrip({
    required this.label,
    required this.grams,
    required this.barColor,
  });

  final String label;
  final double grams;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: CrudoText.labelMd.copyWith(color: colors.onSurfaceMut),
            ),
            const Spacer(),
            Text(
              '${grams.round()}g',
              style: CrudoText.labelMd.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        // Full-width color bar (painted stroke, allowed off-grid).
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: Radii.all(Radii.full),
          ),
        ),
      ],
    );
  }
}
