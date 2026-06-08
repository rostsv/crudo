import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../view_models/plans_list.dart';
import 'plan_list_card.dart';

/// S10 plans list screen. Shows every plan as a card with derived target,
/// weekday chips, Today badge, and Inactive styling. Tapping pushes
/// `/plans/:id`.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(plansListProvider);
    final colors = Theme.of(context).extension<CrudoColors>()!;

    if (rows.isEmpty) {
      return SafeArea(
        child: Center(
          child: Text(
            'No plans yet',
            style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
          ),
        ),
      );
    }

    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: rows.length + 1, // +1 for headline
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: Spacing.md),
              child: Text('Plans', style: CrudoText.headline),
            );
          }
          final row = rows[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: PlanListCard(
              row: row,
              onTap: () => context.push('/plans/${row.id}'),
            ),
          );
        },
      ),
    );
  }
}
