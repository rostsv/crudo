import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/food/food.dart';
import '../../../../domain/meal/meal_template.dart';
import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/services/nutrition.dart';
import '../../../../domain/shared/enums.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/day_controller.dart';
import '../../today/view_models/today_providers.dart';
import 'formatting.dart';

/// Swap-from-library sheet (S08, sheets.jsx SwapSheet): tag-grouped rows
/// ("SAME TYPE" / "OTHER MEALS") with a sticky search field that flattens
/// sections. A template whose refs all dangle renders disabled.
class SwapSheet extends ConsumerStatefulWidget {
  const SwapSheet({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  @override
  ConsumerState<SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<SwapSheet> {
  late final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final templates = ref.watch(mealTemplatesProvider).value ?? const [];
    final foods = ref.watch(foodsProvider).value ?? const [];
    final day = ref.watch(dayControllerProvider(widget.date)).value;
    final meal = day?.meals.where((m) => m.id == widget.mealId).firstOrNull;
    final currentTags = meal?.meal.tags ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.lg),
        ),
        boxShadow: Shadows.cloud,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: Spacing.xs,
                decoration: BoxDecoration(
                  color: colors.surfaceHighest,
                  borderRadius: Radii.all(Radii.full),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Label
            const Text('FROM YOUR LIBRARY', style: CrudoText.label),
            const SizedBox(height: Spacing.xs),
            // Title
            const Text('Swap meal', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            // Search (sticky)
            TextField(
              key: const ValueKey('swap-search'),
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: CrudoText.body,
              decoration: softInputDecoration(
                colors,
                hint: 'Filter meals…',
                prefixIcon: Icon(
                  Icons.search,
                  size: IconSizes.md,
                  color: colors.onSurfaceMut,
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            // List
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Text(
                        'No meals in your library yet.',
                        key: const ValueKey('swap-empty'),
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      ),
                    )
                  : ListView(
                      children: _buildSections(
                        templates,
                        foods,
                        currentTags,
                        colors,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections(
    List<MealTemplate> templates,
    List<Food> foods,
    List<MealTag> currentTags,
    CrudoColors colors,
  ) {
    // Searching: flat filtered list, no headers
    if (_query.isNotEmpty) {
      return [
        for (final t in templates)
          if (t.name.toLowerCase().contains(_query))
            _buildRow(t, foods, colors),
      ];
    }

    // No tags → flat list, no sections
    if (currentTags.isEmpty) {
      return [for (final t in templates) _buildRow(t, foods, colors)];
    }

    // Partition: OR match — template matches any of currentTags.
    final matching = <MealTemplate>[];
    final others = <MealTemplate>[];
    for (final t in templates) {
      if (t.tags.any((tag) => currentTags.contains(tag))) {
        matching.add(t);
      } else {
        others.add(t);
      }
    }

    final result = <Widget>[];
    if (matching.isNotEmpty) {
      result.add(const _SectionHeader(label: 'SAME TYPE'));
      for (final t in matching) {
        result.add(_buildRow(t, foods, colors));
      }
    }
    result.add(const _SectionHeader(label: 'OTHER MEALS'));
    for (final t in others) {
      result.add(_buildRow(t, foods, colors));
    }
    return result;
  }

  Widget _buildRow(MealTemplate t, List<Food> foods, CrudoColors colors) {
    final enabled = mealSnapshotFromTemplate(t, foods).items.isNotEmpty;
    return _SwapRow(
      key: ValueKey('swap-${t.id}'),
      name: t.name,
      summary: _summary(t, foods),
      enabled: enabled,
      colors: colors,
      onTap: () => _swap(t, foods),
    );
  }

  /// Detach-aware commit: when this op is the future day's FIRST persist
  /// (no repo row before it), announce the detach.
  Future<void> _swap(MealTemplate t, List<Food> foods) async {
    final today = ref.read(todayProvider);
    final detaches =
        widget.date.isAfter(today) &&
        ref.read(persistedDayProvider(widget.date)).value == null;
    try {
      await ref
          .read(dayControllerProvider(widget.date).notifier)
          .replaceMeal(widget.mealId, mealSnapshotFromTemplate(t, foods));
      if (!mounted) return;
      if (detaches) {
        showCrudoToast(
          context,
          'Future day saved separately',
          body: detachToastMessage,
        );
      }
      Navigator.of(context).pop();
    } on StateError {
      if (!mounted) return;
      showCrudoToast(
        context,
        "That can't be changed anymore.",
        body: 'This meal is already logged, skipped, or locked.',
        kind: ToastKind.warn,
      );
    }
  }

  String _summary(MealTemplate t, List<Food> foods) {
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

/// Section header for tag-based grouping ("SAME TYPE" / "OTHER MEALS").
/// No `colors` param — CrudoText.label carries its own color (onSurfaceMut);
/// an unused field would trip `unused_field` lint.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
      child: Text(label, style: CrudoText.label),
    );
  }
}
