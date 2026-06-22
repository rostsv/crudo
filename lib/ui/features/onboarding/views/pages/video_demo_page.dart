import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart';
import '../../../../core/themes/typography.dart';
import '../../../../core/widgets/primary_cta.dart';
import '../widgets/onboarding_scaffold.dart';

/// Video demo placeholder (step 2) — a 9:16 aspect-ratio preview with a
/// tappable play button.  No real video asset is wired; [onPlay] is a stub.
class VideoDemoPage extends StatelessWidget {
  const VideoDemoPage({
    required this.onPlay,
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  final VoidCallback onPlay;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return OnboardingScaffold(
      step: 2,
      total: 6,
      onBack: onBack,
      footer: PrimaryCta(label: 'Watch & Continue', onPressed: onContinue),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Spacing.md),
            Text(
              '60 SECOND TOUR',
              style: CrudoText.label.copyWith(color: colors.primarySoft),
            ),
            const SizedBox(height: Spacing.sm),
            Text('See how Crudo works', style: CrudoText.displaySm),
            const SizedBox(height: Spacing.sm),
            Text(
              'Plans, reminders, snoozing — the daily loop, in under a minute.',
              style: CrudoText.body,
            ),
            const SizedBox(height: Spacing.lg),
            // Video placeholder
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: Radii.all(Radii.lg),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.primary, colors.primarySoft],
                    ),
                    boxShadow: Shadows.cloudDeep,
                  ),
                  child: Stack(
                    children: [
                      // DEMO tag
                      Positioned(
                        top: Spacing.md,
                        left: Spacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.onSurface.withAlpha(77),
                            borderRadius: Radii.all(Radii.sm),
                          ),
                          child: Text(
                            'DEMO',
                            style: CrudoText.label.copyWith(
                              color: colors.surfaceLowest,
                            ),
                          ),
                        ),
                      ),
                      // Play button
                      Center(
                        child: GestureDetector(
                          key: const ValueKey('demo-play'),
                          onTap: onPlay,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colors.surfaceLowest.withAlpha(235),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.play_arrow,
                                size: IconSizes.xl,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Duration pill
                      Positioned(
                        bottom: Spacing.md,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm,
                              vertical: Spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: colors.onSurface.withAlpha(102),
                              borderRadius: Radii.all(Radii.full),
                            ),
                            child: Text(
                              '0:58',
                              style: CrudoText.labelMd.copyWith(
                                color: colors.surfaceLowest,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
    );
  }
}
