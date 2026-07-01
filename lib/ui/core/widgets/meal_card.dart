import 'package:flutter/material.dart';

import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/macros.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// A meal card: vertical status bar, meta row (time · meal type), name,
/// fit-aware ingredient preview, macros row (kcal + colored P/C/F dots),
/// trailing 36px status circle. Status colors per design system:
/// done=teal, partial=gold (split glyph, never "½"), upcoming=muted,
/// skipped=red. No dividers — cards separate by spacing.
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
    this.onStatusTap,
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

  /// Full ingredient name list; the card previews as many names as fit on
  /// one line and collapses the rest into "+N more".
  final List<String> ingredientNames;
  final MealStatus status;
  final VoidCallback? onTap;

  /// One-tap complete/undo on the status circle. Null = circle is inert
  /// (past/future days). The card stays dumb: the caller decides what a
  /// tap means for the current status.
  final VoidCallback? onStatusTap;

  static const _barHeight = 44.0; // component size, 4px grid
  static const _statusTapTarget = 44.0; // min touch target, 4px grid (§5)

  /// Largest [k] such that [names][0..k) joined by ` · ` (plus
  /// ` · +N more` when [k] < [names].length) fits within [maxWidth] at
  /// [style]. Always returns at least 1 when [names] is non-empty.
  ///
  /// Public so it can be unit-tested directly; the widget uses it via
  /// [LayoutBuilder].
  static int namesThatFit(
    List<String> names,
    double maxWidth,
    TextStyle style,
    TextScaler scaler,
  ) {
    if (names.isEmpty) return 0;
    const separator = ' · ';
    final painter = TextPainter(
      textScaler: scaler,
      textDirection: TextDirection.ltr,
    );
    for (var i = 1; i <= names.length; i++) {
      final prefix = names.take(i).join(separator);
      final text = i < names.length
          ? '$prefix · +${names.length - i} more'
          : prefix;
      painter.text = TextSpan(text: text, style: style);
      // Measure intrinsic width (no maxWidth) so we can tell whether the
      // single-line preview would overflow the available space.
      painter.layout();
      if (painter.width > maxWidth) {
        // Always show at least one name; let it ellipsize if necessary.
        return i == 1 ? 1 : i - 1;
      }
    }
    return names.length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
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
                  Text.rich(
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final previewStyle = CrudoText.label.copyWith(
                          color: colors.onSurfaceMut,
                          fontWeight: FontWeight.w500,
                        );
                        final count = namesThatFit(
                          ingredientNames,
                          constraints.maxWidth,
                          previewStyle,
                          MediaQuery.textScalerOf(context),
                        );
                        final shown = ingredientNames.take(count).join(' · ');
                        final more = ingredientNames.length - count;
                        final text = more > 0 ? '$shown · +$more more' : shown;
                        return Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: previewStyle,
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: Spacing.md),
                        child: Text(
                          '${macros.kcal.round()} kcal',
                          style: CrudoText.labelMd.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _MacroChip(
                        grams: macros.protein.round(),
                        color: colors.proteinColor,
                      ),
                      _MacroChip(
                        grams: macros.carbs.round(),
                        color: colors.carbsColor,
                      ),
                      _MacroChip(
                        grams: macros.fats.round(),
                        color: colors.fatsColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),
            Center(
              child: Semantics(
                button: onStatusTap != null,
                label: status == MealStatus.done
                    ? 'Undo $title'
                    : 'Mark $title eaten',
                child: GestureDetector(
                  onTap: onStatusTap,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: _statusTapTarget,
                    height: _statusTapTarget,
                    child: Center(
                      child: _StatusCircle(
                        status: status,
                        key: ValueKey('meal-status-${status.name}'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _barColor(CrudoColors colors) => switch (status) {
    MealStatus.done => colors.primarySoft,
    MealStatus.partial => colors.gold,
    MealStatus.upcoming => colors.primary.withValues(alpha: 0.18),
    MealStatus.overdue => colors.overdue,
    MealStatus.skipped => colors.error.withValues(alpha: 0.4),
  };
}

/// Small colored dot + grams label for a single macro.
class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.grams, required this.color});

  final int grams;
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
          '${grams}g',
          style: CrudoText.labelMd.copyWith(color: colors.onSurfaceMut),
        ),
      ],
    );
  }
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
        Icon(Icons.check, size: IconSizes.sm, color: colors.surfaceLowest),
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
      MealStatus.overdue => (
        colors.overdueSoft,
        null,
        Icon(Icons.schedule, size: IconSizes.md, color: colors.overdue),
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
