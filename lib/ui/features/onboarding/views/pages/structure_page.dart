import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart';
import '../../../../core/themes/typography.dart';
import '../../../../core/widgets/primary_cta.dart';
import '../widgets/onboarding_scaffold.dart';

/// Structure / chaos-vs-crudo screen (step 1) — contrasts life without
/// structure against Crudo's rhythm.
class StructurePage extends StatelessWidget {
  const StructurePage({
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
      step: 1,
      total: 6,
      onBack: onBack,
      footer: PrimaryCta(label: 'Continue', onPressed: onContinue),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Spacing.md),
            Text('Structure beats willpower.', style: CrudoText.displaySm),
            const SizedBox(height: Spacing.sm),
            Text(
              "Crudo holds the rhythm so you don't have to.",
              style: CrudoText.body,
            ),
            const SizedBox(height: Spacing.lg),
            // WITHOUT STRUCTURE
            Text(
              'WITHOUT STRUCTURE',
              style: CrudoText.label.copyWith(color: colors.error),
            ),
            const SizedBox(height: Spacing.sm),
            _ComparisonRow(
              title: 'Skipped breakfast',
              subtitle: '"Too busy"',
              isError: true,
              colors: colors,
            ),
            const SizedBox(height: Spacing.sm),
            _ComparisonRow(
              title: 'Random snacking',
              subtitle: 'Sugar spike',
              isError: true,
              colors: colors,
            ),
            const SizedBox(height: Spacing.lg),
            // VS chip
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surfaceLow,
                  borderRadius: Radii.all(Radii.full),
                ),
                child: Center(
                  child: Text(
                    'VS',
                    style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            // WITH CRUDO
            Text(
              'WITH CRUDO',
              style: CrudoText.label.copyWith(color: colors.primary),
            ),
            const SizedBox(height: Spacing.sm),
            _ComparisonRow(
              title: 'High-protein morning',
              subtitle: '08:00 AM',
              isError: false,
              colors: colors,
            ),
            const SizedBox(height: Spacing.sm),
            _ComparisonRow(
              title: 'Planned fuel',
              subtitle: '01:00 PM',
              isError: false,
              colors: colors,
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.title,
    required this.subtitle,
    required this.isError,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final bool isError;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: isError
            ? colors.surfaceLow
            : colors.primaryContainer.withAlpha(15),
        borderRadius: Radii.all(Radii.full),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isError ? colors.surfaceLowest : colors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isError ? Icons.close : Icons.check,
                size: IconSizes.sm,
                color: isError ? colors.error : colors.surfaceLowest,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CrudoText.title.copyWith(
                    color: isError ? colors.onSurface : colors.primary,
                  ),
                ),
                Text(subtitle, style: CrudoText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
