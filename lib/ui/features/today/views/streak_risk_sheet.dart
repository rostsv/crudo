import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../../domain/shared/meal_time.dart';
import '../view_models/notification_scheduler_controller.dart';
import '../view_models/today_providers.dart';
import '../view_models/streak_at_risk_provider.dart';

/// Shows a centered streak-at-risk dialog. Returns when dismissed.
Future<void> showStreakRiskSheet(BuildContext context, StreakRisk risk) =>
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _StreakRiskDialog(risk: risk),
    );

class _StreakRiskDialog extends ConsumerWidget {
  const _StreakRiskDialog({required this.risk});

  final StreakRisk risk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final today = ref.watch(todayProvider);

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
              'STREAK AT RISK',
              style: CrudoText.labelMd.copyWith(color: colors.gold),
            ),
            const SizedBox(height: Spacing.sm),
            // Headline
            Text(
              '${risk.mealsLeft} meals left to keep ${risk.streakDays} days alive.',
              style: CrudoText.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            // Body
            Text(
              '${risk.pivotalMealName} at ${_fmt(risk.pivotalMealTime)} — '
              '${risk.minutesFromNow} minutes from now.',
              style: CrudoText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            // Primary CTA
            PrimaryCta(
              label: 'Got it',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: Spacing.md),
            // Secondary mute button
            TextButton(
              onPressed: () {
                ref.read(mutedRiskDayProvider.notifier).set(today);
                Navigator.pop(context);
              },
              child: Text(
                'Mute today',
                style: CrudoText.bodyLg.copyWith(color: colors.onSurfaceMut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(MealTime t) {
  final hour = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
  final amPm = t.hour < 12 ? 'AM' : 'PM';
  return '$hour:${t.minute.toString().padLeft(2, '0')} $amPm';
}
