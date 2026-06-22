import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart';
import '../../../../core/themes/typography.dart';
import '../../../../core/widgets/primary_cta.dart';
import '../widgets/onboarding_scaffold.dart';

/// Awareness / pain screen (step 0) — highlights the three core frictions
/// that Crudo solves: skipped meals, lost momentum, decision fatigue.
class AwarenessPage extends StatelessWidget {
  const AwarenessPage({
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
      step: 0,
      total: 6,
      onBack: onBack,
      footer: PrimaryCta(label: 'Continue', onPressed: onContinue),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Spacing.md),
            Text('You already know the plan.', style: CrudoText.displaySm),
            const SizedBox(height: Spacing.sm),
            Text(
              "The struggle isn't information — it's the friction of modern life.",
              style: CrudoText.body,
            ),
            const SizedBox(height: Spacing.lg),
            _PainCard(
              title: 'Skipped Meals',
              body: 'Days fly by — meals get forgotten.',
              colors: colors,
            ),
            const SizedBox(height: Spacing.md),
            _PainCard(
              title: 'Lost Momentum',
              body: 'One missed meal cascades into a derailed day.',
              colors: colors,
            ),
            const SizedBox(height: Spacing.md),
            _PainCard(
              title: 'Decision Fatigue',
              body: '"What should I eat now?" drains willpower.',
              colors: colors,
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PainCard extends StatelessWidget {
  const _PainCard({
    required this.title,
    required this.body,
    required this.colors,
  });

  final String title;
  final String body;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: Radii.all(Radii.md),
        boxShadow: Shadows.cloud,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CrudoText.title),
          const SizedBox(height: Spacing.xs),
          Text(body, style: CrudoText.body),
        ],
      ),
    );
  }
}
