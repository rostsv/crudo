import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/food/food.dart';
import '../../../../domain/meal/meal_template.dart';
import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/nutrition.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/day_controller.dart';
import '../../today/view_models/today_providers.dart';
import 'formatting.dart';

/// Swap-from-library sheet (S08, sheets.jsx SwapSheet): meal-template rows,
/// tap = immediate replaceMeal + close (reversible — the meal was upcoming,
/// nothing checked). A template whose refs all dangle renders disabled.
class SwapSheet extends ConsumerWidget {
  const SwapSheet({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final templates = ref.watch(mealTemplatesProvider).value ?? const [];
    final foods = ref.watch(foodsProvider).value ?? const [];
    return SheetScaffold(
      label: 'From your library',
      title: 'Swap meal',
      body: templates.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              child: Text(
                'No meals in your library yet.',
                key: const ValueKey('swap-empty'),
                style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
              ),
            )
          : ListView(
              shrinkWrap: true,
              children: [
                for (final t in templates)
                  _SwapRow(
                    key: ValueKey('swap-${t.id}'),
                    name: t.name,
                    summary: _summary(t, foods),
                    enabled: mealSnapshotFromTemplate(
                      t,
                      foods,
                    ).items.isNotEmpty,
                    colors: colors,
                    onTap: () => _swap(context, ref, t, foods),
                  ),
              ],
            ),
    );
  }

  /// Detach-aware commit (review amendment): when this op is the future
  /// day's FIRST persist (no repo row before it), announce the detach.
  Future<void> _swap(
    BuildContext context,
    WidgetRef ref,
    MealTemplate t,
    List<Food> foods,
  ) async {
    final today = ref.read(todayProvider);
    final detaches =
        date.isAfter(today) &&
        ref.read(persistedDayProvider(date)).value == null;
    try {
      await ref
          .read(dayControllerProvider(date).notifier)
          .replaceMeal(mealId, mealSnapshotFromTemplate(t, foods));
      if (!context.mounted) return;
      if (detaches) showCrudoToast(context, detachToastMessage);
      Navigator.of(context).pop();
    } on StateError {
      if (context.mounted) {
        showCrudoToast(
          context,
          "That can't be changed anymore.",
          kind: ToastKind.warn,
        );
      }
    }
  }

  static String _summary(MealTemplate t, List<Food> foods) {
    final resolved = mealSnapshotFromTemplate(t, foods);
    final m = mealSnapshotMacros(resolved);
    final tags = [for (final tag in t.tags) mealTagLabels[tag]!].join(' · ');
    final lead = tags.isEmpty ? '' : '$tags · ';
    return '$lead${m.kcal.round()} kcal · ${resolved.items.length} ingredients';
  }
}

class _SwapRow extends StatelessWidget {
  const _SwapRow({
    required this.name,
    required this.summary,
    required this.enabled,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final String name;
  final String summary;
  final bool enabled;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : Opacities.disabled,
      child: Semantics(
        button: enabled,
        label: 'Swap to $name',
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: Spacing.xs),
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceLow,
              borderRadius: Radii.all(Radii.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: CrudoText.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        summary,
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.swap_horiz,
                  size: IconSizes.sm,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
