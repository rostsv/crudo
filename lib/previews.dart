import 'package:flutter/material.dart';

import 'domain/food/food.dart';
import 'domain/shared/enums.dart';
import 'domain/shared/macros.dart';
import 'ui/core/themes/colors.dart';
import 'ui/core/themes/theme.dart';
import 'ui/core/themes/dimensions.dart';
import 'ui/core/themes/typography.dart';
import 'ui/core/widgets/primary_cta.dart';
import 'ui/core/widgets/pill.dart';
import 'ui/core/widgets/selection_card.dart';
import 'ui/core/widgets/meal_card.dart';
import 'ui/core/widgets/macro_ring.dart';
import 'ui/core/widgets/sheet.dart';
import 'ui/core/widgets/toast.dart';
import 'ui/features/foods/views/food_row.dart';
import 'ui/features/foods/views/kcal_card.dart';
import 'ui/features/foods/views/macro_field.dart';
import 'ui/features/today/views/day_strip.dart';
import 'ui/features/today/views/intake_card.dart';
import 'ui/features/today/views/nudge_card.dart';
import 'ui/features/today/views/streak_chip.dart';
import 'ui/features/today/views/formatting.dart';

/// Widget preview showcase — renders every core widget in all relevant states.
/// Run as a standalone app for visual review; not wired into production routing.
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crudo Widget Previews',
      debugShowCheckedModeBanner: false,
      theme: crudoTheme,
      home: const _PreviewHome(),
    );
  }
}

class _PreviewHome extends StatelessWidget {
  const _PreviewHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrudoColors.light.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            const Text('PrimaryCta', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            PrimaryCta(label: 'Enabled', onPressed: () {}),
            const SizedBox(height: Spacing.sm),
            const PrimaryCta(
              label: 'Disabled',
              onPressed: null,
              enabled: false,
            ),
            const SizedBox(height: Spacing.lg),

            const Text('Pill', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                Pill(label: 'Selected', selected: true, onTap: () {}),
                Pill(label: 'Unselected', selected: false, onTap: () {}),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            const Text('SelectionCard', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            SelectionCard(
              title: 'Selected',
              subtitle: 'Subtitle',
              selected: true,
              onTap: () {},
            ),
            const SizedBox(height: Spacing.sm),
            SelectionCard(
              title: 'Unselected',
              subtitle: 'Subtitle',
              selected: false,
              onTap: () {},
            ),
            const SizedBox(height: Spacing.lg),

            const Text('MealCard', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            for (final status in MealStatus.values)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: MealCard(
                  title: 'Meal — ${status.name}',
                  timeLabel: '08:00',
                  mealTypeLabel: 'Breakfast',
                  macros: const Macros(
                    protein: 32,
                    carbs: 45,
                    fats: 12,
                    kcal: 420,
                  ),
                  ingredientNames: const [
                    'Egg, whole',
                    'Greek Yogurt',
                    'Oats, dry',
                    'Blueberries',
                  ],
                  status: status,
                ),
              ),
            const SizedBox(height: Spacing.lg),

            const Text('MacroRing', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            const Center(
              child: MacroRing(
                value: 0.62,
                center: Icon(
                  Icons.local_fire_department_outlined,
                  size: IconSizes.lg,
                  color: CrudoPalette.primary,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            const Text('SheetScaffold', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            PrimaryCta(
              label: 'Open sheet',
              onPressed: () => showCrudoSheet<void>(
                context,
                builder: (_) => const SheetScaffold(
                  label: 'Preview',
                  title: 'Demo',
                  body: Center(child: Text('Sheet content')),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            const Text('Toast', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            PrimaryCta(
              label: 'Show success toast',
              onPressed: () => showCrudoToast(
                context,
                'Plan created',
                body: 'Mon–Fri, 4 meals a day.',
              ),
            ),
            const SizedBox(height: Spacing.sm),
            PrimaryCta(
              label: 'Show error toast',
              onPressed: () => showCrudoToast(
                context,
                'Schedule conflict',
                body: 'Two plans on the same day.',
                kind: ToastKind.error,
              ),
            ),
            const SizedBox(height: Spacing.lg),

            const Text('DayStrip', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            DayStrip(
              dates: weekOf(DateTime.utc(2026, 6, 4)),
              selected: DateTime.utc(2026, 6, 4),
              today: DateTime.utc(2026, 6, 4),
              onSelect: (_) {},
            ),
            const SizedBox(height: Spacing.lg),

            const Text('IntakeCard', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            const IntakeCard(
              consumed: Macros(protein: 82, carbs: 140, fats: 38, kcal: 1240),
              planned: Macros(protein: 140, carbs: 220, fats: 70, kcal: 2080),
            ),
            const SizedBox(height: Spacing.lg),

            const Text('StreakChip', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            const StreakChip(count: 7, onTap: _noop),
            const SizedBox(height: Spacing.lg),

            const Text('NudgeCard', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            const NudgeCard(
              title: 'Finish strong',
              body: 'Two meals left — you\'re on pace for today\'s goal.',
            ),
            const SizedBox(height: Spacing.lg),

            const Text('MealCard — snoozed', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            MealCard(
              title: 'Protein Bowl',
              timeLabel: '14:00',
              snoozedTimeLabel: '14:15',
              mealTypeLabel: 'Lunch',
              macros: const Macros(protein: 38, carbs: 52, fats: 16, kcal: 504),
              ingredientNames: const [
                'Chicken breast',
                'Brown rice',
                'Avocado',
              ],
              status: MealStatus.upcoming,
              onTap: _noop,
            ),
            const SizedBox(height: Spacing.lg),

            // MealSheet / SnoozeSheet are provider-driven (they watch
            // dayControllerProvider) — previewed in-app via the dev flavor,
            // not from this static gallery.
            const SizedBox(height: Spacing.lg),

            const Text('FoodRow', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            const FoodRow(
              food: Food(
                id: 'preview-chicken',
                name: 'Chicken breast',
                category: FoodCategory.meat,
                protein: 31,
                carbs: 0,
                fats: 3.6,
                kcalPer100g: 156.4,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            FoodRow(
              food: const Food(
                id: 'preview-shake',
                name: 'My shake',
                category: FoodCategory.custom,
                protein: 30,
                carbs: 10,
                fats: 5,
                kcalPer100g: 205,
                isCustom: true,
              ),
              onTap: _noop,
            ),
            const SizedBox(height: Spacing.lg),

            const Text('MacroField', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            MacroField(
              label: 'PROTEIN',
              accent: CrudoColors.light.primary,
              controller: TextEditingController(text: '31'),
              onChanged: (_) {},
            ),
            const SizedBox(height: Spacing.lg),

            const Text('KcalCard', style: CrudoText.headline),
            const SizedBox(height: Spacing.md),
            KcalCard(
              calculated: 290,
              overrideController: TextEditingController(),
              onOverrideChanged: (_) {},
            ),
            const SizedBox(height: Spacing.sm),
            KcalCard(
              calculated: 290,
              overrideController: TextEditingController(text: '350'),
              onOverrideChanged: (_) {},
              errorText:
                  'Override differs by 21% from macros. Max allowed is 10%.',
            ),
            const SizedBox(height: Spacing.lg),

            // FoodLibraryScreen / FoodFormScreen are provider-driven — verified
            // via the /foods route (dev) + widget tests, not from this static
            // gallery.
          ],
        ),
      ),
    );
  }
}

void _noop() {}
