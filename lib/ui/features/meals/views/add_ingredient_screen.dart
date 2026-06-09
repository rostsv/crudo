import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/food/food.dart';
import '../../../../domain/meal/food_snapshot.dart';
import '../../../../domain/shared/grams.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../foods/views/food_library_list.dart';
import 'grams_entry.dart';

/// Two-stage add-ingredient picker (S08, meal.jsx AddIngredientScreen):
/// stage 1 = the S07 library list in picker mode (+ custom-food CTA),
/// stage 2 = grams entry with presets + live preview. Pops a FoodSnapshot
/// created AT ADD TIME via FoodSnapshot.from (S05 §1.4 point 2) — the
/// editor's draft receives it; this screen never touches the draft.
class AddIngredientScreen extends ConsumerStatefulWidget {
  const AddIngredientScreen({super.key});

  @override
  ConsumerState<AddIngredientScreen> createState() =>
      _AddIngredientScreenState();
}

class _AddIngredientScreenState extends ConsumerState<AddIngredientScreen> {
  Food? _picked;
  double? _grams = 100;

  Future<void> _createCustom() async {
    // The retrofitted FoodFormScreen pops the created Food (Task 5) —
    // land in the grams stage prefilled (decision: never auto-add at 100g).
    final created = await context.push<Food>('/foods/new');
    if (created != null && mounted) {
      setState(() {
        _picked = created;
        _grams = 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final picked = _picked;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    key: const ValueKey('picker-back'),
                    onPressed: picked == null
                        ? context.pop
                        : () => setState(() => _picked = null),
                    icon: Icon(
                      Icons.arrow_back,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                  const Expanded(
                    child: Text('Add ingredient', style: CrudoText.headlineSm),
                  ),
                ],
              ),
            ),
            if (picked == null)
              Expanded(
                child: FoodLibraryList(
                  pickerHint: true,
                  header: _CreateCustomCta(
                    colors: colors,
                    onTap: _createCustom,
                  ),
                  onPick: (f) => setState(() {
                    _picked = f;
                    _grams = 100;
                  }),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    Spacing.sm,
                    Spacing.xl,
                    Spacing.xl,
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceLowest,
                        borderRadius: Radii.all(Radii.lg),
                        boxShadow: Shadows.cloud,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SELECTED', style: CrudoText.label),
                          const SizedBox(height: Spacing.xs),
                          Text(picked.name, style: CrudoText.headline),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Per 100g · ${picked.kcalPer100g.round()} kcal',
                            style: CrudoText.body.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    GramsEntry(
                      // GramsEntry is keyed by food so re-picks reset it.
                      key: ValueKey('grams-entry-${picked.id}'),
                      baseline: FoodSnapshot.from(picked, const Grams(100)),
                      initialGrams: _grams ?? 100,
                      onChanged: (g) => setState(() => _grams = g),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: picked == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: PrimaryCta(
                  key: const ValueKey('add-to-meal'),
                  label: 'Add to Meal',
                  enabled: _grams != null && _grams! > 0,
                  onPressed: () =>
                      context.pop((food: picked, grams: Grams(_grams!))),
                ),
              ),
            ),
    );
  }
}

/// Persistent "Create custom food" CTA above the list. Tonal container —
/// the prototype's dashed border violates the no-line rule.
class _CreateCustomCta extends StatelessWidget {
  const _CreateCustomCta({required this.colors, required this.onTap});

  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create custom food',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          key: const ValueKey('create-custom-cta'),
          margin: const EdgeInsets.only(top: Spacing.sm),
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Row(
            children: [
              Container(
                width: 40, // icon circle, 4px grid (matches sheet grabber)
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: IconSizes.md,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create custom food',
                      style: CrudoText.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      'Add your own with macros per 100g',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: IconSizes.sm,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
