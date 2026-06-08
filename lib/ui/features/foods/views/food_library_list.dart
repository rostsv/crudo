import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/food/food.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../view_models/food_library.dart';
import 'food_row.dart';

/// The reusable library list (S07 list extracted for the S08 picker):
/// search field + grouped sections + empty-search state.
///
/// Library mode ([onPick] == null): custom rows navigate to the edit form,
/// seed rows are inert. Picker mode: EVERY row calls back with its food.
class FoodLibraryList extends ConsumerWidget {
  const FoodLibraryList({
    this.onPick,
    this.header,
    this.pickerHint = false,
    super.key,
  });

  final void Function(Food food)? onPick;

  /// Optional slot above the first group (the picker's custom-food CTA).
  final Widget? header;

  /// Adds the picker's "add it as a custom food" second line to the
  /// empty-search state.
  final bool pickerHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final groups = ref.watch(foodLibraryProvider);
    final query = ref.watch(foodSearchQueryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.sm,
            Spacing.md,
            0,
          ),
          child: TextField(
            key: const ValueKey('food-search'),
            onChanged: (v) =>
                ref.read(foodSearchQueryProvider.notifier).setQuery(v),
            style: CrudoText.body,
            decoration: softInputDecoration(
              colors,
              hint: 'Search foods',
              prefixIcon: Icon(
                Icons.search,
                size: IconSizes.md,
                color: colors.onSurfaceMut,
              ),
            ),
          ),
        ),
        // Header (the picker's custom-food CTA) renders OUTSIDE the list so
        // it survives an empty search — the empty-state copy points at it.
        if (header != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: header!,
          ),
        Expanded(
          child: groups.when(
            data: (gs) => gs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No foods match "${query.trim()}"',
                          style: CrudoText.body.copyWith(
                            color: colors.onSurfaceMut,
                          ),
                        ),
                        if (pickerHint) ...[
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Use the button above to add it as a custom food.',
                            key: const ValueKey('picker-empty-hint'),
                            style: CrudoText.body.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.md,
                      Spacing.sm,
                      Spacing.md,
                      Spacing.xl,
                    ),
                    children: [
                      for (final g in gs) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: Spacing.md,
                            bottom: Spacing.sm,
                          ),
                          child: Text(
                            g.label.toUpperCase(),
                            key: ValueKey('group-${g.label}'),
                            style: CrudoText.label,
                          ),
                        ),
                        for (final f in g.foods)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.sm),
                            child: FoodRow(
                              food: f,
                              onTap: onPick != null
                                  ? () => onPick!(f)
                                  : f.isCustom
                                  ? () => context.push('/foods/${f.id}')
                                  : null,
                            ),
                          ),
                      ],
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Something went wrong', style: CrudoText.body),
            ),
          ),
        ),
      ],
    );
  }
}
