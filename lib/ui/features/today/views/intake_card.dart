import 'package:flutter/material.dart';

import '../../../../domain/shared/macros.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';
import '../../../core/widgets/macro_ring.dart';

/// Hero intake summary: consumed/planned kcal + progress ring + the three
/// macro bars (Protein=primary, Carbs=gold, Fats=bronze). Floating card —
/// the one Cloud Shadow on this screen.
class IntakeCard extends StatelessWidget {
  const IntakeCard({required this.consumed, required this.planned, super.key});

  final Macros consumed;
  final Macros planned;

  static const _ringSize = 72.0; // component size, 4px grid
  static const _settleCurve = Curves.easeOutCubic;

  double _share(double v, double t) => t <= 0 ? 0 : v / t;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      padding: const EdgeInsets.all(dim.Spacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: dim.Radii.all(dim.Radii.xl),
        boxShadow: dim.Shadows.cloud,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("TODAY'S INTAKE", style: CrudoText.label),
                    const SizedBox(height: dim.Spacing.sm),
                    // scaleDown guards narrow screens / 5-digit kcal —
                    // at normal widths it renders 1:1.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(end: consumed.kcal),
                            duration: dim.Durations.slow,
                            curve: _settleCurve,
                            builder: (context, kcal, child) =>
                                Text('${kcal.round()}', style: CrudoText.stat),
                          ),
                          const SizedBox(width: dim.Spacing.xs),
                          Text(
                            '/${planned.kcal.round()} kcal',
                            style: CrudoText.bodyLg.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(end: _share(consumed.kcal, planned.kcal)),
                duration: dim.Durations.slow,
                curve: _settleCurve,
                builder: (_, v, child) =>
                    MacroRing(value: v, size: _ringSize, center: child),
                child: Icon(
                  Icons.local_fire_department_outlined,
                  size: dim.IconSizes.lg,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: dim.Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _MacroBar(
                  label: 'Protein',
                  value: consumed.protein,
                  total: planned.protein,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: dim.Spacing.md),
              Expanded(
                child: _MacroBar(
                  label: 'Carbs',
                  value: consumed.carbs,
                  total: planned.carbs,
                  color: colors.gold,
                ),
              ),
              const SizedBox(width: dim.Spacing.md),
              Expanded(
                child: _MacroBar(
                  label: 'Fats',
                  value: consumed.fats,
                  total: planned.fats,
                  color: colors.bronze,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final double value;
  final double total;
  final Color color;

  static const _barHeight = 4.0; // prototype 3px → snapped to grid

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: dim.Durations.slow,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final share = total <= 0 ? 0.0 : (v / total).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CrudoText.labelMd.copyWith(
                      color: colors.onSurfaceVar,
                    ),
                  ),
                ),
                const SizedBox(width: dim.Spacing.xs),
                // The value scales down a hair when label+value exceed the
                // bar column ('Protein' + '82/140g' is ~2px over at 390px).
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${v.round()}/${total.round()}g',
                      style: CrudoText.labelMd.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: dim.Spacing.xs),
            ClipRRect(
              borderRadius: dim.Radii.all(dim.Radii.full),
              child: SizedBox(
                height: _barHeight,
                child: LinearProgressIndicator(
                  value: share,
                  backgroundColor: colors.outline,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
