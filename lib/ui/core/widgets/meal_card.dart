import 'package:flutter/material.dart';

import 'package:crudo/domain/shared/enums.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// A meal row: status glyph + title + time/kcal. Status colors per design
/// system: done=teal, partial=gold split-circle (never "½"), upcoming=muted,
/// skipped=red. No dividers — cards separate by spacing.
class MealCard extends StatelessWidget {
  const MealCard({
    required this.title,
    required this.timeLabel,
    required this.kcalLabel,
    required this.status,
    this.onTap,
    super.key,
  });

  final String title;
  final String timeLabel;
  final String kcalLabel;
  final MealStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: Radii.all(Radii.md),
        ),
        child: Row(
          children: [
            _StatusGlyph(
              status: status,
              key: ValueKey('meal-status-${status.name}'),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CrudoText.title),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '$timeLabel · $kcalLabel',
                    style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.status, super.key});

  final MealStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return switch (status) {
      MealStatus.done => Icon(Icons.check_circle, color: colors.primary),
      MealStatus.partial => CustomPaint(
        size: const Size.square(24),
        painter: _SplitCirclePainter(colors.gold),
      ),
      MealStatus.upcoming => Icon(
        Icons.circle_outlined,
        color: colors.onSurfaceMut,
      ),
      MealStatus.skipped => Icon(
        Icons.do_not_disturb_on_outlined,
        color: colors.error,
      ),
    };
  }
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
