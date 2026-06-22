import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart';
import '../../../../core/themes/typography.dart';
import '../../../../core/widgets/primary_cta.dart';
import '../widgets/onboarding_scaffold.dart';

/// Transformation screen (step 3) — stats + features that sell the value prop.
class TransformationPage extends StatelessWidget {
  const TransformationPage({
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return OnboardingScaffold(
      step: 3,
      total: 6,
      onBack: onBack,
      footer: PrimaryCta(label: 'Build my plan', onPressed: onContinue),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Spacing.md),
            Text('Turn your plan into a routine.', style: CrudoText.displaySm),
            const SizedBox(height: Spacing.sm),
            Text(
              'Ingredients, gram amounts, reminders, and quick check-ins help you stay on track every day.',
              style: CrudoText.body,
            ),
            const SizedBox(height: Spacing.lg),
            // 3-up stat row
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    figure: '3×',
                    label: 'Consistency',
                    sub: 'vs no system',
                    colors: colors,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _StatTile(
                    figure: '87%',
                    label: 'Adherence',
                    sub: 'avg week 2',
                    colors: colors,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: _StatTile(
                    figure: '21d',
                    label: 'Habit',
                    sub: 'with reminders',
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            // Feature list
            _FeatureRow(
              number: '01',
              title: 'Smart reminders',
              body: 'Nudges at the right moment, not just a fixed time.',
              colors: colors,
            ),
            const SizedBox(height: Spacing.md),
            _FeatureRow(
              number: '02',
              title: 'Structured plans',
              body: 'Assign meals to days. Crudo tracks what is next.',
              colors: colors,
            ),
            const SizedBox(height: Spacing.md),
            _FeatureRow(
              number: '03',
              title: 'Flexible snoozing',
              body: 'Push a meal forward without losing your streak.',
              colors: colors,
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.figure,
    required this.label,
    required this.sub,
    required this.colors,
  });

  final String figure;
  final String label;
  final String sub;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: Radii.all(Radii.md),
        boxShadow: Shadows.cloud,
      ),
      child: Column(
        children: [
          Text(
            figure,
            style: CrudoText.headline.copyWith(color: colors.primary),
          ),
          const SizedBox(height: Spacing.xs),
          Text(label, style: CrudoText.label.copyWith(color: colors.onSurface)),
          const SizedBox(height: Spacing.xs),
          Text(
            sub,
            style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.number,
    required this.title,
    required this.body,
    required this.colors,
  });

  final String number;
  final String title;
  final String body;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primaryContainer.withAlpha(20),
            borderRadius: Radii.all(Radii.sm),
          ),
          child: Center(
            child: Text(
              number,
              style: CrudoText.title.copyWith(color: colors.primary),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: CrudoText.title),
              const SizedBox(height: Spacing.xs),
              Text(body, style: CrudoText.body),
            ],
          ),
        ),
      ],
    );
  }
}
