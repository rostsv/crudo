import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart' as dim;
import '../../../../core/themes/typography.dart';
import '../../../../core/widgets/primary_cta.dart';

/// Welcome / first screen — bespoke layout (no [OnboardingScaffold]).
///
/// Shows a wordmark, three decorative hero meal cards, a headline + sub,
/// a primary CTA ("Set up my plan"), and a secondary text button
/// ("I already have an account"). Hero cards are purely decorative.
class WelcomePage extends StatelessWidget {
  const WelcomePage({required this.onSetUp, required this.onSignIn, super.key});

  final VoidCallback onSetUp;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  // Wordmark
                  Text(
                    'Crudo',
                    style: CrudoText.headline.copyWith(color: colors.primary),
                  ),
                  const SizedBox(height: dim.Spacing.lg),
                  // Hero card stack
                  SizedBox(
                    height: 256, // 3 x 80 + 2 x 8 gaps, on the 4px grid
                    child: Column(
                      children: [
                        _HeroCard(
                          mealName: 'Protein Bowl',
                          timeLabel: '08:00 AM',
                          barColor: colors.primarySoft,
                          statusGlyph: const Icon(
                            Icons.check,
                            size: dim.IconSizes.sm,
                            color: CrudoPalette.primarySoft,
                          ),
                        ),
                        const SizedBox(height: dim.Spacing.sm),
                        _HeroCard(
                          mealName: 'Quinoa Salad',
                          timeLabel: '12:30 \u2192 13:15',
                          barColor: colors.gold,
                          statusGlyph: const Icon(
                            Icons.access_time,
                            size: dim.IconSizes.sm,
                            color: CrudoPalette.gold,
                          ),
                          timeTextStyle: CrudoText.label.copyWith(
                            color: colors.gold,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: dim.Spacing.sm),
                        _HeroCard(
                          mealName: 'Baked Salmon',
                          timeLabel: '07:00 PM',
                          barColor: colors.onSurfaceMut,
                          statusGlyph: const Icon(
                            Icons.circle_outlined,
                            size: dim.IconSizes.sm,
                            color: CrudoPalette.onSurfaceMut,
                          ),
                          timeTextStyle: CrudoText.label.copyWith(
                            color: colors.onSurfaceMut,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: dim.Spacing.xl),
                  // Headline
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: dim.Spacing.lg,
                    ),
                    child: Text(
                      'Follow your meal plan without overthinking',
                      style: CrudoText.displaySm,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: dim.Spacing.sm),
                  // Sub
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: dim.Spacing.lg,
                    ),
                    child: Text(
                      'Build your meals once, get reminded on time, '
                      'keep your streak alive.',
                      style: CrudoText.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: dim.Spacing.xl),
                  // CTA
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: dim.Spacing.lg,
                    ),
                    child: PrimaryCta(
                      label: 'Set up my plan',
                      onPressed: onSetUp,
                    ),
                  ),
                  const SizedBox(height: dim.Spacing.sm),
                  // Sign in
                  TextButton(
                    onPressed: onSignIn,
                    child: Text(
                      'I already have an account',
                      style: CrudoText.labelMd.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ),
                  const SizedBox(height: dim.Spacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single decorative meal card in the hero stack.
///
/// Renders a vertical accent bar, a time label + meal name, and a trailing
/// status glyph. No interaction (purely presentational).
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.mealName,
    required this.timeLabel,
    required this.barColor,
    required this.statusGlyph,
    this.timeTextStyle,
  });

  final String mealName;
  final String timeLabel;
  final Color barColor;
  final Widget statusGlyph;
  final TextStyle? timeTextStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: dim.Spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: dim.Radii.all(dim.Radii.lg),
        boxShadow: dim.Shadows.cloud,
      ),
      child: Row(
        children: [
          // Leading accent bar
          Container(
            width: 3,
            height: dim.IconSizes.lg,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: dim.Radii.all(dim.Radii.full),
            ),
          ),
          const SizedBox(width: dim.Spacing.sm),
          // Time + meal name
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style:
                      timeTextStyle ??
                      CrudoText.label.copyWith(color: colors.onSurfaceVar),
                ),
                const SizedBox(height: dim.Spacing.xs),
                Text(mealName, style: CrudoText.title),
              ],
            ),
          ),
          // Status glyph
          statusGlyph,
        ],
      ),
    );
  }
}
