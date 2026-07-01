import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/food/food.dart';
import '../../../../domain/food/food_ref.dart';
import '../../../../domain/meal/food_snapshot.dart';
import '../../../../domain/meal/meal_template.dart';
import '../../../../domain/services/plan_scheduling.dart';
import '../../../../domain/shared/enums.dart';
import '../../../../domain/shared/grams.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/today_providers.dart';
import '../view_models/meal_template_draft.dart';
import '../view_models/meal_template_draft_controller.dart';
import 'formatting.dart';
import 'grams_entry.dart';

/// S11a library builder: create/edit a reusable [MealTemplate]. Draft-shaped,
/// committed once via [MealTemplateDraftController.save]. Back: pristine pops
/// silently, dirty asks "Discard changes?". If [seed] is provided (create-mode
/// in-memory duplicate), the draft is pre-populated from it once.
class MealTemplateBuilderScreen extends ConsumerWidget {
  const MealTemplateBuilderScreen({
    required this.templateId,
    this.seed,
    super.key,
  });

  final String? templateId; // null = create
  final MealTemplate? seed; // create-mode in-memory seed

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(mealTemplateDraftControllerProvider(templateId));
    return draft.when(
      data: (d) => _BuilderForm(templateId: templateId, seed: seed, initial: d),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Meal not found', style: CrudoText.body)),
      ),
    );
  }
}

class _BuilderForm extends ConsumerStatefulWidget {
  const _BuilderForm({
    required this.templateId,
    this.seed,
    required this.initial,
  });

  final String? templateId;
  final MealTemplate? seed; // create-mode in-memory seed
  final MealTemplateDraft initial;

  @override
  ConsumerState<_BuilderForm> createState() => _BuilderFormState();
}

class _BuilderFormState extends ConsumerState<_BuilderForm> {
  late final _name = TextEditingController(
    text: widget.seed?.name ?? widget.initial.name,
  );

  @override
  void initState() {
    super.initState();
    // Seed once: if we're in create mode with a seed, populate the draft.
    if (widget.templateId == null && widget.seed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(mealTemplateDraftControllerProvider(null).notifier)
            .seedFrom(widget.seed!);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  MealTemplateDraftController get _ctrl =>
      ref.read(mealTemplateDraftControllerProvider(widget.templateId).notifier);

  Future<void> _save() async {
    final saved = await _ctrl.save();
    if (!mounted) return;
    context.pop(saved);
  }

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
    final r = await context.push<({Food food, Grams grams})>(
      '/meal-templates/${widget.templateId ?? 'new'}/add-ingredient',
    );
    if (r != null) {
      _ctrl.addFood(FoodRef(foodId: r.food.id, grams: r.grams));
    }
  }

  Future<void> _editGrams(int index, FoodRef foodRef) async {
    final foodsById = _ctrl.foodsById;
    final food = foodsById[foodRef.foodId];
    if (food == null) return;
    final snapshot = FoodSnapshot.from(food, foodRef.grams);
    final g = await showCrudoSheet<Grams>(
      context,
      builder: (_) => GramsSheet(item: snapshot),
    );
    if (g != null) _ctrl.setGrams(index, g);
  }

  Future<void> _delete() async {
    var out = await _ctrl.delete();
    if (!mounted) return;
    if (out.blockedByEmpty) {
      final names = out.affected.map((p) => p.name).join(', ');
      showCrudoToast(
        context,
        "Can't delete meal",
        body:
            'This is the only meal in $names. Add another meal or delete that plan first.',
        kind: ToastKind.warn,
      );
      return;
    }
    if (!out.deleted && out.affected.isNotEmpty) {
      final names = out.affected.map((p) => p.name).join(', ');
      final ok = await showCrudoSheet<bool>(
        context,
        builder: (sheetCtx) => SheetScaffold(
          title: 'Delete meal?',
          body: Text('$names will lose this meal.', style: CrudoText.body),
          cta: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryCta(
                label: 'Delete',
                onPressed: () => Navigator.of(sheetCtx).pop(true),
              ),
              const SizedBox(height: Spacing.sm),
              SecondaryAction(
                label: 'Cancel',
                onTap: () => Navigator.of(sheetCtx).pop(false),
              ),
            ],
          ),
        ),
      );
      if (ok != true) return;
      out = await _ctrl.delete(confirmed: true);
    } else if (!out.deleted) {
      final ok = await showCrudoSheet<bool>(
        context,
        builder: (sheetCtx) => SheetScaffold(
          title: 'Delete meal?',
          body: Text(
            'This meal will be removed from your library.',
            style: CrudoText.body,
          ),
          cta: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryCta(
                label: 'Delete',
                onPressed: () => Navigator.of(sheetCtx).pop(true),
              ),
              const SizedBox(height: Spacing.sm),
              SecondaryAction(
                label: 'Cancel',
                onTap: () => Navigator.of(sheetCtx).pop(false),
              ),
            ],
          ),
        ),
      );
      if (ok != true) return;
      out = await _ctrl.delete(confirmed: true);
    }
    if (out.deleted && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final draft = ref
        .watch(mealTemplateDraftControllerProvider(widget.templateId))
        .requireValue;

    // Usage badge for edit mode
    final usedInPlans = widget.templateId != null
        ? templateUsage(
            ref.watch(planTemplatesProvider).value ?? const [],
            widget.templateId!,
          ).using.length
        : 0;

    final macros = draft.macros(_ctrl.foodsById);

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
              // Header: back · title · SAVE.
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.name.isEmpty ? 'New meal' : draft.name,
                            style: CrudoText.headlineSm,
                          ),
                          if (usedInPlans > 0)
                            Text(
                              'Used in $usedInPlans plan${usedInPlans == 1 ? '' : 's'}',
                              style: CrudoText.labelMd.copyWith(
                                color: colors.onSurfaceMut,
                              ),
                            ),
                        ],
                      ),
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
                            key: const ValueKey('template-name'),
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
                                '${draft.foods.length} ITEMS',
                                style: CrudoText.label,
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.md),
                          if (draft.foods.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: Spacing.md,
                              ),
                              child: Center(
                                child: Text(
                                  'No ingredients yet',
                                  key: const ValueKey('template-empty'),
                                  style: CrudoText.body.copyWith(
                                    color: colors.onSurfaceMut,
                                  ),
                                ),
                              ),
                            )
                          else
                            for (final (i, row)
                                in draft.rows(_ctrl.foodsById).indexed)
                              _IngredientRow(
                                key: ValueKey('ingredient-$i'),
                                row: row,
                                colors: colors,
                                onTap: () => _editGrams(i, draft.foods[i]),
                                onRemove: () => _ctrl.removeFood(i),
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
                                  '${macros.kcal.round()} kcal',
                                  key: const ValueKey('template-preview-kcal'),
                                  style: CrudoText.displaySm.copyWith(
                                    color: colors.surfaceLowest,
                                  ),
                                ),
                              ),
                              Text(
                                'P ${macros.protein.round()}g'
                                '  C ${macros.carbs.round()}g'
                                '  F ${macros.fats.round()}g',
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
                    const SizedBox(height: Spacing.lg),
                    // DELETE (edit only)
                    if (widget.templateId != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                        ),
                        child: SecondaryAction(
                          label: 'Delete meal',
                          onTap: _delete,
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
    required this.row,
    required this.colors,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final IngredientRowVm row;
  final CrudoColors colors;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Edit ${row.name} quantity',
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
                      row.name,
                      style: CrudoText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${gramsText(row.grams.value)}g ·'
                      ' ${row.kcal} kcal',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('remove-${row.name}'),
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
