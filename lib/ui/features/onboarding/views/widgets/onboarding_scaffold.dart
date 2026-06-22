import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart';
import '../../../../core/themes/typography.dart';
import 'onboarding_progress.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.body,
    required this.footer,
    this.step,
    this.total = 6,
    this.onBack,
    super.key,
  });

  final Widget body;
  final Widget footer;
  final int? step;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          // Top bar
          Container(
            height: Spacing.xxl,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            alignment: Alignment.center,
            child: step == null
                ? Text(
                    'Crudo',
                    style: CrudoText.headlineSm.copyWith(
                      color: colors.primarySoft,
                    ),
                  )
                : Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          onPressed: onBack,
                        )
                      else
                        const SizedBox(width: Spacing.xl),
                      Expanded(
                        child: Center(
                          child: OnboardingProgress(step: step!, total: total),
                        ),
                      ),
                      const SizedBox(width: Spacing.xl),
                    ],
                  ),
          ),
          // Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: body,
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.xl,
            ),
            child: footer,
          ),
        ],
      ),
    );
  }
}
