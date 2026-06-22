import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart';
import '../../../../core/themes/typography.dart';
import '../../../../core/widgets/primary_cta.dart';
import '../../../../core/widgets/selection_card.dart';
import '../widgets/onboarding_scaffold.dart';

const kHeardAboutOptions = <({String id, String label})>[
  (id: 'tiktok', label: 'TikTok'),
  (id: 'instagram', label: 'Instagram'),
  (id: 'youtube', label: 'YouTube'),
  (id: 'reddit', label: 'Reddit'),
  (id: 'friend', label: 'Friend / family'),
  (id: 'search', label: 'App store / search'),
  (id: 'press', label: 'Press / blog'),
  (id: 'other', label: 'Somewhere else'),
];

/// Single-select survey: where the user heard about Crudo (step 4).
class HeardAboutPage extends StatelessWidget {
  const HeardAboutPage({
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    super.key,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return OnboardingScaffold(
      step: 4,
      total: 6,
      onBack: onBack,
      footer: PrimaryCta(
        label: 'Continue',
        onPressed: selected == null ? null : onContinue,
        enabled: selected != null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.md),
          Text(
            'QUICK ONE',
            style: CrudoText.label.copyWith(color: colors.primarySoft),
          ),
          const SizedBox(height: Spacing.sm),
          Text('Where did you hear about Crudo?', style: CrudoText.displaySm),
          const SizedBox(height: Spacing.sm),
          Text(
            "Helps us know what's working. Pick one.",
            style: CrudoText.body,
          ),
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: Spacing.sm,
              crossAxisSpacing: Spacing.sm,
              childAspectRatio: 2.8,
              children: [
                for (final o in kHeardAboutOptions)
                  SelectionCard(
                    title: o.label,
                    selected: o.id == selected,
                    onTap: () => onSelect(o.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
