import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/meal/food_snapshot.dart';
import '../../../../domain/shared/enums.dart';
import '../../../../domain/shared/grams.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/today_providers.dart';
import '../view_models/meal_draft.dart';
import '../view_models/meal_draft_controller.dart';
import 'formatting.dart';
import 'grams_entry.dart';

/// S08 instance editor: draft-shaped (name/tags/items), committed ONCE via
/// MealDraftController.save → replaceMeal. Back: pristine pops silently,
/// dirty asks "Discard changes?".
class MealEditorScreen extends ConsumerWidget {
  const MealEditorScreen({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(mealDraftControllerProvider(date, mealId));
    return draft.when(
      data: (d) => _EditorForm(date: date, mealId: mealId, initial: d),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Meal not found', style: CrudoText.body)),
      ),
    );
  }
}

class _EditorForm extends ConsumerStatefulWidget {
  const _EditorForm({
    required this.date,
    required this.mealId,
    required this.initial,
  });

  final DateTime date;
  final String mealId;
  final MealDraft initial;

  @override
  ConsumerState<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends ConsumerState<_EditorForm> {
  late final _name = TextEditingController(text: widget.initial.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  MealDraftController get _ctrl => ref.read(
    mealDraftControllerProvider(widget.date, widget.mealId).notifier,
  );

  Future<void> _save() async {
    // Detach pre-check BEFORE the op: first persist of a future day = detach.
    final today = ref.read(todayProvider);
    final detaches =
        widget.date.isAfter(today) &&
        ref.read(persistedDayProvider(widget.date)).value == null;
    final result = await AsyncValue.guard(_ctrl.save);
    if (!mounted) return;
    if (result is AsyncError) {
      showCrudoToast(
        context,
        "That can't be changed anymore.",
        kind: ToastKind.warn,
      );
      return;
    }
    if (detaches) showCrudoToast(context, detachToastMessage);
    context.pop();
  }

  /// Back handler (header button + system pop via PopScope): pristine pops,
  /// dirty confirms.
  Future<void> _maybePop() async {
    if (!_ctrl.isDirty) {
      context.pop();
      return;
    }
    final discard =
        await showCrudoSheet<bool>(
          context,
          builder: (sheetCtx) => SheetScaffold(
            title: 'Discard changes?',
            body: Text(
              'Your edits to this meal will be lost.',
              style: CrudoText.body,
            ),
            cta: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryCta(
                  label: 'Discard',
                  onPressed: () => Navigator.of(sheetCtx).pop(true),
                ),
                const SizedBox(height: Spacing.sm),
                TextButton(
                  key: const ValueKey('keep-editing'),
                  onPressed: () => Navigator.of(sheetCtx).pop(false),
                  child: const Text('Keep editing'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (discard && mounted) context.pop();
  }

  Future<void> _addIngredient() async {
    final snap = await context.push<FoodSnapshot>(
      '/meal/${dayParam(widget.date)}/${widget.mealId}/edit/add-ingredient',
    );
    if (snap != null) _ctrl.addItem(snap);
  }

  Future<void> _editGrams(int index, FoodSnapshot item) async {
    final g = await showCrudoSheet<Grams>(
      context,
      builder: (_) => GramsSheet(item: item),
    );
    if (g != null) _ctrl.setItemGrams(index, g);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final draft = ref
        .watch(mealDraftControllerProvider(widget.date, widget.mealId))
        .requireValue;
    return PopScope(
      canPop: !_ctrl.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _maybePop();
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Header: back · 'Edit meal' · SAVE.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.sm,
                  Spacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _maybePop,
                      icon: Icon(
                        Icons.arrow_back,
                        size: IconSizes.lg,
                        color: colors.onSurface,
                      ),
                    ),
                    const Expanded(
                      child: Text('Edit meal', style: CrudoText.headlineSm),
                    ),
                    Opacity(
                      opacity: draft.canSave ? 1 : Opacities.disabled,
                      child: TextButton(
                        key: const ValueKey('save-meal'),
                        onPressed: draft.canSave ? _save : null,
                        child: Text(
                          'SAVE',
                          style: CrudoText.labelMd.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    Spacing.xl,
                  ),
                  children: [
                    // NAME
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MEAL NAME', style: CrudoText.label),
                          const SizedBox(height: Spacing.sm),
                          TextField(
                            key: const ValueKey('meal-name'),
                            controller: _name,
                            style: CrudoText.headline,
                            decoration: softInputDecoration(
                              colors,
                              hint: 'e.g. Protein Bowl',
                              hintStyle: CrudoText.headline.copyWith(
                                color: colors.onSurfaceMut,
                              ),
                              radius: Radii.md,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: Spacing.md,
                                vertical: Spacing.md,
                              ),
                            ),
                            onChanged: _ctrl.setName,
                          ),
                          const SizedBox(height: Spacing.lg),
                          // TAGS
                          const Text(
                            'TAGS · SELECT MULTIPLE',
                            style: CrudoText.label,
                          ),
                          const SizedBox(height: Spacing.sm),
                          Wrap(
                            spacing: Spacing.sm,
                            runSpacing: Spacing.sm,
                            children: [
                              for (final t in MealTag.values)
                                Pill(
                                  key: ValueKey('tag-${t.name}'),
                                  label: mealTagLabels[t]!,
                                  selected: draft.tags.contains(t),
                                  onTap: () => _ctrl.toggleTag(t),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    // INGREDIENTS
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceLow,
                        borderRadius: Radii.all(Radii.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Ingredients',
                                  style: CrudoText.headlineSm,
                                ),
                              ),
                              Text(
                                '${draft.items.length} ITEMS',
                                style: CrudoText.label,
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.md),
                          if (draft.items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: Spacing.md,
                              ),
                              child: Center(
                                child: Text(
                                  'No ingredients yet',
                                  key: const ValueKey('editor-empty'),
                                  style: CrudoText.body.copyWith(
                                    color: colors.onSurfaceMut,
                                  ),
                                ),
                              ),
                            )
                          else
                            for (final (i, item) in draft.items.indexed)
                              _IngredientRow(
                                key: ValueKey('ingredient-$i'),
                                item: item,
                                colors: colors,
                                onTap: () => _editGrams(i, item),
                                onRemove: () => _ctrl.removeItem(i),
                              ),
                          const SizedBox(height: Spacing.sm),
                          Semantics(
                            button: true,
                            label: 'Add ingredient',
                            child: GestureDetector(
                              onTap: _addIngredient,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                key: const ValueKey('add-ingredient'),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: Spacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceLowest,
                                  borderRadius: Radii.all(Radii.md),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: IconSizes.sm,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    Text(
                                      'ADD INGREDIENT',
                                      style: CrudoText.labelMd.copyWith(
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    // MACRO PREVIEW (gradient, live)
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        borderRadius: Radii.all(Radii.lg),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primary, colors.primarySoft],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AUTO-CALCULATED',
                            style: CrudoText.label.copyWith(
                              color: colors.surfaceLowest.withValues(
                                alpha: Opacities.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  '${draft.macros.kcal.round()} kcal',
                                  key: const ValueKey('editor-preview-kcal'),
                                  style: CrudoText.displaySm.copyWith(
                                    color: colors.surfaceLowest,
                                  ),
                                ),
                              ),
                              Text(
                                'P ${draft.macros.protein.round()}g'
                                '  C ${draft.macros.carbs.round()}g'
                                '  F ${draft.macros.fats.round()}g',
                                style: CrudoText.body.copyWith(
                                  color: colors.surfaceLowest,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.item,
    required this.colors,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final FoodSnapshot item;
  final CrudoColors colors;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Edit ${item.name} quantity',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: Spacing.xs),
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: colors.surfaceLowest,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: CrudoText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${gramsText(item.grams.value)}g ·'
                      ' ${item.kcal.round()} kcal',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('remove-${item.name}'),
                onPressed: onRemove,
                icon: Icon(
                  Icons.close,
                  size: IconSizes.sm,
                  color: colors.onSurfaceMut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
