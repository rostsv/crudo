import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/typography.dart';

/// Macro distribution ring. Arc lengths are proportional to kcal share
/// (protein×4 : carbs×4 : fats×9). Colors: protein=primary (teal),
/// carbs=gold, fats=primary-soft.
class MacroRing extends StatelessWidget {
  const MacroRing({
    required this.protein,
    required this.carbs,
    required this.fats,
    this.centerLabel,
    this.size = 120,
    super.key,
  });

  final double protein;
  final double carbs;
  final double fats;
  final String? centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          proteinKcal: protein * 4,
          carbsKcal: carbs * 4,
          fatsKcal: fats * 9,
          proteinColor: colors.primary,
          carbsColor: colors.gold,
          fatsColor: colors.primarySoft,
          trackColor: colors.surfaceHigh,
        ),
        child: centerLabel == null
            ? null
            : Center(child: Text(centerLabel!, style: CrudoText.headlineSm)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.proteinKcal,
    required this.carbsKcal,
    required this.fatsKcal,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatsColor,
    required this.trackColor,
  });

  final double proteinKcal;
  final double carbsKcal;
  final double fatsKcal;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatsColor;
  final Color trackColor;

  static const _gap = 0.06; // radians between segments

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, stroke(trackColor));

    final total = proteinKcal + carbsKcal + fatsKcal;
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final (kcal, color) in [
      (proteinKcal, proteinColor),
      (carbsKcal, carbsColor),
      (fatsKcal, fatsColor),
    ]) {
      if (kcal <= 0) continue;
      final sweep = (kcal / total) * 2 * math.pi - _gap;
      canvas.drawArc(
        rect,
        start + _gap / 2,
        math.max(sweep, 0.01),
        false,
        stroke(color),
      );
      start += (kcal / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.proteinKcal != proteinKcal ||
      old.carbsKcal != carbsKcal ||
      old.fatsKcal != fatsKcal;
}
