import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/food/food.dart';
import '../../../../domain/shared/enums.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../view_models/food_draft.dart';
import '../view_models/food_draft_controller.dart';
import '../view_models/food_library.dart';
import 'formatting.dart';
import 'kcal_card.dart';
import 'macro_field.dart';

/// S07 add/edit-food form. Outer widget resolves the async draft; the
/// inner stateful form owns TextEditingControllers (so provider updates
/// never clobber in-progress typing — controllers are created once from
/// the initial draft).
class FoodFormScreen extends ConsumerWidget {
  const FoodFormScreen({required this.foodId, super.key});

  /// null = create, id = edit (custom foods only).
  final String? foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(foodDraftControllerProvider(foodId));
    return draft.when(
      // initial is read once by _FoodForm's initState; the form watches the
      // provider itself for live derived values.
      data: (d) => _FoodForm(foodId: foodId, initial: d),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Food not found', style: CrudoText.body)),
      ),
    );
  }
}

class _FoodForm extends ConsumerStatefulWidget {
  const _FoodForm({required this.foodId, required this.initial});

  final String? foodId;
  final FoodDraft initial;

  @override
  ConsumerState<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends ConsumerState<_FoodForm> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _protein = TextEditingController(
    text: gramsText(widget.initial.protein),
  );
  late final _carbs = TextEditingController(
    text: gramsText(widget.initial.carbs),
  );
  late final _fats = TextEditingController(
    text: gramsText(widget.initial.fats),
  );
  late final _override = TextEditingController(
    text: widget.initial.explicitKcal == null
        ? ''
        : gramsText(widget.initial.explicitKcal!),
  );

  @override
  void dispose() {
    for (final c in [_name, _protein, _carbs, _fats, _override]) {
      c.dispose();
    }
    super.dispose();
  }

  FoodDraftController get _ctrl =>
      ref.read(foodDraftControllerProvider(widget.foodId).notifier);

  /// Spec copy, verbatim: percentage variant when macros yield kcal,
  /// zero-rule variant otherwise.
  String? _kcalError(FoodDraft d) {
    if (d.kcalValid) return null;
    if (d.calculated <= 0) return 'Macros are zero — calories must be 0.';
    final pct = (d.explicitKcal! - d.calculated).abs() / d.calculated * 100;
    return 'Override differs by ${pctText(pct)}% from macros. Max allowed is 10%.';
  }

  Future<void> _save() async {
    final result = await AsyncValue.guard(_ctrl.save);
    if (!mounted) return;
    if (result is AsyncError) {
      showCrudoToast(
        context,
        "Couldn't save — try again",
        body: 'Check your connection and try once more.',
        kind: ToastKind.error,
      );
      return;
    }
    // Pop with the saved Food so picker callers receive it.
    context.pop<Food?>(result is AsyncData ? result.value : null);
  }

  Future<void> _confirmDelete(String name) async {
    final confirmed =
        await showCrudoSheet<bool>(
          context,
          builder: (sheetCtx) => SheetScaffold(
            title: 'Delete food?',
            body: Text(
              '"$name" will be removed from your library. '
              'Logged days keep their copies.',
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
                TextButton(
                  key: const ValueKey('cancel-delete'),
                  onPressed: () => Navigator.of(sheetCtx).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    await _ctrl.delete();
    if (!mounted) return;
    showCrudoToast(
      context,
      'Food deleted',
      body: 'Logged days keep their copies.',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final draft = ref
        .watch(foodDraftControllerProvider(widget.foodId))
        .requireValue;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back · title · SAVE (disabled-dim unless canSave).
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
                    onPressed: context.pop,
                    icon: Icon(
                      Icons.arrow_back,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.foodId == null ? 'Custom food' : 'Edit food',
                      style: CrudoText.headlineSm,
                    ),
                  ),
                  Opacity(
                    opacity: draft.canSave ? 1 : Opacities.disabled,
                    child: TextButton(
                      key: const ValueKey('save-food'),
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
                  Spacing.xl,
                  Spacing.sm,
                  Spacing.xl,
                  Spacing.xl,
                ),
                children: [
                  // NAME — large soft input, hint 'e.g. My protein blend'.
                  TextField(
                    key: const ValueKey('food-name'),
                    controller: _name,
                    style: CrudoText.headline,
                    decoration: softInputDecoration(
                      colors,
                      hint: 'e.g. My protein blend',
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

                  // TYPE — Product|Dish toggle (S05 mandate; prototype
                  // lacks it). Two Pills side-by-side.
                  Row(
                    children: [
                      Expanded(
                        child: Pill(
                          label: 'Product',
                          selected: draft.kind == FoodKind.product,
                          onTap: () => _ctrl.setKind(FoodKind.product),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Pill(
                          label: 'Dish',
                          selected: draft.kind == FoodKind.dish,
                          onTap: () => _ctrl.setKind(FoodKind.dish),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),

                  // CATEGORY — hidden for dishes (product decision: dishes
                  // always save category = custom). Toggling back to Product
                  // restores the chip selection because draft.category is
                  // never cleared on kind toggle.
                  if (draft.kind == FoodKind.product) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text('CATEGORY', style: CrudoText.label),
                        ),
                        Text('OPTIONAL', style: CrudoText.label),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        for (final cat in FoodCategory.values)
                          if (cat != FoodCategory.custom)
                            Pill(
                              label: foodCategoryLabels[cat]!,
                              selected: draft.category == cat,
                              onTap: () => _ctrl.setCategory(
                                draft.category == cat ? null : cat,
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],

                  // MACROS PER 100G · ALL REQUIRED — three MacroFields.
                  const Text(
                    'MACROS PER 100G · ALL REQUIRED',
                    style: CrudoText.label,
                  ),
                  const SizedBox(height: Spacing.sm),
                  MacroField(
                    key: const ValueKey('macro-protein'),
                    label: 'PROTEIN',
                    accent: colors.proteinColor,
                    controller: _protein,
                    onChanged: _ctrl.setProtein,
                  ),
                  const SizedBox(height: Spacing.sm),
                  MacroField(
                    key: const ValueKey('macro-carbs'),
                    label: 'CARBS',
                    accent: colors.carbsColor,
                    controller: _carbs,
                    onChanged: _ctrl.setCarbs,
                  ),
                  const SizedBox(height: Spacing.sm),
                  MacroField(
                    key: const ValueKey('macro-fats'),
                    label: 'FATS',
                    accent: colors.fatsColor,
                    controller: _fats,
                    onChanged: _ctrl.setFats,
                  ),
                  const SizedBox(height: Spacing.lg),

                  // KCAL CARD:
                  KcalCard(
                    calculated: draft.calculated,
                    overrideController: _override,
                    onOverrideChanged: (s) => _ctrl.setExplicitKcal(
                      s.trim().isEmpty ? null : parseGrams(s),
                    ),
                    errorText: _kcalError(draft),
                  ),

                  // DELETE (edit mode only):
                  if (widget.foodId != null) ...[
                    const SizedBox(height: Spacing.xl),
                    TextButton(
                      key: const ValueKey('delete-food'),
                      onPressed: () => _confirmDelete(draft.name),
                      child: Text(
                        'Delete food',
                        style: CrudoText.body.copyWith(color: colors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
