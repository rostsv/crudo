import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../view_models/food_library.dart';
import 'food_row.dart';

/// S07: food library — search field, grouped list of seed + custom foods,
/// add button (create form) and custom-row tap (edit form). Seed rows are
/// inert — S08's add-ingredient picker gives them a tap meaning.
class FoodLibraryScreen extends ConsumerWidget {
  const FoodLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final groups = ref.watch(foodLibraryProvider);
    final query = ref.watch(foodSearchQueryProvider);
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appbar row: optional back (only when pushed), title, add.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.sm,
                Spacing.md,
                0,
              ),
              child: Row(
                children: [
                  if (context.canPop())
                    IconButton(
                      onPressed: context.pop,
                      icon: Icon(
                        Icons.arrow_back,
                        size: IconSizes.lg,
                        color: colors.onSurface,
                      ),
                    ),
                  const Expanded(
                    child: Text('Food library', style: CrudoText.headline),
                  ),
                  IconButton(
                    key: const ValueKey('add-food'),
                    onPressed: () => context.push('/foods/new'),
                    icon: Icon(
                      Icons.add,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Search — soft input per design system (filled surfaceLow,
            // Radii.sm, no border), hint 'Search foods'.
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
            Expanded(
              child: groups.when(
                data: (gs) => gs.isEmpty
                    ? Center(
                        child: Text(
                          'No foods match "${query.trim()}"',
                          style: CrudoText.body.copyWith(
                            color: colors.onSurfaceMut,
                          ),
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
                                padding: const EdgeInsets.only(
                                  bottom: Spacing.sm,
                                ),
                                child: FoodRow(
                                  food: f,
                                  onTap: f.isCustom
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
        ),
      ),
    );
  }
}
