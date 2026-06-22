import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart' as dim;

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    required this.step,
    required this.total,
    super.key,
  });

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isCurrent = i == step;
        final isCompleted = i <= step;

        return AnimatedContainer(
          duration: dim.Durations.base,
          width: isCurrent ? dim.Spacing.lg : dim.Spacing.sm,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: dim.Spacing.xs / 2),
          decoration: BoxDecoration(
            color: isCompleted
                ? colors.primary
                : colors.primary.withValues(alpha: 0.15),
            borderRadius: dim.Radii.all(dim.Radii.full),
          ),
        );
      }),
    );
  }
}
