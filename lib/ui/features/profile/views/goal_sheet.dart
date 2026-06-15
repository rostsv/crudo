import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/shared/enums.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/widgets/crudo_stepper.dart';
import '../../../core/widgets/crudo_toggle.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/selection_card.dart';
import '../../../core/widgets/settings_section.dart';
import '../../../core/widgets/sheet.dart';
import '../../../features/profile/view_models/profile_controller.dart';
import '../../../features/today/view_models/today_providers.dart';

Future<void> showGoalSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const _GoalSheet());

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet();

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  late Goal _goal;
  late bool _targetEnabled;
  late int _targetValue;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(profileProvider).requireValue.prefs;
    _goal = prefs.goal;
    _targetEnabled = prefs.dailyKcalTarget != null;
    _targetValue = prefs.dailyKcalTarget ?? 2000;
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Goal',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectionCard(
            title: 'Cut',
            selected: _goal == Goal.cut,
            onTap: () => setState(() => _goal = Goal.cut),
          ),
          const SizedBox(height: dim.Spacing.sm),
          SelectionCard(
            title: 'Maintain',
            selected: _goal == Goal.maintain,
            onTap: () => setState(() => _goal = Goal.maintain),
          ),
          const SizedBox(height: dim.Spacing.sm),
          SelectionCard(
            title: 'Bulk',
            selected: _goal == Goal.bulk,
            onTap: () => setState(() => _goal = Goal.bulk),
          ),
          const SizedBox(height: dim.Spacing.md),
          SettingsRow(
            label: 'Set a target',
            trailing: CrudoToggle(
              value: _targetEnabled,
              onChanged: (v) => setState(() => _targetEnabled = v),
            ),
          ),
          if (_targetEnabled) ...[
            const SizedBox(height: dim.Spacing.sm),
            CrudoStepper(
              value: _targetValue,
              onChanged: (v) => setState(() => _targetValue = v),
              min: 1200,
              max: 4000,
              step: 50,
              suffix: ' kcal',
            ),
          ],
        ],
      ),
      cta: PrimaryCta(
        label: 'Save',
        onPressed: () async {
          await ref
              .read(profileControllerProvider.notifier)
              .setGoal(_goal, kcalTarget: _targetEnabled ? _targetValue : null);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}
