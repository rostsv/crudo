import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/shared/enums.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/widgets/selection_card.dart';
import '../../../core/widgets/sheet.dart';
import '../../../features/profile/view_models/profile_controller.dart';
import '../../../features/today/view_models/today_providers.dart';

Future<void> showUnitsSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const _UnitsSheet());

class _UnitsSheet extends ConsumerWidget {
  const _UnitsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final current = profile.value?.prefs.units ?? Unit.g;

    return SheetScaffold(
      title: 'Units',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectionCard(
            title: 'Grams',
            selected: current == Unit.g,
            onTap: () async {
              await ref
                  .read(profileControllerProvider.notifier)
                  .setUnits(Unit.g);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: dim.Spacing.sm),
          SelectionCard(
            title: 'Ounces',
            selected: current == Unit.oz,
            onTap: () async {
              await ref
                  .read(profileControllerProvider.notifier)
                  .setUnits(Unit.oz);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
