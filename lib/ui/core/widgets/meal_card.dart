import 'package:flutter/material.dart';

import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/macros.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// A meal card: vertical status bar, meta row (time · meal type + status
/// label), name, ingredient preview (first 3 + "+N more"), macros row
/// (kcal bold, P/C/F muted), trailing 36px status circle. Status colors per
/// design system: done=teal, partial=gold (split glyph, never "½"),
/// upcoming=muted, skipped=red. No dividers — cards separate by spacing.
class MealCard extends StatelessWidget {
  const MealCard({
    required this.title,
    required this.timeLabel,
    required this.mealTypeLabel,
    required this.macros,
    required this.status,
    this.ingredientNames = const <String>[],
    this.snoozedTimeLabel,
    this.onTap,
    super.key,
  });

  final String title;
  final String timeLabel;

  /// When the meal is snoozed: the new local time. Renders [timeLabel]
  /// struck-through with this to its right.
  final String? snoozedTimeLabel;

  /// Meal-type tag shown next to the time, e.g. "Breakfast".
  final String mealTypeLabel;

  /// Derived meal totals; the card shows kcal + P/C/F grams rounded.
  final Macros macros;

  /// Full ingredient name list; the card previews the first
  /// [_previewCount] and collapses the rest into "+N more".
  final List<String> ingredientNames;
  final MealStatus status;
  final VoidCallback? onTap;

  static const _previewCount = 3;
  static const _barHeight = 44.0; // component size, 4px grid

  /// "Eggs · Yogurt · Oats · +1 more" — first 3 names, rest collapsed.
  String get ingredientPreview {
    final shown = ingredientNames.take(_previewCount).join(' · ');
    final more = ingredientNames.length - _previewCount;
    return more > 0 ? '$shown · +$more more' : shown;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final statusColor = _statusLabelColor(colors);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: Radii.all(Radii.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Container(
                width: Spacing.xs,
                height: _barHeight,
                decoration: BoxDecoration(
                  color: _barColor(colors),
                  borderRadius: Radii.all(Radii.full),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: CrudoText.label.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                            children: [
                              TextSpan(
                                text: timeLabel,
                                style: snoozedTimeLabel == null
                                    ? null
                                    : const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                      ),
                              ),
                              if (snoozedTimeLabel != null)
                                TextSpan(text: '  $snoozedTimeLabel'),
                              TextSpan(text: ' · $mealTypeLabel'),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        status.name.toUpperCase(),
                        style: CrudoText.label.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    title,
                    style: CrudoText.title.copyWith(
                      color: status == MealStatus.skipped
                          ? colors.onSurfaceMut
                          : colors.onSurface,
                    ),
                  ),
                  if (ingredientNames.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      ingredientPreview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      Text(
                        '${macros.kcal.round()} kcal',
                        style: CrudoText.body.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Text(
                        'P ${macros.protein.round()}g'
                        '  C ${macros.carbs.round()}g'
                        '  F ${macros.fats.round()}g',
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),
            Center(
              child: _StatusCircle(
                status: status,
                key: ValueKey('meal-status-${status.name}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusLabelColor(CrudoColors colors) => switch (status) {
    MealStatus.done => colors.primary,
    MealStatus.partial => colors.goldDeep,
    MealStatus.upcoming => colors.onSurfaceMut,
    MealStatus.skipped => colors.error,
  };

  Color _barColor(CrudoColors colors) => switch (status) {
    MealStatus.done => colors.primarySoft,
    MealStatus.partial => colors.gold,
    MealStatus.upcoming => colors.primary.withValues(alpha: 0.18),
    MealStatus.skipped => colors.error.withValues(alpha: 0.4),
  };
}

/// 36px trailing status circle: done=filled teal check, partial=gold
/// split-circle (never "½"), upcoming=outlined clock, skipped=soft-red X.
class _StatusCircle extends StatelessWidget {
  const _StatusCircle({required this.status, super.key});

  final MealStatus status;

  static const _size = 36.0; // component size, 4px grid

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    // Upcoming gets a painted ring (no-line rule: never a Border).
    final (background, ring, child) = switch (status) {
      MealStatus.done => (
        colors.primary,
        null,
        Icon(Icons.check, size: IconSizes.md, color: colors.surfaceLowest),
      ),
      MealStatus.partial => (
        colors.gold,
        null,
        CustomPaint(
          size: const Size.square(IconSizes.md),
          painter: _SplitCirclePainter(colors.surfaceLowest),
        ),
      ),
      MealStatus.upcoming => (
        null,
        colors.onSurfaceMut.withValues(alpha: 0.3),
        Icon(Icons.schedule, size: IconSizes.md, color: colors.onSurfaceMut),
      ),
      MealStatus.skipped => (
        colors.errorSoft,
        null,
        Icon(Icons.close, size: IconSizes.md, color: colors.error),
      ),
    };
    return CustomPaint(
      painter: ring == null ? null : _RingPainter(ring),
      child: Container(
        width: _size,
        height: _size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

/// Thin stroked circle for the upcoming state (painted, never a Border).
class _RingPainter extends CustomPainter {
  const _RingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide / 2 - 1,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.color != color;
}

/// Half-filled circle: the partial-state glyph (never a "½" character).
class _SplitCirclePainter extends CustomPainter {
  const _SplitCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, stroke);
    final fill = Paint()..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90°: fill the left half
      -3.14159,
      true,
      fill,
    );
  }

  @override
  bool shouldRepaint(_SplitCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
