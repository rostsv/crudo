import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';

/// Floating streak pill, inset over the intake card. Reads the stub
/// streakCountProvider until S12 lands the real engine.
class StreakChip extends StatelessWidget {
  const StreakChip({required this.count, this.onTap, super.key});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      label: '$count-day streak',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm + Spacing.xs, // 12 on-grid
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primarySoft, colors.primary],
            ),
            borderRadius: Radii.all(Radii.full),
            boxShadow: Shadows.cloud,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: IconSizes.sm,
                color: colors.gold,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                '$count-day streak',
                style: CrudoText.labelMd.copyWith(color: colors.surfaceLowest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
