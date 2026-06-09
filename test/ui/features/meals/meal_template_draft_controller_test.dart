// test/ui/features/meals/meal_template_draft_controller_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/repositories/in_memory_meal_template_repository.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/food/food_ref.dart';
import 'package:crudo/domain/meal/meal_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/features/meals/view_models/meal_template_draft_controller.dart';
import 'package:crudo/ui/features/meals/view_models/meal_template_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Food food1;
  late Food food2;
  late MealTemplate existingTemplate;
  late PlanTemplate planA;
  late PlanTemplate planB;

  setUp(() {
    food1 = Food(
      id: 'f1',
      name: 'Chicken',
      category: FoodCategory.meat,
      protein: 30,
      carbs: 0,
      fats: 5,
      kcalPer100g: 165,
    );
    food2 = Food(
      id: 'f2',
      name: 'Rice',
      category: FoodCategory.grain,
      protein: 2.5,
      carbs: 30,
      fats: 0.5,
      kcalPer100g: 135,
    );
    existingTemplate = MealTemplate(
      id: 'mt1',
      name: 'Breakfast',
      tags: [MealTag.breakfast],
      foods: [FoodRef(foodId: 'f1', grams: const Grams(100))],
    );
    // Plan A has mt1 + another slot, plan B has mt1 as its only slot.
    planA = PlanTemplate(
      id: 'A',
      name: 'Plan With More',
      days: [0, 2, 4],
      active: true,
      slots: [
        PlanSlot(id: 's1', mealTemplateId: 'mt1', time: const MealTime(480)),
        PlanSlot(id: 's2', mealTemplateId: 'mt2', time: const MealTime(720)),
      ],
    );
    planB = PlanTemplate(
      id: 'B',
      name: 'Only Meal',
      days: [5, 6],
      active: true,
      slots: [
        PlanSlot(id: 's3', mealTemplateId: 'mt1', time: const MealTime(480)),
      ],
    );
  });

  ProviderContainer createContainer({
    List<Food>? foods,
    List<MealTemplate>? templates,
    List<PlanTemplate>? plans,
  }) {
    return ProviderContainer(
      overrides: [
        foodRepositoryProvider.overrideWithValue(
          InMemoryFoodRepository(seed: foods ?? [food1, food2]),
        ),
        mealTemplateRepositoryProvider.overrideWithValue(
          InMemoryMealTemplateRepository(seed: templates ?? [existingTemplate]),
        ),
        planTemplateRepositoryProvider.overrideWithValue(
          InMemoryPlanTemplateRepository(seed: plans ?? [planA, planB]),
        ),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
  }

  group('MealTemplateDraftController — create', () {
    test('build(null) → empty draft, canSave false', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      final draft = await c.read(
        mealTemplateDraftControllerProvider(null).future,
      );
      check(draft.canSave).isFalse();
      check(draft.name).equals('');
      check(draft.foods).isEmpty();
    });

    test(
      'setName + addFood → canSave true; save returns minted template',
      () async {
        final c = createContainer();
        addTearDown(c.dispose);

        await c.read(mealTemplateDraftControllerProvider(null).future);
        final ctrl = c.read(mealTemplateDraftControllerProvider(null).notifier);

        ctrl.setName('My Meal');
        ctrl.addFood(FoodRef(foodId: 'f1', grams: const Grams(100)));
        final d = c
            .read(mealTemplateDraftControllerProvider(null))
            .requireValue;
        check(d.canSave).isTrue();

        final saved = await ctrl.save();
        check(saved.name).equals('My Meal');
        check(saved.id).isNotEmpty();
        check(saved.id).equals('sm-0'); // first FakeIdGenerator id

        // Repo has it
        final fromRepo = await c
            .read(mealTemplateRepositoryProvider)
            .getById(saved.id);
        check(fromRepo).isNotNull();
        check(fromRepo!.name).equals('My Meal');
      },
    );
  });

  group('MealTemplateDraftController — edit', () {
    test(
      'build(existingId) → draft matches; setName → isDirty; save keeps id',
      () async {
        final c = createContainer();
        addTearDown(c.dispose);

        final draft = await c.read(
          mealTemplateDraftControllerProvider('mt1').future,
        );
        check(draft.name).equals('Breakfast');
        check(draft.tags).deepEquals([MealTag.breakfast]);
        check(draft.foods.length).equals(1);

        final ctrl = c.read(
          mealTemplateDraftControllerProvider('mt1').notifier,
        );
        check(ctrl.isDirty).isFalse();

        ctrl.setName('Updated Breakfast');
        check(ctrl.isDirty).isTrue();

        final saved = await ctrl.save();
        check(saved.id).equals('mt1'); // keeps original id
        check(saved.name).equals('Updated Breakfast');

        final fromRepo = await c
            .read(mealTemplateRepositoryProvider)
            .getById('mt1');
        check(fromRepo!.name).equals('Updated Breakfast');
      },
    );
  });

  group('MealTemplateDraftController — mutations', () {
    test('removeFood / setGrams mutate foods', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      await c.read(mealTemplateDraftControllerProvider('mt1').future);
      final ctrl = c.read(mealTemplateDraftControllerProvider('mt1').notifier);

      // Add a second food
      ctrl.addFood(FoodRef(foodId: 'f2', grams: const Grams(200)));
      var d = c.read(mealTemplateDraftControllerProvider('mt1')).requireValue;
      check(d.foods.length).equals(2);

      // Remove first food
      ctrl.removeFood(0);
      d = c.read(mealTemplateDraftControllerProvider('mt1')).requireValue;
      check(d.foods.length).equals(1);
      check(d.foods.first.foodId).equals('f2');
      check(d.foods.first.grams.value).equals(200);

      // setGrams
      ctrl.setGrams(0, const Grams(50));
      d = c.read(mealTemplateDraftControllerProvider('mt1')).requireValue;
      check(d.foods.first.grams.value).equals(50);
    });

    test('macros and rows recompute after mutations', () async {
      final c = createContainer();
      addTearDown(c.dispose);

      await c.read(mealTemplateDraftControllerProvider('mt1').future);
      final ctrl = c.read(mealTemplateDraftControllerProvider('mt1').notifier);

      final d = c.read(mealTemplateDraftControllerProvider('mt1')).requireValue;
      final foodsById = ctrl.foodsById;

      // Chicken 100g → 165 kcal
      final macros = d.macros(foodsById);
      check(macros.kcal).equals(165);
      check(macros.protein).equals(30);
      check(macros.fats).equals(5);

      final rows = d.rows(foodsById);
      check(rows.length).equals(1);
      check(rows.first.name).equals('Chicken');
      check(rows.first.kcal).equals(165);

      // Double the grams
      ctrl.setGrams(0, const Grams(200));
      final d2 = c
          .read(mealTemplateDraftControllerProvider('mt1'))
          .requireValue;
      final rows2 = d2.rows(foodsById);
      check(rows2.first.kcal).equals(330); // 165 * 2
    });
  });

  group('MealTemplateDraftController — delete', () {
    test(
      'delete unused template → confirm needed; confirmed:true → deletes',
      () async {
        final c = createContainer(plans: []); // no plans use mt1
        addTearDown(c.dispose);

        await c.read(mealTemplateDraftControllerProvider('mt1').future);
        final ctrl = c.read(
          mealTemplateDraftControllerProvider('mt1').notifier,
        );

        // Not confirmed
        final out1 = await ctrl.delete();
        check(out1.deleted).isFalse();
        check(out1.blockedByEmpty).isFalse();
        check(out1.affected).isEmpty();

        // Template still present
        var fromRepo = await c
            .read(mealTemplateRepositoryProvider)
            .getById('mt1');
        check(fromRepo).isNotNull();

        // Confirmed
        final out2 = await ctrl.delete(confirmed: true);
        check(out2.deleted).isTrue();
        check(out2.blockedByEmpty).isFalse();
        check(out2.affected).isEmpty();

        fromRepo = await c.read(mealTemplateRepositoryProvider).getById('mt1');
        check(fromRepo).isNull();
      },
    );

    test('delete referenced template (plan has other slot) → confirm needed;'
        ' confirmed:true → cascade strips', () async {
      // planA uses mt1 but also has mt2 → would-not-empty
      final c = createContainer(plans: [planA]);
      addTearDown(c.dispose);

      await c.read(mealTemplateDraftControllerProvider('mt1').future);
      final ctrl = c.read(mealTemplateDraftControllerProvider('mt1').notifier);

      // Not confirmed
      final out1 = await ctrl.delete();
      check(out1.deleted).isFalse();
      check(out1.blockedByEmpty).isFalse();
      check(out1.affected).length.equals(1);
      check(out1.affected.first.id).equals('A');

      // Template still present
      var fromRepo = await c
          .read(mealTemplateRepositoryProvider)
          .getById('mt1');
      check(fromRepo).isNotNull();

      // Confirmed
      final out2 = await ctrl.delete(confirmed: true);
      check(out2.deleted).isTrue();
      check(out2.blockedByEmpty).isFalse();

      // Template gone
      fromRepo = await c.read(mealTemplateRepositoryProvider).getById('mt1');
      check(fromRepo).isNull();

      // Plan A stripd of mt1 slot
      final planAFromRepo = await c
          .read(planTemplateRepositoryProvider)
          .getById('A');
      check(planAFromRepo!.slots).length.equals(1);
      check(planAFromRepo.slots.first.mealTemplateId).equals('mt2');
    });

    test(
      'delete sole-meal template → blockedByEmpty:true, nothing written',
      () async {
        // planB only has mt1 → would be emptied
        final c = createContainer(plans: [planB]);
        addTearDown(c.dispose);

        await c.read(mealTemplateDraftControllerProvider('mt1').future);
        final ctrl = c.read(
          mealTemplateDraftControllerProvider('mt1').notifier,
        );

        final out = await ctrl.delete();
        check(out.deleted).isFalse();
        check(out.blockedByEmpty).isTrue();
        check(out.affected).length.equals(1);
        check(out.affected.first.id).equals('B');

        // Template still present (nothing written)
        var fromRepo = await c
            .read(mealTemplateRepositoryProvider)
            .getById('mt1');
        check(fromRepo).isNotNull();

        // Even with confirmed:true, should still be blocked
        final out2 = await ctrl.delete(confirmed: true);
        check(out2.deleted).isFalse();
        check(out2.blockedByEmpty).isTrue();
        fromRepo = await c.read(mealTemplateRepositoryProvider).getById('mt1');
        check(fromRepo).isNotNull();
      },
    );
  });

  group('mealTemplateRows', () {
    /// Pump a [container] into a widget tree so stream providers emit.
    Future<void> pumpContainer(
      WidgetTester tester,
      ProviderContainer container,
    ) {
      return tester.pumpWidget(
        MaterialApp(
          home: UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, child) {
                // Keep mealTemplateRows alive to let stream emissions propagate.
                ref.watch(mealTemplateRowsProvider);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    }

    testWidgets('emits rows with correct kcal, tags, usedInPlans', (
      tester,
    ) async {
      final c = createContainer(plans: [planA]);
      addTearDown(c.dispose);

      await pumpContainer(tester, c);
      await tester.pumpAndSettle();

      final rows = c.read(mealTemplateRowsProvider);
      check(rows).length.equals(1);

      final row = rows.first;
      check(row.id).equals('mt1');
      check(row.name).equals('Breakfast');
      check(row.tags).deepEquals([MealTag.breakfast]);
      // Chicken 100g → 165 kcal
      check(row.kcal).equals(165);
      // planA uses mt1
      check(row.usedInPlans).equals(1);
    });

    testWidgets('unreferenced template shows usedInPlans == 0', (tester) async {
      final mealTemplateRepo = InMemoryMealTemplateRepository(
        seed: [
          MealTemplate(
            id: 'mt99',
            name: 'Unused',
            foods: [FoodRef(foodId: 'f1', grams: const Grams(100))],
          ),
        ],
      );
      final c = ProviderContainer(
        overrides: [
          foodRepositoryProvider.overrideWithValue(
            InMemoryFoodRepository(seed: [food1, food2]),
          ),
          mealTemplateRepositoryProvider.overrideWithValue(mealTemplateRepo),
          planTemplateRepositoryProvider.overrideWithValue(
            InMemoryPlanTemplateRepository(seed: []),
          ),
          idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
        ],
      );
      addTearDown(c.dispose);

      await pumpContainer(tester, c);
      await tester.pumpAndSettle();

      final rows = c.read(mealTemplateRowsProvider);
      check(rows).length.equals(1);
      check(rows.first.usedInPlans).equals(0);
    });
  });
}
