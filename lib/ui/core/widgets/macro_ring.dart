import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/colors.dart';

/// Macro-progress ring: a thin single-value arc over a muted track
/// (design system: "thin 2px strokes, never heavy donuts"). [value] is the
/// 0–1 progress share (clamped); [center] floats in the middle (icon, kcal
/// label). Macro P/C/F split renders as slim Progress bars, not this ring.
class MacroRing extends StatelessWidget {
  const MacroRing({
    required this.value,
    this.size = 72,
    this.strokeWidth = 2.5,
    this.color,
    this.trackColor,
    this.center,
    super.key,
  });

  /// Progress share, clamped to 0–1.
  final double value;
  final double size;
  final double strokeWidth;

  /// Arc color; defaults to primary teal.
  final Color? color;

  /// Track color; defaults to the outline ghost tone.
  final Color? trackColor;

  /// Centered overlay (icon or label).
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0, 1).toDouble(),
          color: color ?? colors.primary,
          trackColor: trackColor ?? colors.outline,
          strokeWidth: strokeWidth,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, stroke(trackColor));
    if (value <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at 12 o'clock
      value * 2 * math.pi,
      false,
      stroke(color),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
