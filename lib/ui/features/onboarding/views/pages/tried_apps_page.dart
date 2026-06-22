import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimensions.dart';
import '../../../../core/themes/typography.dart';
import '../../../../core/widgets/primary_cta.dart';
import '../../../../core/widgets/selection_card.dart';
import '../widgets/onboarding_scaffold.dart';

const kTriedAppsOptions = <({String id, String label, String sub})>[
  (id: 'mfp', label: 'MyFitnessPal', sub: 'Calorie & macro logger'),
  (id: 'noom', label: 'Noom', sub: 'Behavioural coaching'),
  (id: 'lose', label: 'Lose It! / Cronometer', sub: 'Calorie tracking'),
  (id: 'planner', label: 'Mealime / Eat This Much', sub: 'Recipe planners'),
  (id: 'multi', label: 'A few of these', sub: 'And kept switching'),
  (id: 'none', label: 'No, this is my first', sub: 'Fresh start'),
];

/// Single-select survey: which nutrition apps the user has tried (step 5).
class TriedAppsPage extends StatelessWidget {
  const TriedAppsPage({
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
      step: 5,
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
            'ONE MORE',
            style: CrudoText.label.copyWith(color: colors.primarySoft),
          ),
          const SizedBox(height: Spacing.sm),
          Text('Tried something like this before?', style: CrudoText.displaySm),
          const SizedBox(height: Spacing.sm),
          Text(
            'No judgement — most of us have a graveyard of nutrition apps. Pick the closest.',
            style: CrudoText.body,
          ),
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: ListView.separated(
              itemCount: kTriedAppsOptions.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final o = kTriedAppsOptions[index];
                final isSelected = o.id == selected;
                return SelectionCard(
                  title: o.label,
                  subtitle: o.sub,
                  selected: isSelected,
                  onTap: () => onSelect(o.id),
                  trailing: _RadioDot(selected: isSelected),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    // No-line rule (design_system §150): use a glyph, never a `Border`.
    return Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      size: IconSizes.md,
      color: selected ? colors.primary : colors.onSurfaceMut,
    );
  }
}
