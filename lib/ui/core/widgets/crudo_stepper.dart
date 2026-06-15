import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;

/// A stepper control with "− value suffix +" layout.
///
/// Clamps to [min, max] by [step]. The plus/minus buttons are teal
/// (`primary`) text glyphs inside 44×44 hit targets.
class CrudoStepper extends StatelessWidget {
  const CrudoStepper({
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.step = 1,
    this.suffix = '',
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String suffix;

  void _increment() {
    final next = value + step;
    if (next <= max) {
      onChanged(next);
    }
  }

  void _decrement() {
    final next = value - step;
    if (next >= min) {
      onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: dim.Radii.all(dim.Radii.full),
      ),
      padding: const EdgeInsets.all(dim.Spacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _decrement,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  '−',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: dim.Spacing.sm),
              child: Text(
                '$value$suffix',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                  height: 1.0,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _increment,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
