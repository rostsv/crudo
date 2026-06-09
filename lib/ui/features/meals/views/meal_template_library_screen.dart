import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../view_models/meal_template_rows.dart';
import 'formatting.dart';

/// S11a: meal-template library list — one card per template, tap to edit,
/// "New" CTA to create. Mirrors [FoodLibraryScreen].
class MealTemplateLibraryScreen extends ConsumerWidget {
  const MealTemplateLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final rows = ref.watch(mealTemplateRowsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appbar row: optional back, title, add.
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
                    child: Text('Meals', style: CrudoText.headline),
                  ),
                  IconButton(
                    key: const ValueKey('add-template'),
                    onPressed: () => context.push('/meal-templates/new'),
                    icon: Icon(
                      Icons.add,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Body
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      key: const ValueKey('templates-empty'),
                      child: Text(
                        'No meals yet',
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                      ),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final vm = rows[index];
                        return _TemplateCard(vm: vm, colors: colors);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.vm, required this.colors});

  final MealTemplateRowVm vm;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    final tagsLabel = vm.tags.map((t) => mealTagLabels[t]!).join(' · ');
    final usageText = vm.usedInPlans == 0
        ? 'Unused'
        : 'Used in ${vm.usedInPlans} plan${vm.usedInPlans == 1 ? '' : 's'}';

    return Semantics(
      button: true,
      label: 'Edit ${vm.name}',
      child: GestureDetector(
        key: ValueKey('template-row-${vm.id}'),
        onTap: () => context.push('/meal-templates/${vm.id}'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.md),
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vm.name, style: CrudoText.headlineSm),
              const SizedBox(height: Spacing.xs),
              Text(
                '${vm.kcal} kcal · $tagsLabel',
                style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
              ),
              const SizedBox(height: Spacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceHigh,
                  borderRadius: Radii.all(Radii.full),
                ),
                child: Text(
                  usageText,
                  style: CrudoText.labelMd.copyWith(color: colors.onSurfaceVar),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
