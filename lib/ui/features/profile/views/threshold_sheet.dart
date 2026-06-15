import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/widgets/selection_card.dart';
import '../../../core/widgets/sheet.dart';
import '../../../features/profile/view_models/profile_controller.dart';
import '../../../features/today/view_models/today_providers.dart';

Future<void> showThresholdSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const _ThresholdSheet());

class _ThresholdSheet extends ConsumerWidget {
  const _ThresholdSheet();

  static const _values = [70, 80, 90, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final current = profile.value?.prefs.streakThreshold ?? 80;

    return SheetScaffold(
      title: 'Streak threshold',
      label: 'GREEN LINE',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in _values)
            Padding(
              padding: const EdgeInsets.only(bottom: dim.Spacing.sm),
              child: SelectionCard(
                title: '$value%',
                subtitle: '% of planned calories',
                selected: current == value,
                onTap: () async {
                  await ref
                      .read(profileControllerProvider.notifier)
                      .setThreshold(value);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ),
        ],
      ),
    );
  }
}
