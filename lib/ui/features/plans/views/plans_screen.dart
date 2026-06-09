import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../view_models/plans_list.dart';
import 'plan_list_card.dart';

/// S10 plans list screen. Shows every plan as a card with derived target,
/// weekday chips, Today badge, and Inactive styling. Tapping pushes
/// `/plans/:id`. A sticky "New plan" CTA sits at the bottom.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(plansListProvider);
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return SafeArea(
      child: Column(
        children: [
          // Main content fills remaining space
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'No plans yet',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  )
                : ListView.builder(
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
          ),
          // Sticky CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              0,
              Spacing.md,
              Spacing.md,
            ),
            child: PrimaryCta(
              key: const ValueKey('new-plan'),
              label: 'New plan',
              onPressed: () => context.push('/plans/new'),
            ),
          ),
        ],
      ),
    );
  }
}
