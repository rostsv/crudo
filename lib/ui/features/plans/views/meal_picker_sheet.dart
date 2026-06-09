import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../meals/view_models/meal_template_rows.dart';
import '../../meals/views/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';

/// Picker result — exactly one variant is meaningful (checked in priority:
/// createNew, then duplicateTemplateId, then selectedTemplateIds).
typedef MealPickerResult = ({
  List<String>? selectedTemplateIds,
  bool createNew,
  String? duplicateTemplateId,
});

/// Shows the picker; returns null if dismissed without action.
Future<MealPickerResult?> showMealPickerSheet(BuildContext context) =>
    showCrudoSheet<MealPickerResult>(
      context,
      builder: (_) => const _MealPickerSheet(),
    );

class _MealPickerSheet extends ConsumerStatefulWidget {
  const _MealPickerSheet();

  @override
  ConsumerState<_MealPickerSheet> createState() => _MealPickerSheetState();
}

class _MealPickerSheetState extends ConsumerState<_MealPickerSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final rows = ref.watch(mealTemplateRowsProvider);

    return SheetScaffold(
      title: 'Add meals',
      body: ListView(
        shrinkWrap: true,
        children: [
          // "Create new meal" CTA
          GestureDetector(
            key: const ValueKey('picker-create-new'),
            onTap: () => Navigator.of(context).pop((
              selectedTemplateIds: null,
              createNew: true,
              duplicateTemplateId: null,
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: dim.Spacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceLow,
                borderRadius: dim.Radii.all(dim.Radii.md),
              ),
              child: Row(
                children: [
                  const SizedBox(width: dim.Spacing.md),
                  Icon(
                    Icons.add_circle_outline,
                    size: dim.IconSizes.lg,
                    color: colors.primary,
                  ),
                  const SizedBox(width: dim.Spacing.sm),
                  Text(
                    'Create new meal',
                    style: CrudoText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: dim.Spacing.sm),
          // Meal template rows
          for (final vm in rows)
            _PickerRow(
              key: ValueKey('picker-row-${vm.id}'),
              vm: vm,
              selected: _selected.contains(vm.id),
              colors: colors,
              onTap: () => setState(() {
                if (_selected.contains(vm.id)) {
                  _selected.remove(vm.id);
                } else {
                  _selected.add(vm.id);
                }
              }),
              onDuplicate: () => Navigator.of(context).pop((
                selectedTemplateIds: null,
                createNew: false,
                duplicateTemplateId: vm.id,
              )),
            ),
        ],
      ),
      cta: PrimaryCta(
        key: const ValueKey('picker-done'),
        label: 'Done · ${_selected.length} selected',
        enabled: _selected.isNotEmpty,
        onPressed: () => Navigator.of(context).pop((
          selectedTemplateIds: _selected.toList(),
          createNew: false,
          duplicateTemplateId: null,
        )),
      ),
    );
  }
}

/// One selectable meal template row in the picker.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.vm,
    required this.selected,
    required this.colors,
    required this.onTap,
    required this.onDuplicate,
    super.key,
  });

  final MealTemplateRowVm vm;
  final bool selected;
  final CrudoColors colors;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final tagsLabel = vm.tags.map((t) => mealTagLabels[t]!).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: dim.Spacing.xs),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: dim.Durations.fast,
          padding: const EdgeInsets.all(dim.Spacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceLowest,
            borderRadius: dim.Radii.all(dim.Radii.md),
          ),
          child: Row(
            children: [
              // Checkmark
              Container(
                width: dim.IconSizes.lg,
                height: dim.IconSizes.lg,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.primary : colors.outline,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: dim.IconSizes.sm,
                        color: colors.surfaceLowest,
                      )
                    : null,
              ),
              const SizedBox(width: dim.Spacing.sm),
              // Name + kcal + tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.name,
                      style: CrudoText.title.copyWith(color: colors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: dim.Spacing.xs),
                    Text(
                      '${vm.kcal} kcal${tagsLabel.isNotEmpty ? ' · $tagsLabel' : ''}',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceVar,
                      ),
                    ),
                  ],
                ),
              ),
              // Duplicate button
              GestureDetector(
                key: ValueKey('picker-dup-${vm.id}'),
                onTap: onDuplicate,
                child: Padding(
                  padding: const EdgeInsets.all(dim.Spacing.sm),
                  child: Icon(
                    Icons.copy_rounded,
                    size: dim.IconSizes.md,
                    color: colors.onSurfaceMut,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
