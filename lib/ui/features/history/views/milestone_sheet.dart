import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';

/// Shows a centered milestone celebration dialog when a streak crosses
/// 7 / 30 / 100 days. Returns when dismissed so the caller can chain
/// multiple crossings in order.
Future<void> showMilestoneSheet(BuildContext context, int milestone) =>
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _MilestoneDialog(milestone: milestone),
    );

class _MilestoneDialog extends StatelessWidget {
  const _MilestoneDialog({required this.milestone});

  final int milestone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: Radii.all(Radii.lg),
          boxShadow: Shadows.cloud,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold flame circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.local_fire_department,
                  size: IconSizes.xl,
                  color: colors.gold,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // Label
            Text(
              'STREAK MILESTONE',
              style: CrudoText.labelMd.copyWith(color: colors.gold),
            ),
            const SizedBox(height: Spacing.sm),
            // Headline
            Text(
              '$milestone-day streak!',
              style: CrudoText.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            // Body
            Text(
              '$milestone days locked in. Keep the fire going.',
              style: CrudoText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            // Primary CTA
            PrimaryCta(
              label: 'Keep going',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
