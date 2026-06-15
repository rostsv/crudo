import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart' as dim;

/// A styled toggle switch with a 48×28 pill shape.
///
/// Off track = `surfaceHigh`, on track = `primary`. Thumb is white.
/// No Material default styling — fully custom.
class CrudoToggle extends StatelessWidget {
  const CrudoToggle({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: dim.Durations.fast,
          width: 48,
          height: 28,
          decoration: BoxDecoration(
            color: value ? colors.primary : colors.surfaceHigh,
            borderRadius: dim.Radii.all(dim.Radii.full),
          ),
          padding: const EdgeInsets.all(3),
          child: AnimatedAlign(
            duration: dim.Durations.fast,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: dim.Radii.all(dim.Radii.full),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
