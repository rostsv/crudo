import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/widgets/crudo_stepper.dart';
import '../../../core/widgets/crudo_toggle.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/settings_section.dart';
import '../../../core/widgets/sheet.dart';
import '../../../features/profile/view_models/profile_controller.dart';
import '../../../features/today/view_models/today_providers.dart';

Future<void> showRemindersSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const _RemindersSheet());

class _RemindersSheet extends ConsumerStatefulWidget {
  const _RemindersSheet();

  @override
  ConsumerState<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends ConsumerState<_RemindersSheet> {
  late bool _preOn;
  late bool _atOn;
  late bool _eodOn;
  late bool _riskOn;
  late int _preMin;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(profileProvider).requireValue.prefs;
    _preOn = prefs.preOn;
    _atOn = prefs.atOn;
    _eodOn = prefs.eodOn;
    _riskOn = prefs.riskOn;
    _preMin = prefs.preMin;
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      label: 'NOTIFICATIONS',
      title: 'How we ping you',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsRow(
            label: 'Pre-meal heads up',
            trailing: CrudoToggle(
              value: _preOn,
              onChanged: (v) => setState(() => _preOn = v),
            ),
          ),
          const SizedBox(height: dim.Spacing.sm),
          SettingsRow(
            label: 'At meal time',
            trailing: CrudoToggle(
              value: _atOn,
              onChanged: (v) => setState(() => _atOn = v),
            ),
          ),
          const SizedBox(height: dim.Spacing.sm),
          SettingsRow(
            label: 'End of day summary',
            trailing: CrudoToggle(
              value: _eodOn,
              onChanged: (v) => setState(() => _eodOn = v),
            ),
          ),
          const SizedBox(height: dim.Spacing.sm),
          SettingsRow(
            label: 'Streak at risk',
            trailing: CrudoToggle(
              value: _riskOn,
              onChanged: (v) => setState(() => _riskOn = v),
            ),
          ),
          const SizedBox(height: dim.Spacing.sm),
          SettingsRow(
            label: 'Pre-meal lead',
            trailing: CrudoStepper(
              value: _preMin,
              onChanged: (v) => setState(() => _preMin = v),
              min: 5,
              max: 60,
              step: 5,
              suffix: 'm',
            ),
          ),
        ],
      ),
      cta: PrimaryCta(
        label: 'Save',
        onPressed: () async {
          await ref
              .read(profileControllerProvider.notifier)
              .setNotifToggle(
                pre: _preOn,
                at: _atOn,
                eod: _eodOn,
                risk: _riskOn,
              );
          await ref.read(profileControllerProvider.notifier).setPreMin(_preMin);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}
